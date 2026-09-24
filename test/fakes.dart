import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jobsstory/core/media/feed_video_tile.dart';
import 'package:jobsstory/core/media/media_picker.dart';
import 'package:jobsstory/core/models/app_user.dart';
import 'package:jobsstory/core/models/job.dart';
import 'package:jobsstory/core/models/job_application.dart';
import 'package:jobsstory/core/models/story.dart';
import 'package:jobsstory/core/services/application_repository.dart';
import 'package:jobsstory/core/services/auth_service.dart';
import 'package:jobsstory/core/services/job_repository.dart';
import 'package:jobsstory/core/services/notification_service.dart';
import 'package:jobsstory/core/services/story_interaction_service.dart';
import 'package:jobsstory/core/services/story_service.dart';
import 'package:jobsstory/core/services/user_repository.dart';

enum FakeStatus {
  unsigned,
  signedInNoProfile,
  signedInSeeker,
  signedInRecruiter,
}

/// In-memory AuthService for widget tests — no Firebase involved.
class FakeAuthService implements AuthService {
  FakeAuthService([FakeStatus status = FakeStatus.unsigned]) {
    _apply(status);
  }

  final _controller = StreamController<AuthSnapshot>.broadcast();
  AuthSnapshot _state = AuthSnapshot.unsigned;

  /// Seeds new listeners with the current state, then forwards live updates.
  @override
  Stream<AuthSnapshot> get snapshots async* {
    yield _state;
    yield* _controller.stream;
  }

  void _apply(FakeStatus status) {
    _state = switch (status) {
      FakeStatus.unsigned => const AuthSnapshot(isSignedIn: false),
      FakeStatus.signedInNoProfile => const AuthSnapshot(isSignedIn: true),
      FakeStatus.signedInSeeker => AuthSnapshot(
          isSignedIn: true,
          profile: AppUser(
            uid: 'u1',
            email: 'seeker@test.dev',
            displayName: 'سارة',
            role: UserRole.seeker,
          ),
        ),
      FakeStatus.signedInRecruiter => AuthSnapshot(
          isSignedIn: true,
          profile: AppUser(
            uid: 'u1',
            email: 'hr@test.dev',
            displayName: 'HR',
            role: UserRole.recruiter,
          ),
        ),
    };
    _emit();
  }

  void _emit() {
    if (_controller.hasListener) _controller.add(_state);
  }

  Future<void> setStatus(FakeStatus status) async {
    _apply(status);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    _apply(FakeStatus.signedInNoProfile);
  }

  @override
  Future<void> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _state = AuthSnapshot(
      isSignedIn: true,
      profile: AppUser(uid: 'u1', email: email, displayName: displayName, role: role),
    );
    _emit();
  }

  @override
  Future<void> signInWithGoogle({UserRole? role}) async {
    _apply(FakeStatus.signedInNoProfile);
  }

  @override
  Future<void> completeOnboarding(UserRole role) async {
    final profile = _state.profile;
    if (profile != null) {
      _state = AuthSnapshot(isSignedIn: true, profile: profile.copyWith(role: role));
    }
    _emit();
  }

  @override
  Future<void> signOut() async {
    _apply(FakeStatus.unsigned);
  }
}

/// In-memory StoryService for widget tests — no Firebase involved.
class FakeStoryService implements StoryService {
  final List<Story> _stories = [];
  int publishCount = 0;
  StoryStatus publishStatus = StoryStatus.review;
  Object? errorToThrow;

  @override
  Future<Story> publishStory({
    required File video,
    File? thumbnail,
    required String caption,
    required String ownerUid,
    void Function(double progress)? onProgress,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    publishCount++;
    onProgress?.call(0.5);
    onProgress?.call(1.0);
    final story = Story(
      id: 's$publishCount',
      ownerUid: ownerUid,
      videoUrl: 'https://cdn/stories/$ownerUid/$publishCount.mp4',
      thumbnailUrl: 'https://cdn/stories/$ownerUid/$publishCount/thumb.jpg',
      caption: caption.trim(),
      durationMs: 32000,
      status: publishStatus,
    );
    _stories.insert(0, story);
    return story;
  }

  @override
  Future<List<Story>> listOwnStories(String uid) async =>
      _stories.where((s) => s.ownerUid == uid).toList();

  @override
  Future<List<Story>> fetchApprovedStories() async {
    if (errorToThrow != null) throw errorToThrow!;
    return _stories.where((s) => s.status == StoryStatus.approved).toList();
  }

  @override
  Future<List<Story>> fetchApprovedStoriesOf(String uid) async {
    if (errorToThrow != null) throw errorToThrow!;
    return _stories
        .where((s) => s.ownerUid == uid && s.status == StoryStatus.approved)
        .toList();
  }

  @override
  Future<void> deleteStory(Story story) async {
    _stories.removeWhere((s) => s.id == story.id);
  }

  void seed(List<Story> stories) => _stories.addAll(stories);
}

/// In-memory UserRepository for profile/feed tests.
class FakeUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {};

  void seed(Iterable<AppUser> users) {
    for (final user in users) {
      _users[user.uid] = user;
    }
  }

  @override
  Future<AppUser?> get(String uid) async => _users[uid];

  @override
  Future<void> create({required AppUser user}) async {
    _users[user.uid] = user;
  }

