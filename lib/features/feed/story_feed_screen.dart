import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_strings.dart';
import '../../core/media/feed_video_tile.dart';
import '../../core/models/app_user.dart';
import '../../core/models/story.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/providers/story_interaction_provider.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_theme.dart';
import '../profile/seeker_profile_screen.dart';

/// Vertical full-screen feed of approved stories — TikTok-style browsing.
/// Actions: like, save (candidate), share, report. Audio is muted by default.
class StoryFeedScreen extends StatefulWidget {
  const StoryFeedScreen({super.key});

  static const String route = '/explore';

  @override
  State<StoryFeedScreen> createState() => _StoryFeedScreenState();
}

class _StoryFeedScreenState extends State<StoryFeedScreen> {
  final PageController _pageController = PageController();
  int _activeIndex = 0;
  Map<String, AppUser> _owners = const {};

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final feed = context.read<FeedProvider>();
    final auth = context.read<AuthProvider>();
    final interaction = context.read<StoryInteractionProvider>();
    final repo = context.read<UserRepository>();
    await feed.load();
    final me = auth.snapshot.profile?.uid;
    if (me != null && me.isNotEmpty) {
      await interaction.loadMine(me);
    }
    await _loadOwners(repo, feed.stories);
  }

  Future<void> _loadOwners(UserRepository repo, List<Story> stories) async {
    final map = <String, AppUser>{};
    for (final uid in stories.map((s) => s.ownerUid)) {
      if (uid.isEmpty || map.containsKey(uid)) continue;
      final user = await repo.get(uid);
      if (user != null && mounted) map[uid] = user;
    }
    if (mounted) setState(() => _owners = map);
  }

  Future<void> _share(Story story, String ownerName) async {
    final text = _isAr
        ? 'شاهد قصة ${ownerName.isEmpty ? 'الباحث' : ownerName} على ${AppStrings.appNameAr} — ${story.videoUrl}'
        : 'Watch ${ownerName.isEmpty ? 'the seeker' : ownerName}\'s story on ${AppStrings.appName} — ${story.videoUrl}';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      // Sharing is unavailable (e.g. data-only environments) — ignore.
    }
  }

  Future<void> _report(Story story) async {
    final comp = _ReportSheet(story: story);
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => comp,
    );
    if (reason == null || !mounted) return;
    final me = context.read<AuthProvider>().snapshot.profile?.uid;
    if (me == null || me.isEmpty) return;
    await context.read<StoryInteractionProvider>().report(
          storyId: story.id,
          reportedBy: me,
          reason: reason,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(_isAr ? 'شكراً لك، تم استلام البلاغ.' : 'Thanks, your report was received.'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();

    return Scaffold(
      body: SafeArea(
        child: feed.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : feed.error != null
                ? _FeedError(isAr: _isAr, onRetry: _init)
                : feed.stories.isEmpty
                    ? _EmptyFeed(isAr: _isAr, mode: context.watch<AuthProvider>().role)
                    : PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        onPageChanged: (index) => setState(() => _activeIndex = index),
                        itemCount: feed.stories.length,
                        itemBuilder: (context, index) {
                          final story = feed.stories[index];
                          return _FeedPage(
                            story: story,
                            owner: _owners[story.ownerUid],
                            active: index == _activeIndex,
                            position: '${index + 1}/${feed.stories.length}',
                            onOpenProfile: () =>
                                context.push(SeekerProfileScreen.route(story.ownerUid)),
                            onLike: () {
                              final me = context.read<AuthProvider>().snapshot.profile?.uid;
                              if (me == null || me.isEmpty) return;
                              context
                                  .read<StoryInteractionProvider>()
                                  .toggleLike(storyId: story.id, userId: me);
                            },
                            onSave: () {
                              final me = context.read<AuthProvider>().snapshot.profile?.uid;
                              if (me == null || me.isEmpty) return;
                              context
                                  .read<StoryInteractionProvider>()
                                  .toggleSaveSeeker(seekerId: story.ownerUid, savedById: me);
                            },
                            onShare: () => _share(story, _owners[story.ownerUid]?.displayName ?? ''),
                            onReport: () => _report(story),
                          );
                        },
                      ),
      ),
    );
  }
}

