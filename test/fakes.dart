import 'dart:async';
import 'dart:io';

import 'package:jobsstory/core/media/media_picker.dart';
import 'package:jobsstory/core/models/app_user.dart';
import 'package:jobsstory/core/models/story.dart';
import 'package:jobsstory/core/services/auth_service.dart';
import 'package:jobsstory/core/services/story_service.dart';

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
  Future<void> deleteStory(Story story) async {
    _stories.removeWhere((s) => s.id == story.id);
  }

  void seed(List<Story> stories) => _stories.addAll(stories);
}

/// Returns pre-made files so gallery-pick flows work without platform channels.
class FakeMediaPicker implements MediaPicker {
  final File _video = File('${Directory.systemTemp.path}/fake_video.mp4');

  @override
  Future<File?> pickVideo() async => _video;

  @override
  Future<File?> pickImage() async => null;
}