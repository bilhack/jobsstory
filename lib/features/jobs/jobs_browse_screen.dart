import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/job.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/theme/app_theme.dart';
import 'job_detail_screen.dart';

/// Seeker-only browse screen for open job postings.
class JobsBrowseScreen extends StatefulWidget {
  const JobsBrowseScreen({super.key});

  static const String route = '/jobs';

  @override
  State<JobsBrowseScreen> createState() => _JobsBrowseScreenState();
}

class _JobsBrowseScreenState extends State<JobsBrowseScreen> {
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobsProvider>().loadOpen();
    });
  }

  Future<void> _openLinkedInJobs() async {
    const url = 'https://www.linkedin.com/jobs';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobsProvider>();
    final jobs = provider.openJobs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isAr ? AppStrings.jobsAr : AppStrings.jobs),
      ),
      body: SafeArea(
        child: provider.loading && jobs.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : jobs.isEmpty
                ? _EmptyJobs(isAr: _isAr, onLinkedIn: _openLinkedInJobs)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _LinkedInMoreTile(isAr: _isAr, onTap: _openLinkedInJobs),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          itemCount: jobs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _JobCard(
                            job: jobs[index],
                            isAr: _isAr,
                            onTap: () => context.push(JobDetailScreen.route(jobs[index].id)),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _LinkedInMoreTile extends StatelessWidget {
  const _LinkedInMoreTile({required this.isAr, required this.onTap});

  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? AppStrings.browseLinkedInMoreAr : AppStrings.browseLinkedInMore,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'linkedin.com/jobs',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.isAr, required this.onTap});

  final Job job;
  final bool isAr;
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
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.work_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      [job.company, if (job.location.isNotEmpty) job.location].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
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

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs({required this.isAr, required this.onLinkedIn});

  final bool isAr;
  final VoidCallback onLinkedIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              isAr ? AppStrings.noOpenJobsAr : AppStrings.noOpenJobs,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? AppStrings.noOpenJobsHintAr : AppStrings.noOpenJobsHint,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onLinkedIn,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: Text(isAr ? AppStrings.browseLinkedInAr : AppStrings.browseLinkedIn),
            ),
          ],
        ),
      ),
    );
  }
}