import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles on the platform.
enum UserRole {
  seeker,
  recruiter;

  String get value => switch (this) {
        UserRole.seeker => 'seeker',
        UserRole.recruiter => 'recruiter',
      };

  static UserRole? fromValue(String? value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

/// Application profile stored in Firestore `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role,
    this.avatarUrl,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole? role;
  final String? avatarUrl;
  final DateTime? createdAt;

  bool get hasRole => role != null;

  AppUser copyWith({UserRole? role}) => AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        role: role ?? this.role,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );

  Map<String, Object> toDoc() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role?.value ?? '',
        'avatarUrl': avatarUrl ?? '',
        'createdAt': createdAt ?? DateTime.now(),
      };

  factory AppUser.fromDoc(String uid, Map<String, dynamic> doc) => AppUser(
        uid: uid,
        email: doc['email'] as String? ?? '',
        displayName: doc['displayName'] as String? ?? '',
        role: UserRole.fromValue(doc['role'] as String?),
        avatarUrl: doc['avatarUrl'] as String?,
        createdAt: (doc['createdAt'] as Object?) is DateTime
            ? (doc['createdAt'] as DateTime)
            : (doc['createdAt'] as Timestamp?)?.toDate(),
      );
}