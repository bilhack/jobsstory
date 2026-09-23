import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'user_repository.dart';

/// Immutable snapshot of the session consumed by the UI.
class AuthSnapshot {
  const AuthSnapshot({required this.isSignedIn, this.profile});

  final bool isSignedIn;

  /// null = signed-in user without a Firestore profile/role yet.
  final AppUser? profile;

  bool get hasProfile => profile != null;

  static const unsigned = AuthSnapshot(isSignedIn: false);
}

/// Abstract boundary used by AuthProvider so the UI is fully testable.
abstract class AuthService {
  Stream<AuthSnapshot> get snapshots;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
    required UserRole role,
  });
  Future<void> signInWithGoogle({UserRole? role});
  Future<void> completeOnboarding(UserRole role);
  Future<void> signOut();
}

/// Production implementation backed by Firebase Auth + Firestore.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    UserRepository? repository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _repository = repository ?? FirestoreUserRepository();

  final FirebaseAuth _auth;
  final UserRepository _repository;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    _googleInitialized = true;
    // gsi v7 singleton; reads config from the native app automatically.
    await GoogleSignIn.instance.initialize();
  }

  @override
  Stream<AuthSnapshot> get snapshots {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return AuthSnapshot.unsigned;
      final profile = await _repository.get(firebaseUser.uid);
      return AuthSnapshot(isSignedIn: true, profile: profile);
    });
  }

  Future<void> _ensureProfile(User firebaseUser, {UserRole? role}) async {
    final existing = await _repository.get(firebaseUser.uid);
    if (existing != null) return;
    final now = DateTime.now();
    await _repository.create(
      user: AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        role: role,
        avatarUrl: firebaseUser.photoURL,
        createdAt: now,
      ),
    );
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  @override
  Future<void> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await _ensureProfile(credential.user!, role: role);
  }

  @override
  Future<void> signInWithGoogle({UserRole? role}) async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    // role is only applied on sign-up; existing profiles keep their role.
    await _ensureProfile(result.user!, role: role);
  }

  @override
  Future<void> completeOnboarding(UserRole role) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final existing = await _repository.get(user.uid);
    if (existing == null) {
      await _repository.create(
        user: AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          role: role,
          avatarUrl: user.photoURL,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await _repository.setRole(user.uid, role);
    }
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}