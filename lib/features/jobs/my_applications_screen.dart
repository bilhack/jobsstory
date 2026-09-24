import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/job.dart';
import '../../core/models/job_application.dart';
import '../../core/providers/applications_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/theme/app_theme.dart';

/// Seeker-only status tracker for sent applications.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  static const String route = '/my-applications';

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final Map<String, Job> _jobs = {};

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final applications = context.read<ApplicationsProvider>();
      final uid = auth.snapshot.profile?.uid;
      if (uid == null || uid.isEmpty) return;
      await applications.loadMine(uid);
      for (final app in applications.mine) {
        unawaited(_fetchJob(app.jobId));
      }
    });
  }

  Future<void> _fetchJob(String jobId) async {
    if (_jobs.containsKey(jobId)) return;
    final job = await context.read<JobsProvider>().fetch(jobId);
    if (!mounted || job == null) return;
    setState(() => _jobs[jobId] = job);
  }

  @override
  Widget build(BuildContext context) {
    final mine = context.watch<ApplicationsProvider>().mine;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isAr ? AppStrings.myApplicationsAr : AppStrings.myApplications),
      ),
      body: SafeArea(
        child: mine.isEmpty
            ? _EmptyApplications(isAr: _isAr)
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: mine.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = mine[index];
                  final job = _jobs[app.jobId];
                  return _ApplicationCard(app: app, job: job, isAr: _isAr);
                },
              ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.app, required this.job, required this.isAr});

  final JobApplication app;
  final Job? job;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, color) = switch (app.status) {
      ApplicationStatus.pending => (
          isAr ? AppStrings.statusPendingAr : AppStrings.statusPending,
          AppColors.accent,
        ),
      ApplicationStatus.contacted => (
          isAr ? AppStrings.statusContactedAr : AppStrings.statusContacted,
          AppColors.primary,
        ),
      ApplicationStatus.rejected => (
          isAr ? AppStrings.statusRejectedAr : AppStrings.statusRejected,
          Colors.redAccent,
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job?.title ?? (app.jobId.isNotEmpty ? app.jobId : ''),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      if (job != null)
                        Text(
                          job!.company,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
            if (app.recruiterNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        app.recruiterNote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.send_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              isAr ? AppStrings.noApplicationsAr : AppStrings.noApplications,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? AppStrings.noApplicationsHintAr : AppStrings.noApplicationsHint,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}