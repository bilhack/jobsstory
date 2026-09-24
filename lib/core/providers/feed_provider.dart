import 'package:flutter/foundation.dart';

import '../models/story.dart';
import '../services/story_service.dart';

/// Loads the approved stories that make up the discover feed.
class FeedProvider extends ChangeNotifier {
  FeedProvider({required StoryService service}) : _service = service;

  final StoryService _service;

  List<Story> _stories = const [];
  bool _loading = false;
  Object? _error;

  List<Story> get stories => _stories;
  bool get loading => _loading;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stories = await _service.fetchApprovedStories();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}