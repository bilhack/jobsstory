import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/job.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/theme/app_theme.dart';
import 'job_applicants_screen.dart';
import 'job_create_screen.dart';

/// Recruiter-only list of the recruiter's postings.
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  static const String route = '/my-jobs';

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().snapshot.profile?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<JobsProvider>().loadMine(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobsProvider>();
    final jobs = provider.myJobs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isAr ? AppStrings.myJobsAr : AppStrings.myJobs),
        actions: [
          IconButton(
            tooltip: _isAr ? AppStrings.postJobAr : AppStrings.postJob,
            onPressed: () => context.push(JobCreateScreen.route),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: provider.loading && jobs.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : jobs.isEmpty
                ? _EmptyJobs(isAr: _isAr)
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _MyJobCard(
                      job: jobs[index],
                      isAr: _isAr,
                      onTap: () => context.push(JobApplicantsScreen.route(jobs[index].id)),
                      onToggle: () {
                        final next = jobs[index].status == JobStatus.open
                            ? JobStatus.closed
                            : JobStatus.open;
                        context.read<JobsProvider>().setStatus(jobs[index], next);
                      },
                    ),
                  ),
      ),
    );
  }
}

class _MyJobCard extends StatelessWidget {
  const _MyJobCard({
    required this.job,
    required this.isAr,
    required this.onTap,
    required this.onToggle,
  });

  final Job job;
  final bool isAr;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final open = job.status == JobStatus.open;
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: open
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.textMuted.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        open
                            ? (isAr ? AppStrings.jobStatusOpenAr : AppStrings.jobStatusOpen)
                            : (isAr ? AppStrings.jobStatusClosedAr : AppStrings.jobStatusClosed),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: open ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<bool>(
                tooltip: isAr ? AppStrings.updateStatusAr : AppStrings.updateStatus,
                onSelected: (_) {
                  onToggle();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: true,
                    child: Text(
                      open
                          ? (isAr ? AppStrings.closeJobAr : AppStrings.closeJob)
                          : (isAr ? AppStrings.reopenJobAr : AppStrings.reopenJob),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.post_add_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              isAr ? AppStrings.postJobAr : AppStrings.postJob,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? AppStrings.myJobsHintAr : AppStrings.myJobsHint,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push(JobCreateScreen.route),
              child: Text(isAr ? AppStrings.postJobAr : AppStrings.postJob),
            ),
          ],
        ),
      ),
    );
  }
}