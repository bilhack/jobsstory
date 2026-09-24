import 'package:flutter/foundation.dart';

import '../services/story_interaction_service.dart';

/// Holds the signed-in user's likes & saved candidates, and forwards
/// like/save/report actions to the interaction service.
class StoryInteractionProvider extends ChangeNotifier {
  StoryInteractionProvider({required StoryInteractionService service}) : _service = service;

  final StoryInteractionService _service;

  Set<String> _likedStoryIds = const {};
  Set<String> _savedSeekerIds = const {};
  Object? _error;

  Set<String> get likedStoryIds => _likedStoryIds;
  Set<String> get savedSeekerIds => _savedSeekerIds;
  Object? get error => _error;

  bool isLiked(String storyId) => _likedStoryIds.contains(storyId);
  bool isSaved(String seekerId) => _savedSeekerIds.contains(seekerId);

  Future<void> loadMine(String userId) async {
    try {
      _likedStoryIds = (await _service.likedStoryIds(userId)).toSet();
      _savedSeekerIds = (await _service.savedSeekerIds(userId)).toSet();
      _error = null;
    } catch (e) {
      _error = e;
    }
    notifyListeners();
  }

  Future<void> toggleLike({required String storyId, required String userId}) async {
    final liked = isLiked(storyId);
    final updated = Set<String>.from(_likedStoryIds);
    liked ? updated.remove(storyId) : updated.add(storyId);
    _likedStoryIds = updated;
    notifyListeners();
    try {
      liked
          ? await _service.unlikeStory(storyId: storyId, userId: userId)
          : await _service.likeStory(storyId: storyId, userId: userId);
    } catch (e) {
      _error = e;
    }
  }

  Future<void> toggleSaveSeeker({required String seekerId, required String savedById}) async {
    final saved = isSaved(seekerId);
    final updated = Set<String>.from(_savedSeekerIds);
    saved ? updated.remove(seekerId) : updated.add(seekerId);
    _savedSeekerIds = updated;
    notifyListeners();
    try {
      saved
          ? await _service.unsaveSeeker(seekerId: seekerId, savedById: savedById)
          : await _service.saveSeeker(seekerId: seekerId, savedById: savedById);
    } catch (e) {
      _error = e;
    }
  }

  Future<void> report({
    required String storyId,
    required String reportedBy,
    required String reason,
    String? details,
  }) {
    return _service.reportStory(
      storyId: storyId,
      reportedBy: reportedBy,
      reason: reason,
      details: details,
    );
  }
}