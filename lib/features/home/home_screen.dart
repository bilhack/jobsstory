import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../feed/saved_candidates_screen.dart';
import '../feed/story_feed_screen.dart';
import '../jobs/jobs_browse_screen.dart';
import '../jobs/my_applications_screen.dart';
import '../jobs/my_jobs_screen.dart';
import '../story/my_stories_screen.dart';
import '../story/studio_screen.dart';

/// Post-auth dashboard. Both roles get a discovery grid; seekers create and
/// manage their story, recruiters manage their saved candidates.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String route = '/home';

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final auth = context.watch<AuthProvider>();
    final profile = auth.snapshot.profile;
    final isSeeker = auth.role == UserRole.seeker;
    final initial = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName.trim().characters.first.toUpperCase()
        : '!';
    final roleLabel = switch (auth.role) {
      UserRole.seeker => (isAr ? AppStrings.roleSeekerAr : AppStrings.roleSeeker),
      UserRole.recruiter => (isAr ? AppStrings.roleRecruiterAr : AppStrings.roleRecruiter),
      null => '',
    };
    final name = (profile?.displayName.isNotEmpty ?? false) ? profile!.displayName : '';
    final tiles = _buildTiles(context, isAr, isSeeker);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            // Brand row.
            Row(
              children: [
                const GradientMark(size: 34),
                const SizedBox(width: 10),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21, letterSpacing: 0.4),
                ),
                const Spacer(),
                IconButton(
                  tooltip: isAr ? AppStrings.signOutAr : AppStrings.signOut,
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Hero greeting card.
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isAr ? AppStrings.homeHelloAr : AppStrings.homeHello} $name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSeeker
                        ? (isAr ? 'جاهز لتحكي قصتك القادمة؟ سجّل فيديو يوصلك.' : 'Ready to tell your next story? 60 seconds of you.')
                        : (isAr ? 'اكتشف مواهب جديدة من قصص المرشحين.' : 'Discover fresh talent through candidate stories.'),
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Quick access grid.
            SectionTitle(isSeeker ? (isAr ? 'ابدأ من هنا' : 'Start here') : (isAr ? 'لوحة العمل' : 'Your workspace')),
            for (var i = 0; i < tiles.length; i += 2) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (i + 2 < tiles.length) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  List<_QuickTile> _buildTiles(BuildContext context, bool isAr, bool isSeeker) {
    final tiles = <_QuickTile>[];
    if (isSeeker) {
      tiles.add(_QuickTile(
        icon: Icons.videocam_rounded,
        title: isAr ? AppStrings.createStoryCtaAr : AppStrings.createStoryCta,
        subtitle: isAr ? AppStrings.studioHintAr : AppStrings.studioHint,
        tileGradient: AppColors.buttonGradient,
        onTap: () => context.go(StoryStudioScreen.route),
      ));
      tiles.add(_QuickTile(
        icon: Icons.explore_rounded,
        title: isAr ? AppStrings.exploreAr : AppStrings.explore,
        subtitle: isAr ? AppStrings.exploreHintAr : AppStrings.exploreHint,
        tileGradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary]),
        onTap: () => context.go(StoryFeedScreen.route),
      ));
      tiles.add(_QuickTile(
        icon: Icons.video_library_rounded,
        title: isAr ? AppStrings.myStoriesAr : AppStrings.myStories,
        subtitle: isAr ? 'اعرض قصصك وراجع حالاتها' : 'See your stories and their status',
        tileGradient: const LinearGradient(colors: [AppColors.amber, AppColors.secondary]),
        onTap: () => context.go(MyStoriesScreen.route),
      ));
      tiles.add(_QuickTile(
        icon: Icons.work_rounded,
        title: isAr ? AppStrings.jobsAr : AppStrings.jobs,
        subtitle: isAr ? AppStrings.jobsHintAr : AppStrings.jobsHint,
        tileGradient: const LinearGradient(colors: [AppColors.success, AppColors.accent]),
        onTap: () => context.go(JobsBrowseScreen.route),
      ));
      tiles.add(_QuickTile(
        icon: Icons.send_rounded,
        title: isAr ? AppStrings.myApplicationsAr : AppStrings.myApplications,
        subtitle: isAr ? AppStrings.noApplicationsHintAr : AppStrings.noApplicationsHint,
        tileGradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
        onTap: () => context.go(MyApplicationsScreen.route),
      ));
    } else {
      tiles.add(_QuickTile(
        icon: Icons.explore_rounded,
        title: isAr ? AppStrings.exploreAr : AppStrings.explore,
        subtitle: isAr ? AppStrings.exploreHintAr : AppStrings.exploreHint,
        tileGradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary]),
        onTap: () => context.go(StoryFeedScreen.route),
      ));
      tiles.add(_QuickTile(
        icon: Icons.bookmark_rounded,
        title: isAr ? AppStrings.candidatesAr : AppStrings.candidates,
        subtitle: isAr ? AppStrings.candidatesHintAr : AppStrings.candidatesHint,
        tileGradient: const LinearGradient(colors: [AppColors.amber, AppColors.secondary]),
        onTap: () => context.go(SavedCandidatesScreen.route),
      ));
      tiles.add(_QuickTile(
        icon: Icons.work_rounded,
        title: isAr ? AppStrings.myJobsAr : AppStrings.myJobs,
        subtitle: isAr ? AppStrings.myJobsHintAr : AppStrings.myJobsHint,
        tileGradient: AppColors.buttonGradient,
        onTap: () => context.go(MyJobsScreen.route),
      ));
    }
    return tiles;
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tileGradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient tileGradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minHeight: 132),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.surfaceLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: tileGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: tileGradient.colors.first.withValues(alpha: 0.4), blurRadius: 14),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}