  @override
  Future<void> setRole(String uid, UserRole role) async {
    final existing = _users[uid];
    if (existing != null) {
      _users[uid] = existing.copyWith(role: role);
    }
  }
}

/// In-memory interactions (likes/saves/reports) — no Firebase involved.
class FakeStoryInteractionService implements StoryInteractionService {
  final Set<String> liked = {};
  final Set<String> saved = {};
  final List<Map<String, String>> reports = [];

  int get reportCount => reports.length;
  int likeCalls = 0;
  int saveCalls = 0;

  @override
  Future<void> likeStory({required String storyId, required String userId}) async {
    likeCalls++;
    liked.add('${storyId}_$userId');
  }

  @override
  Future<void> unlikeStory({required String storyId, required String userId}) async {
    likeCalls++;
    liked.remove('${storyId}_$userId');
  }

  @override
  Future<List<String>> likedStoryIds(String userId) async =>
      liked.where((id) => id.endsWith('_$userId')).map((id) => id.substring(0, id.length - userId.length - 1)).toList();

  @override
  Future<void> saveSeeker({required String seekerId, required String savedById}) async {
    saveCalls++;
    saved.add('${savedById}_$seekerId');
  }

  @override
  Future<void> unsaveSeeker({required String seekerId, required String savedById}) async {
    saveCalls++;
    saved.remove('${savedById}_$seekerId');
  }

  @override
  Future<List<String>> savedSeekerIds(String savedById) async =>
      saved.where((id) => id.startsWith('${savedById}_')).map((id) => id.substring(savedById.length + 1)).toList();

  @override
  Future<void> reportStory({
    required String storyId,
    required String reportedBy,
    required String reason,
    String? details,
  }) async {
    reports.add({'targetId': storyId, 'reportedBy': reportedBy, 'reason': reason});
  }
}

/// In-memory JobRepository for Phase 4 widget/unit tests.
class FakeJobRepository implements JobRepository {
  final Map<String, Job> _jobs = {};

  void seed(List<Job> jobs) {
    for (final job in jobs) {
      _jobs[job.id] = job;
    }
  }

  Iterable<Job> get all => _jobs.values;

  @override
  Future<Job?> get(String id) async => _jobs[id];

  @override
  Future<List<Job>> listOpen() async =>
      _jobs.values.where((j) => j.status == JobStatus.open).toList();

  @override
  Future<List<Job>> listMine(String recruiterUid) async =>
      _jobs.values.where((j) => j.createdBy == recruiterUid).toList();

  @override
  Future<Job> create({required Job job}) async {
    _jobs[job.id] = job;
    return job;
  }

  @override
  Future<void> setStatus(String id, JobStatus status) async {
    final existing = _jobs[id];
    if (existing != null) _jobs[id] = existing.copyWith(status: status);
  }
}

/// In-memory ApplicationRepository for Phase 4 widget/unit tests.
class FakeApplicationRepository implements ApplicationRepository {
  final Map<String, JobApplication> _apps = {};

  void seed(List<JobApplication> apps) {
    for (final app in apps) {
      _apps[app.id] = app;
    }
  }

  Iterable<JobApplication> get all => _apps.values;

  @override
  Future<JobApplication?> applicationFor({
    required String jobId,
    required String seekerUid,
  }) async =>
      _apps['${jobId}_$seekerUid'];

  @override
  Future<List<JobApplication>> applicationsForJob(String jobId) async =>
      _apps.values.where((a) => a.jobId == jobId).toList();

  @override
  Future<List<JobApplication>> applicationsBySeeker(String seekerUid) async =>
      _apps.values.where((a) => a.seekerUid == seekerUid).toList();

  @override
  Future<void> submit({required JobApplication application}) async {
    _apps[application.id] = application;
  }

  @override
  Future<void> setStatus(String id, ApplicationStatus status) async {
    final existing = _apps[id];
    if (existing != null) _apps[id] = existing.copyWith(status: status);
  }

  @override
  Future<void> setNote(String id, String note) async {
    final existing = _apps[id];
    if (existing != null) _apps[id] = existing.copyWith(recruiterNote: note);
  }
}

/// Records FCM register/unregister calls for the shell wiring.
class FakeNotificationService implements NotificationService {
  final List<String> registered = [];
  final List<String> unregistered = [];

  @override
  Future<void> register(String uid) async => registered.add(uid);

  @override
  Future<void> unregister(String uid) async => unregistered.add(uid);
}

/// Fake video tile: no platform channels, renders a static placeholder.
class FakeFeedVideoTile implements FeedVideoTile {
  @override
  Widget build({
    required String videoUrl,
    String? thumbnailUrl,
    required bool autoplay,
    required bool initiallyMuted,
  }) {
    return Container(
      color: const Color(0xFF232338),
      alignment: Alignment.center,
      child: const Icon(Icons.videocam_outlined, size: 72, color: Color(0xFFB8B8CC)),
    );
  }
}

/// Returns pre-made files so gallery-pick flows work without platform channels.
class FakeMediaPicker implements MediaPicker {
  final File _video = File('${Directory.systemTemp.path}/fake_video.mp4');

  @override
  Future<File?> pickVideo() async => _video;

  @override
  Future<File?> pickImage() async => null;
}