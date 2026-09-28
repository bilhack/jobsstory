import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a job posting.
enum JobStatus {
  open,
  closed;

  String get value => switch (this) {
        JobStatus.open => 'open',
        JobStatus.closed => 'closed',
      };

  static JobStatus fromValue(String? value) =>
      JobStatus.values.firstWhere((s) => s.value == value, orElse: () => JobStatus.open);
}

/// A job posting owned by a recruiter, stored in Firestore `jobs/{jobId}`.
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    this.location = '',
    this.description = '',
    required this.createdBy,
    this.status = JobStatus.open,
    this.createdAt,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String createdBy;
  final JobStatus status;
  final DateTime? createdAt;

  Map<String, Object> toDoc() => {
        'title': title,
        'company': company,
        'location': location,
        'description': description,
        'createdBy': createdBy,
        'status': status.value,
        'createdAt': createdAt ?? DateTime.now(),
      };

  Job copyWith({JobStatus? status}) => Job(
        id: id,
        title: title,
        company: company,
        location: location,
        description: description,
        createdBy: createdBy,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  factory Job.fromDoc(String id, Map<String, dynamic> doc) => Job(
        id: id,
        title: doc['title'] as String? ?? '',
        company: doc['company'] as String? ?? '',
        location: doc['location'] as String? ?? '',
        description: doc['description'] as String? ?? '',
        createdBy: doc['createdBy'] as String? ?? '',
        status: JobStatus.fromValue(doc['status'] as String?),
        createdAt: (doc['createdAt'] as Object?) is DateTime
            ? (doc['createdAt'] as DateTime)
            : (doc['createdAt'] as Timestamp?)?.toDate(),
      );
}