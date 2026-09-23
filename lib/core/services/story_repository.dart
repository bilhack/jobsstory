import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story.dart';

/// Data access for the `stories` collection.
abstract class StoryRepository {
  Future<void> create({required Story story});
  Future<List<Story>> listOwn(String uid);
  Future<void> delete(String storyId);
}

/// Production implementation backed by Cloud Firestore.
class FirestoreStoryRepository implements StoryRepository {
  FirestoreStoryRepository([FirebaseFirestore? db]) : _db = db;

  FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _stories => _firestore.collection('stories');

  @override
  Future<void> create({required Story story}) async {
    await _stories.doc(story.id).set(story.toDoc());
  }

  @override
  Future<List<Story>> listOwn(String uid) async {
    final query = await _stories.where('ownerUid', isEqualTo: uid).orderBy('createdAt', descending: true).get();
    return query.docs.map((doc) => Story.fromDoc(doc.id, doc.data())).toList();
  }

  @override
  Future<void> delete(String storyId) async {
    await _stories.doc(storyId).delete();
  }
}