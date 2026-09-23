import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Exposes the current session to the widget tree (change-notifier).
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService service}) : _service = service {
    _subscription = service.snapshots.listen((snapshot) {
      _snapshot = snapshot;
      notifyListeners();
    });
  }

  final AuthService _service;
  StreamSubscription<AuthSnapshot>? _subscription;
  AuthSnapshot _snapshot = AuthSnapshot.unsigned;

  AuthSnapshot get snapshot => _snapshot;
  bool get isAuthenticated => _snapshot.isSignedIn;
  bool get hasRole => _snapshot.hasProfile && _snapshot.profile!.hasRole;
  UserRole? get role => _snapshot.profile?.role;

  Future<void> signInWithEmail(String email, String password) =>
      _service.signInWithEmail(email, password);

  Future<void> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
    required UserRole role,
  }) =>
      _service.signUpWithEmail(
        displayName: displayName,
        email: email,
        password: password,
        role: role,
      );

  Future<void> signInWithGoogle({UserRole? role}) => _service.signInWithGoogle(role: role);

  Future<void> completeOnboarding(UserRole role) => _service.completeOnboarding(role);

  Future<void> signOut() => _service.signOut();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}