class _FeedPage extends StatelessWidget {
  const _FeedPage({
    required this.story,
    required this.owner,
    required this.active,
    required this.position,
    required this.onOpenProfile,
    required this.onLike,
    required this.onSave,
    required this.onShare,
    required this.onReport,
  });

  final Story story;
  final AppUser? owner;
  final bool active;
  final String position;
  final VoidCallback onOpenProfile;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final tile = context.watch<FeedVideoTile>();
    final interactions = context.watch<StoryInteractionProvider>();
    final name = owner?.displayName ?? '';
    final headline = owner?.headline ?? '';
    final location = owner?.location ?? '';
    final liked = interactions.isLiked(story.id);
    final saved = interactions.isSaved(story.ownerUid);

    return Stack(
      fit: StackFit.expand,
      children: [
        tile.build(
          videoUrl: story.videoUrl,
          thumbnailUrl: story.thumbnailUrl,
          autoplay: active,
          initiallyMuted: true,
        ),
        const _Scrim(top: true, colors: [Color(0x66000000), Color(0x00000000)]),
        const _Scrim(top: false, colors: [Color(0x00000000), Color(0xCC000000)]),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? AppStrings.appNameAr : AppStrings.appName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(position, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 72,
          bottom: 20,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: name.isEmpty
                            ? const Icon(Icons.person_rounded, color: Colors.white)
                            : Text(
                                name.characters.first,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            if (headline.isNotEmpty)
                              Text(headline, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            if (location.isNotEmpty)
                              Text(location, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (story.caption.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(story.caption, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                  ],
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: onOpenProfile,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Text(
                          isAr ? AppStrings.viewProfileAr : AppStrings.viewProfile,
                          style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 20,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RailAction(
                  icon: liked ? Icons.favorite : Icons.favorite_border,
                  active: liked,
                  activeColor: AppColors.danger,
                  onTap: onLike,
                ),
                const SizedBox(height: 18),
                _RailAction(
                  icon: saved ? Icons.bookmark : Icons.bookmark_border,
                  active: saved,
                  activeColor: AppColors.accent,
                  onTap: onSave,
                ),
                const SizedBox(height: 18),
                _RailAction(icon: Icons.share_rounded, onTap: onShare),
                const SizedBox(height: 18),
                _RailAction(icon: Icons.flag_outlined, onTap: onReport),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction({required this.icon, this.onTap, this.active = false, this.activeColor});

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: active ? (activeColor ?? AppColors.danger) : Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.top, required this.colors});

  final bool top;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _ReportSheet extends StatelessWidget {
  const _ReportSheet({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final reasons = [
      (isAr ? 'محتوى غير لائق' : 'Inappropriate content'),
      (isAr ? 'مزعج أو تضليل' : 'Harassment or misleading'),
      (isAr ? 'انتحال هوية' : 'Impersonation'),
      (isAr ? 'أخرى' : 'Other'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isAr ? 'الإبلاغ عن القصة' : 'Report story',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              isAr ? 'اختر سبباً للإبلاغ. لن نكشف هويتك.' : 'Choose a reason. Your identity stays private.',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, reason),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(reason),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.isAr, required this.mode});

  final bool isAr;
  final UserRole? mode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              isAr ? AppStrings.feedEmptyAr : AppStrings.feedEmpty,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? AppStrings.feedEmptyHintAr : AppStrings.feedEmptyHint,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.isAr, required this.onRetry});

  final bool isAr;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isAr ? 'تعذّر تحميل التغذية.' : 'Could not load the feed.'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }
}