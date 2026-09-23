import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/story.dart';
import '../services/story_service.dart';

/// Loads and publishes stories for the signed-in user.
class StoryProvider extends ChangeNotifier {
  StoryProvider({required StoryService service}) : _service = service;

  final StoryService _service;

  List<Story> _stories = const [];
  bool _loading = false;
  Object? _error;

  List<Story> get stories => _stories;
  bool get loading => _loading;
  Object? get error => _error;

  Future<void> load(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stories = await _service.listOwnStories(uid);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Story> publishStory({
    required File video,
    File? thumbnail,
    required String caption,
    required String ownerUid,
    void Function(double progress)? onProgress,
  }) async {
    final story = await _service.publishStory(
      video: video,
      thumbnail: thumbnail,
      caption: caption,
      ownerUid: ownerUid,
      onProgress: onProgress,
    );
    _stories = [story, ..._stories];
    notifyListeners();
    return story;
  }

  Future<void> deleteStory(Story story) async {
    await _service.deleteStory(story);
    _stories = _stories.where((s) => s.id != story.id).toList();
    notifyListeners();
  }
}