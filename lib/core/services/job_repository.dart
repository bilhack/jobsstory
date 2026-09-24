import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job.dart';

/// Job postings: browse open jobs, manage a recruiter's own postings.
abstract class JobRepository {
  Future<Job?> get(String id);
  Future<List<Job>> listOpen();
  Future<List<Job>> listMine(String recruiterUid);
  Future<Job> create({required Job job});
  Future<void> setStatus(String id, JobStatus status);
}

/// Production implementation backed by Cloud Firestore `jobs/{jobId}`.
class FirestoreJobRepository implements JobRepository {
  FirestoreJobRepository([FirebaseFirestore? db]) : _db = db;

  FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  @override
  Future<Job?> get(String id) async {
    final doc = await _firestore.collection('jobs').doc(id).get();
    if (!doc.exists) return null;
    return Job.fromDoc(doc.id, doc.data() ?? const {});
  }

  @override
  Future<List<Job>> listOpen() async {
    final query = await _firestore
        .collection('jobs')
        .where('status', isEqualTo: JobStatus.open.value)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => Job.fromDoc(doc.id, doc.data())).toList();
  }

  @override
  Future<List<Job>> listMine(String recruiterUid) async {
    final query = await _firestore
        .collection('jobs')
        .where('createdBy', isEqualTo: recruiterUid)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => Job.fromDoc(doc.id, doc.data())).toList();
  }

  @override
  Future<Job> create({required Job job}) async {
    await _firestore.collection('jobs').doc(job.id).set(job.toDoc());
    return job;
  }

  @override
  Future<void> setStatus(String id, JobStatus status) async {
    await _firestore.collection('jobs').doc(id).update({'status': status.value});
  }
}