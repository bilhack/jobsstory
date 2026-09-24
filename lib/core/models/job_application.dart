import 'package:cloud_firestore/cloud_firestore.dart';

/// How far a seeker's application has progressed.
enum ApplicationStatus {
  /// Freshly submitted — the recruiter has not engaged yet.
  pending,
  contacted,
  rejected;

  String get value => switch (this) {
        ApplicationStatus.pending => 'pending',
        ApplicationStatus.contacted => 'contacted',
        ApplicationStatus.rejected => 'rejected',
      };

  static ApplicationStatus fromValue(String? value) => ApplicationStatus.values
      .firstWhere((s) => s.value == value, orElse: () => ApplicationStatus.pending);
}

/// One seeker job application, stored in Firestore `applications/{jobId_seekerUid}`.
/// Snapshots the seeker's identity + attached story so the recruiter list
/// renders without extra lookups.
class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.seekerUid,
    this.seekerName = '',
    this.seekerHeadline = '',
    this.seekerAvatar = '',
    this.seekerEmail = '',
    this.storyId,
    this.status = ApplicationStatus.pending,
    this.recruiterNote = '',
    this.appliedAt,
  });

  final String id;
  final String jobId;
  final String seekerUid;
  final String seekerName;
  final String seekerHeadline;
  final String seekerAvatar;
  final String seekerEmail;
  final String? storyId;
  final ApplicationStatus status;
  final String recruiterNote;
  final DateTime? appliedAt;

  Map<String, Object> toDoc() => {
        'jobId': jobId,
        'seekerUid': seekerUid,
        'seekerName': seekerName,
        'seekerHeadline': seekerHeadline,
        'seekerAvatar': seekerAvatar,
        'seekerEmail': seekerEmail,
        'storyId': storyId ?? '',
        'status': status.value,
        'recruiterNote': recruiterNote,
        'appliedAt': appliedAt ?? DateTime.now(),
      };

  JobApplication copyWith({
    ApplicationStatus? status,
    String? recruiterNote,
  }) =>
      JobApplication(
        id: id,
        jobId: jobId,
        seekerUid: seekerUid,
        seekerName: seekerName,
        seekerHeadline: seekerHeadline,
        seekerAvatar: seekerAvatar,
        seekerEmail: seekerEmail,
        storyId: storyId,
        status: status ?? this.status,
        recruiterNote: recruiterNote ?? this.recruiterNote,
        appliedAt: appliedAt,
      );

  factory JobApplication.fromDoc(String id, Map<String, dynamic> doc) => JobApplication(
        id: id,
        jobId: doc['jobId'] as String? ?? '',
        seekerUid: doc['seekerUid'] as String? ?? '',
        seekerName: doc['seekerName'] as String? ?? '',
        seekerHeadline: doc['seekerHeadline'] as String? ?? '',
        seekerAvatar: doc['seekerAvatar'] as String? ?? '',
        seekerEmail: doc['seekerEmail'] as String? ?? '',
        storyId: doc['storyId'] as String?,
        status: ApplicationStatus.fromValue(doc['status'] as String?),
        recruiterNote: doc['recruiterNote'] as String? ?? '',
        appliedAt: (doc['appliedAt'] as Object?) is DateTime
            ? (doc['appliedAt'] as DateTime)
            : (doc['appliedAt'] as Timestamp?)?.toDate(),
      );
}