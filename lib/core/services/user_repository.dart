import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Data access for the `users` collection.
abstract class UserRepository {
  Future<AppUser?> get(String uid);
  Future<void> create({required AppUser user});
  Future<void> setRole(String uid, UserRole role);
}

/// Production implementation backed by Cloud Firestore.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  @override
  Future<AppUser?> get(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(uid, doc.data()!);
  }

  @override
  Future<void> create({required AppUser user}) async {
    await _users.doc(user.uid).set(user.toDoc());
  }

  @override
  Future<void> setRole(String uid, UserRole role) async {
    await _users.doc(uid).update({'role': role.value});
  }
}