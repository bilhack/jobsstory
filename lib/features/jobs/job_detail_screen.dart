import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/job.dart';
import '../../core/providers/applications_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/services/story_service.dart';
import '../../core/theme/app_theme.dart';
import '../story/studio_screen.dart';

/// Seeker-only job detail with a one-tap "apply with my story" action.
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  static String route(String id) => '/job/$id';

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  bool _loading = true;
  bool _applying = false;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final applications = context.read<ApplicationsProvider>();
      final jobsProvider = context.read<JobsProvider>();
      final uid = auth.snapshot.profile?.uid;
      if (uid != null && uid.isNotEmpty) {
        await applications.loadMine(uid);
      }
      final job = await jobsProvider.fetch(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _loading = false;
      });
    });
  }

  Future<void> _apply() async {
    final auth = context.read<AuthProvider>();
    final me = auth.snapshot.profile;
    if (me == null) return;

    final storyService = context.read<StoryService>();
    final stories = await storyService.fetchApprovedStoriesOf(me.uid);
    if (!mounted) return;

    if (stories.isEmpty) {
      await _promptCreateStory();
      return;
    }

    setState(() => _applying = true);
    try {
      await context.read<ApplicationsProvider>().submit(
            jobId: widget.jobId,
            seekerUid: me.uid,
            seekerName: me.displayName,
            seekerHeadline: me.headline,
            seekerAvatar: me.avatarUrl ?? '',
            seekerEmail: me.email,
            storyId: stories.first.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAr ? AppStrings.appliedSnackAr : AppStrings.appliedSnack)),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _promptCreateStory() async {
    final goStudio = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isAr ? AppStrings.needStoryTitleAr : AppStrings.needStoryTitle),
        content: Text(_isAr ? AppStrings.needStoryBodyAr : AppStrings.needStoryBodyEn),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_isAr ? AppStrings.goToStudioAr : AppStrings.goToStudio),
          ),
        ],
      ),
    );
    if (goStudio == true && mounted) {
      context.push(StoryStudioScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applications = context.watch<ApplicationsProvider>();
    final hasApplied = applications.hasApplied(widget.jobId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_job?.title ?? (_isAr ? AppStrings.jobsAr : AppStrings.jobs)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _job == null
                ? Center(
                    child: Text(
                      _isAr ? AppStrings.genericErrorAr : AppStrings.genericError,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _JobHeader(job: _job!, isAr: _isAr),
                            const SizedBox(height: 16),
                            if (_job!.description.isNotEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Text(
                                    _job!.description,
                                    style: const TextStyle(fontSize: 15, height: 1.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: hasApplied
                              ? _AppliedBar(isAr: _isAr)
                              : FilledButton(
                                  onPressed: _applying ? null : _apply,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _applying
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(_isAr ? AppStrings.applyWithStoryAr : AppStrings.applyWithStory),
                                ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.job, required this.isAr});

  final Job job;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business_rounded, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(job.company, style: const TextStyle(fontSize: 14)),
                if (job.location.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  const Icon(Icons.place_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(job.location, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppliedBar extends StatelessWidget {
  const _AppliedBar({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            isAr ? AppStrings.appliedAr : AppStrings.applied,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}