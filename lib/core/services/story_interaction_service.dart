import 'package:cloud_firestore/cloud_firestore.dart';

/// Social actions on the feed: like, save (candidates) and report.
/// Persisted into Firestore `likes`, `saves` and `reports` collections.
abstract class StoryInteractionService {
  Future<void> likeStory({required String storyId, required String userId});
  Future<void> unlikeStory({required String storyId, required String userId});
  Future<List<String>> likedStoryIds(String userId);

  Future<void> saveSeeker({required String seekerId, required String savedById});
  Future<void> unsaveSeeker({required String seekerId, required String savedById});
  Future<List<String>> savedSeekerIds(String savedById);

  Future<void> reportStory({
    required String storyId,
    required String reportedBy,
    required String reason,
    String? details,
  });
}

/// Production implementation backed by Cloud Firestore.
/// Firebase instances are resolved lazily so the service can be injected
/// before `Firebase.initializeApp` in tests.
class FirebaseStoryInteractionService implements StoryInteractionService {
  FirebaseStoryInteractionService([FirebaseFirestore? db]) : _db = db;

  FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  @override
  Future<void> likeStory({required String storyId, required String userId}) async {
    await _firestore.collection('likes').doc('${storyId}_$userId').set({
      'storyId': storyId,
      'userId': userId,
      'createdAt': DateTime.now(),
    });
  }

  @override
  Future<void> unlikeStory({required String storyId, required String userId}) async {
    await _firestore.collection('likes').doc('${storyId}_$userId').delete();
  }

  @override
  Future<List<String>> likedStoryIds(String userId) async {
    final query = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs.map((doc) => doc.data()['storyId'] as String? ?? '').where((id) => id.isNotEmpty).toList();
  }

  @override
  Future<void> saveSeeker({required String seekerId, required String savedById}) async {
    await _firestore.collection('saves').doc('${savedById}_$seekerId').set({
      'savedById': savedById,
      'seekerId': seekerId,
      'targetType': 'seeker',
      'createdAt': DateTime.now(),
    });
  }

  @override
  Future<void> unsaveSeeker({required String seekerId, required String savedById}) async {
    await _firestore.collection('saves').doc('${savedById}_$seekerId').delete();
  }

  @override
  Future<List<String>> savedSeekerIds(String savedById) async {
    final query = await _firestore
        .collection('saves')
        .where('savedById', isEqualTo: savedById)
        .get();
    final ids = query.docs
        .map((doc) => doc.data()['seekerId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    return ids;
  }

  @override
  Future<void> reportStory({
    required String storyId,
    required String reportedBy,
    required String reason,
    String? details,
  }) async {
    await _firestore.collection('reports').add({
      'contentType': 'story',
      'targetId': storyId,
      'reportedBy': reportedBy,
      'reason': reason,
      'details': details ?? '',
      'status': 'open',
      'createdAt': DateTime.now(),
    });
  }
}