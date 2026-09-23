import 'package:cloud_firestore/cloud_firestore.dart';

/// Moderation state of a story.
enum StoryStatus {
  /// Fresh upload, waiting for review before it reaches the feed (Phase 3).
  review,
  approved,
  hidden;

  String get value => switch (this) {
        StoryStatus.review => 'review',
        StoryStatus.approved => 'approved',
        StoryStatus.hidden => 'hidden',
      };

  static StoryStatus fromValue(String? value) =>
      StoryStatus.values.firstWhere((s) => s.value == value, orElse: () => StoryStatus.review);
}

/// A 60-second video story stored in Firestore `stories/{storyId}`.
class Story {
  const Story({
    required this.id,
    required this.ownerUid,
    this.videoUrl = '',
    this.thumbnailUrl = '',
    this.caption = '',
    this.durationMs = 0,
    this.status = StoryStatus.review,
    this.createdAt,
  });

  final String id;
  final String ownerUid;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int durationMs;
  final StoryStatus status;
  final DateTime? createdAt;

  String get durationLabel {
    final seconds = (durationMs / 1000).round();
    return '$seconds${"'"}';
  }

  Map<String, Object> toDoc() => {
        'ownerUid': ownerUid,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'durationMs': durationMs,
        'status': status.value,
        'createdAt': createdAt ?? DateTime.now(),
      };

  Story copyWith({StoryStatus? status}) => Story(
        id: id,
        ownerUid: ownerUid,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        durationMs: durationMs,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  factory Story.fromDoc(String id, Map<String, dynamic> doc) => Story(
        id: id,
        ownerUid: doc['ownerUid'] as String? ?? '',
        videoUrl: doc['videoUrl'] as String? ?? '',
        thumbnailUrl: doc['thumbnailUrl'] as String? ?? '',
        caption: doc['caption'] as String? ?? '',
        durationMs: (doc['durationMs'] as num?)?.toInt() ?? 0,
        status: StoryStatus.fromValue(doc['status'] as String?),
        createdAt: (doc['createdAt'] as Object?) is DateTime
            ? (doc['createdAt'] as DateTime)
            : (doc['createdAt'] as Timestamp?)?.toDate(),
      );
}