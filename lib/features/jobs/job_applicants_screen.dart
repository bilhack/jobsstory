import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_strings.dart';
import '../../core/models/job.dart';
import '../../core/models/job_application.dart';
import '../../core/providers/applications_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/providers/story_interaction_provider.dart';
import '../../core/theme/app_theme.dart';
import '../profile/seeker_profile_screen.dart';

/// Recruiter-only "who is interested in this job" screen with status
/// tracking, private notes and one-tap contact (copy / email app).
class JobApplicantsScreen extends StatefulWidget {
  const JobApplicantsScreen({super.key, required this.jobId});

  final String jobId;

  static String route(String jobId) => '/job/$jobId/applicants';

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  Job? _job;
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final applications = context.read<ApplicationsProvider>();
      final jobsProvider = context.read<JobsProvider>();
      await applications.loadApplicants(widget.jobId);
      final job = await jobsProvider.fetch(widget.jobId);
      if (!mounted) return;
      setState(() => _job = job);
    });
  }

  Future<void> _contact(JobApplication app) async {
    final email = app.seekerEmail;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAr ? 'لا يتوفر بريد لهذا المرشح' : 'This candidate has no email on file')),
      );
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app.seekerName.isEmpty ? app.seekerUid : app.seekerName),
        content: Text(email),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: email));
              Navigator.of(context).pop('copied');
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(_isAr ? AppStrings.copyEmailAr : AppStrings.copyEmail),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop('mail'),
            icon: const Icon(Icons.mail_outline_rounded, size: 18),
            label: Text(_isAr ? AppStrings.openMailAppAr : AppStrings.openMailApp),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'copied') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAr ? AppStrings.emailCopiedAr : AppStrings.emailCopied)),
      );
    } else if (action == 'mail') {
      try {
        final uri = Uri(scheme: 'mailto', path: email);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && mounted) {
          await Clipboard.setData(ClipboardData(text: email));
        }
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: email));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isAr ? AppStrings.emailCopiedAr : AppStrings.emailCopied)),
          );
        }
      }
    }
  }

  Future<void> _editNote(JobApplication app) async {
    final controller = TextEditingController(text: app.recruiterNote);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isAr ? AppStrings.privateNoteAr : AppStrings.privateNote),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: _isAr ? AppStrings.addNoteAr : AppStrings.addNote,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(_isAr ? AppStrings.saveNoteAr : AppStrings.saveNote),
          ),
        ],
      ),
    );
    if (saved != null && mounted) {
      await context.read<ApplicationsProvider>().setNote(applicationId: app.id, note: saved);
    }
  }

  Future<void> _setStatus(JobApplication app, ApplicationStatus status) async {
    await context.read<ApplicationsProvider>().setStatus(applicationId: app.id, status: status);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final applicants = provider.applicantsFor(widget.jobId);
    final me = context.watch<AuthProvider>().snapshot.profile?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isAr ? AppStrings.applicantsToJobAr : AppStrings.applicantsToJob),
            if (_job != null)
              Text(
                _job!.title,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: applicants.isEmpty
            ? _EmptyApplicants(isAr: _isAr)
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: applicants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = applicants[index];
                  return _ApplicantCard(
                    app: app,
                    isAr: _isAr,
                    onOpen: () => context.push(SeekerProfileScreen.route(app.seekerUid)),
                    onSave: () {
                      final saved = context.read<StoryInteractionProvider>().isSaved(app.seekerUid);
                      context
                          .read<StoryInteractionProvider>()
                          .toggleSaveSeeker(seekerId: app.seekerUid, savedById: me);
                      if (!saved && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_isAr ? AppStrings.savedAr : AppStrings.saved)),
                        );
                      }
                    },
                    onContact: () => _contact(app),
                    onNote: () => _editNote(app),
                    onStatus: (status) => _setStatus(app, status),
                  );
                },
              ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.app,
    required this.isAr,
    required this.onOpen,
    required this.onSave,
    required this.onContact,
    required this.onNote,
    required this.onStatus,
  });

  final JobApplication app;
  final bool isAr;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onContact;
  final VoidCallback onNote;
  final ValueChanged<ApplicationStatus> onStatus;

  String get _statusLabel {
    final label = switch (app.status) {
      ApplicationStatus.pending => isAr ? AppStrings.statusPendingAr : AppStrings.statusPending,
      ApplicationStatus.contacted => isAr ? AppStrings.statusContactedAr : AppStrings.statusContacted,
      ApplicationStatus.rejected => isAr ? AppStrings.statusRejectedAr : AppStrings.statusRejected,
    };
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final interaction = context.watch<StoryInteractionProvider>();
    final isSaved = interaction.isSaved(app.seekerUid);

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: app.seekerName.isEmpty
                        ? const Icon(Icons.person_rounded, color: Colors.white)
                        : Text(
                            app.seekerName.characters.first,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.seekerName.isEmpty ? app.seekerUid : app.seekerName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        if (app.seekerHeadline.isNotEmpty)
                          Text(
                            app.seekerHeadline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<ApplicationStatus>(
                    tooltip: isAr ? AppStrings.updateStatusAr : AppStrings.updateStatus,
                    initialValue: app.status,
                    onSelected: onStatus,
                    itemBuilder: (context) => [
                      for (final status in ApplicationStatus.values)
                        PopupMenuItem(
                          value: status,
                          child: Text(switch (status) {
                            ApplicationStatus.pending =>
                              isAr ? AppStrings.statusPendingAr : AppStrings.statusPending,
                            ApplicationStatus.contacted =>
                              isAr ? AppStrings.statusContactedAr : AppStrings.statusContacted,
                            ApplicationStatus.rejected =>
                              isAr ? AppStrings.statusRejectedAr : AppStrings.statusRejected,
                          }),
                        ),
                    ],
                    child: _StatusChip(label: _statusLabel, status: app.status),
                  ),
                ],
              ),
              if (app.recruiterNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppColors.textMuted),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.bookmark_add_outlined,
                    label: isAr ? AppStrings.saveCandidateShortAr : AppStrings.saveCandidateShort,
                    active: isSaved,
                    onTap: onSave,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.mail_outline_rounded,
                    label: isAr ? AppStrings.contactAr : AppStrings.contact,
                    onTap: onContact,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.sticky_note_2_outlined,
                    label: isAr ? AppStrings.privateNoteAr : AppStrings.privateNote,
                    onTap: onNote,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ApplicationStatus.pending => AppColors.accent,
      ApplicationStatus.contacted => AppColors.primary,
      ApplicationStatus.rejected => Colors.redAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          foregroundColor: active ? AppColors.primary : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.primary : null),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EmptyApplicants extends StatelessWidget {
  const _EmptyApplicants({required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              isAr ? AppStrings.noApplicantsAr : AppStrings.noApplicants,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? AppStrings.noApplicantsHintAr : AppStrings.noApplicantsHint,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}