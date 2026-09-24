import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobsstory/core/models/story.dart';
import 'package:jobsstory/core/providers/feed_provider.dart';
import 'package:jobsstory/core/providers/story_interaction_provider.dart';
import 'package:jobsstory/core/providers/story_provider.dart';

import 'fakes.dart';

void main() {
  group('Story model', () {
    test('toDoc/fromDoc round-trips all fields', () {
      final original = Story(
        id: 'u_123',
        ownerUid: 'u_123',
        videoUrl: 'https://cdn/v.mp4',
        thumbnailUrl: 'https://cdn/t.jpg',
        caption: 'مرحباً',
        durationMs: 45000,
        status: StoryStatus.approved,
        createdAt: DateTime.utc(2026, 9, 24),
      );

      final restored = Story.fromDoc(original.id, original.toDoc());

      expect(restored.id, original.id);
      expect(restored.ownerUid, original.ownerUid);
      expect(restored.videoUrl, original.videoUrl);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
      expect(restored.caption, original.caption);
      expect(restored.durationMs, original.durationMs);
      expect(restored.status, StoryStatus.approved);
      expect(restored.createdAt, original.createdAt);
    });

    test('unknown status string falls back to review', () {
      final story = Story.fromDoc('x', {
        'ownerUid': 'u',
        'status': 'bogus',
      });
      expect(story.status, StoryStatus.review);
    });

    test('duration label formats seconds', () {
      expect(const Story(id: 'x', ownerUid: 'u', durationMs: 60000).durationLabel, "60'");
    });
  });

  group('StoryProvider', () {
    test('publish inserts the story at the top and fires progress', () async {
      final service = FakeStoryService();
      final provider = StoryProvider(service: service);
      final progress = <double>[];

      final story = await provider.publishStory(
        video: File('${Directory.systemTemp.path}/v.mp4'),
        ownerUid: 'u1',
        caption: 'قصتي',
        onProgress: progress.add,
      );

      expect(story.status, StoryStatus.review);
      expect(provider.stories, hasLength(1));
      expect(provider.stories.first.id, story.id);
      expect(progress, contains(0.5));
      expect(progress.last, 1.0);
    });

    test('delete removes the story from the provider list', () async {
      final service = FakeStoryService();
      final provider = StoryProvider(service: service);
      await provider.publishStory(
        video: File('${Directory.systemTemp.path}/v.mp4'),
        ownerUid: 'u1',
        caption: 'قصتي',
      );
      final story = provider.stories.single;

      await provider.deleteStory(story);

      expect(provider.stories, isEmpty);
    });

    test('load pulls owned stories and reorders list', () async {
      final service = FakeStoryService();
      service.seed([
        const Story(id: 'a', ownerUid: 'u1', caption: 'الأولى'),
        const Story(id: 'b', ownerUid: 'u1', caption: 'الثانية'),
        const Story(id: 'c', ownerUid: 'other', caption: 'ليست لي'),
      ]);
      final provider = StoryProvider(service: service);

      await provider.load('u1');

      expect(provider.stories.map((s) => s.id), ['a', 'b']);
    });
  });

  group('FeedProvider', () {
    test('load returns only approved stories', () async {
      final service = FakeStoryService();
      service.seed([
        const Story(id: 's1', ownerUid: 'u', caption: 'معتمدة', status: StoryStatus.approved),
        const Story(id: 's2', ownerUid: 'u', caption: 'قيد المراجعة'),
      ]);
      final provider = FeedProvider(service: service);

      await provider.load();

      expect(provider.stories.map((s) => s.id), ['s1']);
    });

    test('surfaces load errors', () async {
      final service = FakeStoryService()..errorToThrow = StateError('boom');
      final provider = FeedProvider(service: service);

      await provider.load();

      expect(provider.error, isA<StateError>());
      expect(provider.stories, isEmpty);
    });
  });

  group('StoryInteractionProvider', () {
    test('toggleLike toggles the set and persists', () async {
      final service = FakeStoryInteractionService();
      final provider = StoryInteractionProvider(service: service);

      await provider.loadMine('u1');
      expect(provider.isLiked('s1'), isFalse);

      await provider.toggleLike(storyId: 's1', userId: 'u1');
      expect(provider.isLiked('s1'), isTrue);
      expect(service.liked, contains('s1_u1'));

      await provider.toggleLike(storyId: 's1', userId: 'u1');
      expect(provider.isLiked('s1'), isFalse);
      expect(service.liked, isEmpty);
    });

    test('toggleSaveSeeker toggles candidate saves', () async {
      final service = FakeStoryInteractionService();
      final provider = StoryInteractionProvider(service: service);

      await provider.loadMine('u1');
      await provider.toggleSaveSeeker(seekerId: 'sa', savedById: 'u1');
      expect(provider.isSaved('sa'), isTrue);
      expect(service.saved, contains('u1_sa'));

      await provider.toggleSaveSeeker(seekerId: 'sa', savedById: 'u1');
      expect(provider.isSaved('sa'), isFalse);
    });

    test('report is forwarded to the service with reason', () async {
      final service = FakeStoryInteractionService();
      final provider = StoryInteractionProvider(service: service);

      await provider.report(storyId: 's1', reportedBy: 'u1', reason: 'محتوى غير لائق');

      expect(service.reportCount, 1);
      expect(service.reports.single['reason'], 'محتوى غير لائق');
    });
  });
}