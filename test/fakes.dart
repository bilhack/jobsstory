import 'dart:async';

import 'package:jobsstory/core/models/app_user.dart';
import 'package:jobsstory/core/services/auth_service.dart';

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