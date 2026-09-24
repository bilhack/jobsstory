import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Reads public profiles and maintains the signed-in user's own profile.
abstract class UserRepository {
  Future<AppUser?> get(String uid);
  Future<void> create({required AppUser user});
  Future<void> setRole(String uid, UserRole role);
}

/// Production implementation backed by Cloud Firestore `users/{uid}`.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository([FirebaseFirestore? db]) : _db = db;

  FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  @override
  Future<AppUser?> get(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc.id, doc.data() ?? const {});
  }

  @override
  Future<void> create({required AppUser user}) async {
    await _firestore.collection('users').doc(user.uid).set(user.toDoc());
  }

  @override
  Future<void> setRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({'role': role.value});
  }
}