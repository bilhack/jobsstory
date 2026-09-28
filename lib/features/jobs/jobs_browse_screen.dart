import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/job.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
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
                ? const _EmptyJobs()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _JobCard(
                      job: jobs[index],
                      onTap: () => context.push(JobDetailScreen.route(jobs[index].id)),
                    ),
                  ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});

  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final posted = jobPostedLabel(job.createdAt, isAr);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  job.company.isEmpty ? '?' : job.company.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (job.location.isNotEmpty) ...[
                          const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              job.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                            ),
                          ),
                        ],
                        if (job.location.isNotEmpty && posted.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            '•',
                            style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(width: 5),
                        ],
                        if (posted.isNotEmpty)
                          Text(
                            posted,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
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
          ],
        ),
      ),
    );
  }
}

