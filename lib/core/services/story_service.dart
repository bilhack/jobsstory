import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/story.dart';
import 'story_repository.dart';

/// Thrown when a story exceeds the 60-second platform limit.
class StoryTooLongException implements Exception {
  const StoryTooLongException();
}

/// Our hard product limit (TikTok-style):
const int kMaxStoryDurationMs = 60 * 1000;

/// Boundary for the UI tests — everything here is fakeable.
abstract class StoryService {
  Future<Story> publishStory({
    required File video,
    File? thumbnail,
    required String caption,
    required String ownerUid,
    void Function(double progress)? onProgress,
  });

  Future<List<Story>> listOwnStories(String uid);

  Future<void> deleteStory(Story story);
}

/// Production implementation: Cloud Storage upload + Firestore metadata.
/// Firebase instances are resolved lazily so the service can be constructed
/// (and injected) before `Firebase.initializeApp` in tests.
class FirebaseStoryService implements StoryService {
  FirebaseStoryService({StoryRepository? repository}) : _repository = repository;

  StoryRepository? _repository;
  FirebaseStorage? _storage;

  StoryRepository get _repo => _repository ??= FirestoreStoryRepository();
  FirebaseStorage get _fbStorage => _storage ??= FirebaseStorage.instance;

  @override
  Future<Story> publishStory({
    required File video,
    File? thumbnail,
    required String caption,
    required String ownerUid,
    void Function(double progress)? onProgress,
  }) async {
    final durationMs = await _probeDurationMs(video);
    if (durationMs > kMaxStoryDurationMs) {
      throw const StoryTooLongException();
    }

    final id = '${ownerUid}_${DateTime.now().millisecondsSinceEpoch}';
    final videoUrl = await _upload(
      video,
      'stories/$ownerUid/$id/video${_extensionFor(video.path)}',
      onProgress,
    );

    // A missing thumbnail falls back to an auto-generated frame.
    var thumbnailUrl = '';
    final thumb = thumbnail ?? await _makeThumbnail(video);
    if (thumb != null) {
      thumbnailUrl = await _upload(thumb, 'stories/$ownerUid/$id/thumb.jpg', null);
    }

    final story = Story(
      id: id,
      ownerUid: ownerUid,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption.trim(),
      durationMs: durationMs,
      status: StoryStatus.review,
    );
    await _repo.create(story: story);
    return story;
  }

  @override
  Future<List<Story>> listOwnStories(String uid) => _repo.listOwn(uid);

  @override
  Future<void> deleteStory(Story story) async {
    await _deleteIfExists('stories/${story.ownerUid}/${story.id}/video.mp4');
    await _deleteIfExists('stories/${story.ownerUid}/${story.id}/thumb.jpg');
    await _repo.delete(story.id);
  }

  Future<String> _upload(File file, String path, void Function(double)? onProgress) async {
    final ref = _fbStorage.ref(path);
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: _contentTypeFor(path)),
    );
    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        final total = snap.totalBytes;
        final progress = total == 0 ? 0.0 : snap.bytesTransferred / total;
        onProgress(progress.clamp(0.0, 1.0));
      });
    }
    await task;
    return ref.getDownloadURL();
  }

  Future<void> _deleteIfExists(String path) async {
    try {
      await _fbStorage.ref(path).delete();
    } catch (_) {
      // Missing object is fine.
    }
  }

  Future<int> _probeDurationMs(File video) async {
    try {
      final controller = VideoPlayerController.file(video);
      await controller.initialize();
      final duration = controller.value.duration.inMilliseconds;
      await controller.dispose();
      return duration;
    } catch (_) {
      return 0; // duration unknown — accept rather than reject.
    }
  }

  Future<File?> _makeThumbnail(File video) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = await VideoThumbnail.thumbnailFile(
        video: video.path,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 75,
      );
      return path == null ? null : File(path);
    } catch (_) {
      return null;
    }
  }

  String _extensionFor(String path) {
    final idx = path.lastIndexOf('.');
    return idx < 0 ? '.mp4' : path.substring(idx);
  }

  String _contentTypeFor(String path) {
    final ext = _extensionFor(path).toLowerCase();
    return switch (ext) {
      '.mov' => 'video/quicktime',
      '.m4v' => 'video/x-m4v',
      _ => 'video/mp4',
    };
  }
}