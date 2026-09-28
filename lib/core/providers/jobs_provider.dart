import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../services/job_repository.dart';

/// Holds open jobs (for seeker browsing) and the recruiter's own postings.
class JobsProvider extends ChangeNotifier {
  JobsProvider({required JobRepository repository}) : _repository = repository;

  final JobRepository _repository;

  List<Job> _openJobs = const [];
  List<Job> _myJobs = const [];
  bool _loading = false;
  Object? _error;

  List<Job> get openJobs => _openJobs;
  List<Job> get myJobs => _myJobs;
  bool get loading => _loading;
  Object? get error => _error;

  Future<void> loadOpen() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _openJobs = await _repository.listOpen();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMine(String recruiterUid) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _myJobs = await _repository.listMine(recruiterUid);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Job?> fetch(String id) => _repository.get(id);

  Future<Job> create({
    required String title,
    required String company,
    String location = '',
    String description = '',
    required String createdBy,
  }) async {
    final job = Job(
      id: '${createdBy}_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      company: company.trim(),
      location: location.trim(),
      description: description.trim(),
      createdBy: createdBy,
    );
    await _repository.create(job: job);
    _myJobs = [job, ..._myJobs];
    notifyListeners();
    return job;
  }

  Future<void> setStatus(Job job, JobStatus status) async {
    await _repository.setStatus(job.id, status);
    _myJobs = _myJobs.map((j) => j.id == job.id ? j.copyWith(status: status) : j).toList();
    _openJobs = _openJobs
        .map((j) => j.id == job.id ? j.copyWith(status: status) : j)
        .where((j) => j.status == JobStatus.open)
        .toList();
    notifyListeners();
  }
}