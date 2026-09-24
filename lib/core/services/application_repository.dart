import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job_application.dart';

/// Job applications: seekers submit one-tap (attaching their story),
/// recruiters review applicants, track status and take private notes.
abstract class ApplicationRepository {
  Future<JobApplication?> applicationFor({
    required String jobId,
    required String seekerUid,
  });
  Future<List<JobApplication>> applicationsForJob(String jobId);
  Future<List<JobApplication>> applicationsBySeeker(String seekerUid);
  Future<void> submit({required JobApplication application});
  Future<void> setStatus(String id, ApplicationStatus status);
  Future<void> setNote(String id, String note);
}

/// Production implementation backed by Cloud Firestore
/// `applications/{jobId_seekerUid}`.
class FirestoreApplicationRepository implements ApplicationRepository {
  FirestoreApplicationRepository([FirebaseFirestore? db]) : _db = db;

  FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  @override
  Future<JobApplication?> applicationFor({
    required String jobId,
    required String seekerUid,
  }) async {
    final userId = _id(jobId, seekerUid);
    final doc = await _firestore.collection('applications').doc(userId).get();
    if (!doc.exists) return null;
    return JobApplication.fromDoc(doc.id, doc.data() ?? const {});
  }

  @override
  Future<List<JobApplication>> applicationsForJob(String jobId) async {
    final query = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .get();
    return query.docs.map((doc) => JobApplication.fromDoc(doc.id, doc.data())).toList();
  }

  @override
  Future<List<JobApplication>> applicationsBySeeker(String seekerUid) async {
    final query = await _firestore
        .collection('applications')
        .where('seekerUid', isEqualTo: seekerUid)
        .orderBy('appliedAt', descending: true)
        .get();
    return query.docs.map((doc) => JobApplication.fromDoc(doc.id, doc.data())).toList();
  }

  @override
  Future<void> submit({required JobApplication application}) async {
    await _firestore.collection('applications').doc(application.id).set(application.toDoc());
  }

  @override
  Future<void> setStatus(String id, ApplicationStatus status) async {
    await _firestore.collection('applications').doc(id).update({'status': status.value});
  }

  @override
  Future<void> setNote(String id, String note) async {
    await _firestore.collection('applications').doc(id).update({'recruiterNote': note.trim()});
  }

  String _id(String jobId, String seekerUid) => '${jobId}_$seekerUid';
}