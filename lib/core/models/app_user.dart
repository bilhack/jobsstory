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
    this.headline = '',
    this.bio = '',
    this.location = '',
    this.skills = const [],
    this.experience = '',
    this.education = '',
    this.languages = const [],
    this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole? role;
  final String? avatarUrl;
  final String headline;
  final String bio;
  final String location;
  final List<String> skills;
  final String experience;
  final String education;
  final List<String> languages;
  final DateTime? createdAt;

  bool get hasRole => role != null;

  bool get hasProfileDetails =>
      headline.isNotEmpty || bio.isNotEmpty || location.isNotEmpty || skills.isNotEmpty;

  AppUser copyWith({
    UserRole? role,
    String? headline,
    String? bio,
    String? location,
    List<String>? skills,
    String? experience,
    String? education,
    List<String>? languages,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        role: role ?? this.role,
        avatarUrl: avatarUrl,
        headline: headline ?? this.headline,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        skills: skills ?? this.skills,
        experience: experience ?? this.experience,
        education: education ?? this.education,
        languages: languages ?? this.languages,
        createdAt: createdAt,
      );

  Map<String, Object> toDoc() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role?.value ?? '',
        'avatarUrl': avatarUrl ?? '',
        'headline': headline,
        'bio': bio,
        'location': location,
        'skills': skills,
        'experience': experience,
        'education': education,
        'languages': languages,
        'createdAt': createdAt ?? DateTime.now(),
      };

  factory AppUser.fromDoc(String uid, Map<String, dynamic> doc) {
    List<String> strings(String key) =>
        ((doc[key] as List<dynamic>?) ?? const []).whereType<String>().toList();

    return AppUser(
      uid: uid,
      email: doc['email'] as String? ?? '',
      displayName: doc['displayName'] as String? ?? '',
      role: UserRole.fromValue(doc['role'] as String?),
      avatarUrl: doc['avatarUrl'] as String?,
      headline: doc['headline'] as String? ?? '',
      bio: doc['bio'] as String? ?? '',
      location: doc['location'] as String? ?? '',
      skills: strings('skills'),
      experience: doc['experience'] as String? ?? '',
      education: doc['education'] as String? ?? '',
      languages: strings('languages'),
      createdAt: (doc['createdAt'] as Object?) is DateTime
          ? (doc['createdAt'] as DateTime)
          : (doc['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}