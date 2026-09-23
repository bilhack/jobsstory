import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/story.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/story_provider.dart';
import '../../core/theme/app_theme.dart';
import 'studio_screen.dart';

/// The seeker's own stories: status, cover, publish anew or delete.
class MyStoriesScreen extends StatefulWidget {
  const MyStoriesScreen({super.key});

  static const String route = '/my-stories';

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred to the next frame so auth/profile is stable and no
    // notification fires while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().snapshot.profile?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<StoryProvider>().load(uid);
      }
    });
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isAr ? AppStrings.myStoriesAr : AppStrings.myStories),
      ),
      body: SafeArea(
        child: provider.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : provider.stories.isEmpty
                ? _EmptyState(isAr: _isAr)
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.stories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final story = provider.stories[index];
                      return _StoryCard(
                        story: story,
                        onDelete: () => context.read<StoryProvider>().deleteStory(story),
                      );
                    },
                  ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.onDelete});

  final Story story;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final statusLabel = switch (story.status) {
      StoryStatus.review => (isAr ? 'قيد المراجعة' : 'Under review'),
      StoryStatus.approved => (isAr ? 'منشورة' : 'Live'),
      StoryStatus.hidden => (isAr ? 'مخفية' : 'Hidden'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (story.thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  story.thumbnailUrl,
                  width: 64,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _CoverFallback(),
                ),
              )
            else
              const _CoverFallback(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.caption.isNotEmpty) ...[
                    Text(
                      story.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    '${story.durationLabel} • ${_formatDate(story.createdAt, isAr)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: story.status == StoryStatus.approved
                          ? const Color(0xFF1B5E20).withValues(alpha: 0.35)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isAr ? 'حذف القصة' : 'Delete story',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date, bool isAr) {
    if (date == null) return '-';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 100,
      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.videocam_outlined, color: Colors.white70),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              isAr ? AppStrings.noStoriesAr : AppStrings.noStories,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? AppStrings.noStoriesHintAr : AppStrings.noStoriesHint,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(StoryStudioScreen.route),
              icon: const Icon(Icons.add_rounded),
              label: Text(isAr ? AppStrings.createStoryCtaAr : AppStrings.createStoryCta),
            ),
          ],
        ),
      ),
    );
  }
}