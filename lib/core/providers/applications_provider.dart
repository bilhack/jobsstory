import 'package:flutter/foundation.dart';

import '../models/job_application.dart';
import '../services/application_repository.dart';

/// Tracks the signed-in user's applications and the applicant lists the
/// recruiter is reviewing, and forwards status/note actions upstream.
class ApplicationsProvider extends ChangeNotifier {
  ApplicationsProvider({required ApplicationRepository repository}) : _repository = repository;

  final ApplicationRepository _repository;

  List<JobApplication> _mine = const [];
  Map<String, List<JobApplication>> _applicantsByJob = const {};
  Set<String> _appliedJobIds = const {};
  bool _loading = false;
  Object? _error;

  List<JobApplication> get mine => _mine;
  Map<String, List<JobApplication>> get applicantsByJob => _applicantsByJob;
  bool get loading => _loading;
  Object? get error => _error;

  List<JobApplication> applicantsFor(String jobId) => _applicantsByJob[jobId] ?? const [];

  bool hasApplied(String jobId) => _appliedJobIds.contains(jobId);

  Future<void> loadMine(String seekerUid) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _mine = await _repository.applicationsBySeeker(seekerUid);
      _appliedJobIds = _mine.map((a) => a.jobId).toSet();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadApplicants(String jobId) async {
    try {
      _applicantsByJob = {
        ..._applicantsByJob,
        jobId: await _repository.applicationsForJob(jobId),
      };
      _error = null;
    } catch (e) {
      _error = e;
    }
    notifyListeners();
  }

  Future<void> submit({
    required String jobId,
    required String seekerUid,
    String seekerName = '',
    String seekerHeadline = '',
    String seekerAvatar = '',
    String seekerEmail = '',
    String? storyId,
  }) async {
    final application = JobApplication(
      id: '${jobId}_$seekerUid',
      jobId: jobId,
      seekerUid: seekerUid,
      seekerName: seekerName,
      seekerHeadline: seekerHeadline,
      seekerAvatar: seekerAvatar,
      seekerEmail: seekerEmail,
      storyId: storyId,
    );
    await _repository.submit(application: application);
    _mine = [application, ..._mine];
    _appliedJobIds = {jobId, ..._appliedJobIds};
    final existing = _applicantsByJob[jobId] ?? const [];
    _applicantsByJob = {..._applicantsByJob, jobId: [application, ...existing]};
    _error = null;
    notifyListeners();
  }

  Future<void> setStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    await _repository.setStatus(applicationId, status);
    _apply((a) => a.id == applicationId ? a.copyWith(status: status) : a);
  }

  Future<void> setNote({
    required String applicationId,
    required String note,
  }) async {
    await _repository.setNote(applicationId, note);
    _apply((a) => a.id == applicationId ? a.copyWith(recruiterNote: note.trim()) : a);
  }

  void _apply(JobApplication Function(JobApplication) f) {
    _mine = _mine.map(f).toList();
    _applicantsByJob = {
      for (final entry in _applicantsByJob.entries) entry.key: entry.value.map(f).toList()
    };
    notifyListeners();
  }
}