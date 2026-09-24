import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../feed/saved_candidates_screen.dart';
import '../feed/story_feed_screen.dart';
import '../jobs/jobs_browse_screen.dart';
import '../jobs/my_applications_screen.dart';
import '../jobs/my_jobs_screen.dart';
import '../story/my_stories_screen.dart';
import '../story/studio_screen.dart';

/// Post-auth shell. Both roles get the discover feed; seekers create and
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
    final roleLabel = switch (auth.role) {
      UserRole.seeker => (isAr ? AppStrings.roleSeekerAr : AppStrings.roleSeeker),
      UserRole.recruiter => (isAr ? AppStrings.roleRecruiterAr : AppStrings.roleRecruiter),
      null => '',
    };
    final name = (profile?.displayName.isNotEmpty ?? false) ? profile!.displayName : '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                  IconButton(
                    tooltip: isAr ? AppStrings.signOutAr : AppStrings.signOut,
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isAr ? AppStrings.homeHelloAr : AppStrings.homeHello} $name',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _ActionCard(
                      icon: Icons.explore_rounded,
                      title: (isAr ? AppStrings.exploreAr : AppStrings.explore),
                      subtitle: (isAr ? AppStrings.exploreHintAr : AppStrings.exploreHint),
                      onTap: () => context.go(StoryFeedScreen.route),
                    ),
                    const SizedBox(height: 12),
                    if (isSeeker) ...[
                      _ActionCard(
                        icon: Icons.videocam_rounded,
                        title: (isAr ? AppStrings.createStoryCtaAr : AppStrings.createStoryCta),
                        subtitle: (isAr ? AppStrings.studioHintAr : AppStrings.studioHint),
                        onTap: () => context.go(StoryStudioScreen.route),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.video_library_rounded,
                        title: (isAr ? AppStrings.myStoriesAr : AppStrings.myStories),
                        subtitle: (isAr ? 'اعرض قصصك وراجع حالاتها' : 'See your stories and their status'),
                        onTap: () => context.go(MyStoriesScreen.route),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.work_rounded,
                        title: (isAr ? AppStrings.jobsAr : AppStrings.jobs),
                        subtitle: (isAr ? AppStrings.jobsHintAr : AppStrings.jobsHint),
                        onTap: () => context.go(JobsBrowseScreen.route),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.send_rounded,
                        title: (isAr ? AppStrings.myApplicationsAr : AppStrings.myApplications),
                        subtitle: (isAr ? AppStrings.noApplicationsHintAr : AppStrings.noApplicationsHint),
                        onTap: () => context.go(MyApplicationsScreen.route),
                      ),
                    ] else ...[
                      _ActionCard(
                        icon: Icons.bookmark_rounded,
                        title: (isAr ? AppStrings.candidatesAr : AppStrings.candidates),
                        subtitle: (isAr ? AppStrings.candidatesHintAr : AppStrings.candidatesHint),
                        onTap: () => context.go(SavedCandidatesScreen.route),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.work_rounded,
                        title: (isAr ? AppStrings.myJobsAr : AppStrings.myJobs),
                        subtitle: (isAr ? AppStrings.myJobsHintAr : AppStrings.myJobsHint),
                        onTap: () => context.go(MyJobsScreen.route),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}