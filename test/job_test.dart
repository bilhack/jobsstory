import 'package:flutter_test/flutter_test.dart';
import 'package:jobsstory/core/models/job.dart';
import 'package:jobsstory/core/models/job_application.dart';
import 'package:jobsstory/core/providers/applications_provider.dart';
import 'package:jobsstory/core/providers/jobs_provider.dart';

import 'fakes.dart';

void main() {
  group('Job model', () {
    test('toDoc/fromDoc round-trips all fields', () {
      final original = Job(
        id: 'r_99',
        title: 'مهندس فلاتر',
        company: 'شركة النور',
        location: 'دبي',
        description: 'مطلوب مهندس واجهات.',
        createdBy: 'r1',
        status: JobStatus.open,
        createdAt: DateTime.utc(2026, 9, 24),
      );

      final restored = Job.fromDoc(original.id, original.toDoc());

      expect(restored.title, original.title);
      expect(restored.company, original.company);
      expect(restored.location, original.location);
      expect(restored.description, original.description);
      expect(restored.createdBy, original.createdBy);
      expect(restored.status, JobStatus.open);
      expect(restored.createdAt, original.createdAt);
    });

    test('unknown status string falls back to open', () {
      final job = Job.fromDoc('x', {'createdBy': 'r', 'status': 'bogus'});
      expect(job.status, JobStatus.open);
    });
  });

  group('JobApplication model', () {
    test('toDoc/fromDoc round-trips all fields', () {
      final original = JobApplication(
        id: 'j1_s1',
        jobId: 'j1',
        seekerUid: 's1',
        seekerName: 'ليلى',
        seekerHeadline: 'مصممة واجهات',
        seekerAvatar: 'https://cdn/a.jpg',
        seekerEmail: 'laila@test.dev',
        storyId: 'st1',
        status: ApplicationStatus.contacted,
        recruiterNote: 'ممتازة',
        appliedAt: DateTime.utc(2026, 9, 24),
      );

      final restored = JobApplication.fromDoc(original.id, original.toDoc());

      expect(restored.jobId, original.jobId);
      expect(restored.seekerUid, original.seekerUid);
      expect(restored.seekerName, original.seekerName);
      expect(restored.seekerEmail, original.seekerEmail);
      expect(restored.storyId, original.storyId);
      expect(restored.status, ApplicationStatus.contacted);
      expect(restored.recruiterNote, original.recruiterNote);
      expect(restored.appliedAt, original.appliedAt);
    });

    test('unknown status string falls back to pending', () {
      final app = JobApplication.fromDoc('x', {'jobId': 'j', 'seekerUid': 's', 'status': 'bogus'});
      expect(app.status, ApplicationStatus.pending);
    });
  });

  group('JobsProvider', () {
    test('loadOpen returns only open jobs', () async {
      final repo = FakeJobRepository()
        ..seed([
          Job(id: 'j1', title: 'مفتوحة', company: 'أ', createdBy: 'r1'),
          Job(id: 'j2', title: 'مغلقة', company: 'ب', createdBy: 'r1', status: JobStatus.closed),
        ]);
      final provider = JobsProvider(repository: repo);

      await provider.loadOpen();

      expect(provider.openJobs.map((j) => j.id), ['j1']);
    });

    test('create posts a job into the recruiter list', () async {
      final repo = FakeJobRepository();
      final provider = JobsProvider(repository: repo);

      final job = await provider.create(
        title: 'محلل بيانات',
        company: 'شركة الشمس',
        createdBy: 'r1',
      );

      await provider.loadMine('r1');
      expect(provider.myJobs.single.id, job.id);
      expect(provider.myJobs.single.status, JobStatus.open);
    });

    test('setStatus closes the job and drops it from open', () async {
      final repo = FakeJobRepository()
        ..seed([Job(id: 'j1', title: 'وظيفة', company: 'أ', createdBy: 'r1')]);
      final provider = JobsProvider(repository: repo);
      await provider.loadOpen();
      await provider.loadMine('r1');

      await provider.setStatus(provider.myJobs.single, JobStatus.closed);

      expect(provider.myJobs.single.status, JobStatus.closed);
      expect(provider.openJobs, isEmpty);
    });
  });

  group('ApplicationsProvider', () {
    test('loadMine tracks applied job ids', () async {
      final repo = FakeApplicationRepository()
        ..seed([
          JobApplication(id: 'j1_s1', jobId: 'j1', seekerUid: 's1'),
        ]);
      final provider = ApplicationsProvider(repository: repo);

      await provider.loadMine('s1');

      expect(provider.mine, hasLength(1));
      expect(provider.hasApplied('j1'), isTrue);
    });

    test('submit adds an application and marks the job applied', () async {
      final repo = FakeApplicationRepository();
      final provider = ApplicationsProvider(repository: repo);

      await provider.submit(
        jobId: 'j1',
        seekerUid: 's1',
        seekerName: 'ليلى',
        storyId: 'st1',
      );

      expect(repo.all.single.storyId, 'st1');
      expect(provider.hasApplied('j1'), isTrue);
    });

    test('loadApplicants groups applicants per job', () async {
      final repo = FakeApplicationRepository()
        ..seed([
          JobApplication(id: 'j1_s1', jobId: 'j1', seekerUid: 's1', seekerName: 'سارة'),
          JobApplication(id: 'j1_s2', jobId: 'j1', seekerUid: 's2', seekerName: 'سمر'),
        ]);
      final provider = ApplicationsProvider(repository: repo);

      await provider.loadApplicants('j1');

      expect(provider.applicantsFor('j1'), hasLength(2));
    });

    test('setStatus updates both mine and the applicants list', () async {
      final repo = FakeApplicationRepository()
        ..seed([JobApplication(id: 'j1_s1', jobId: 'j1', seekerUid: 's1')]);
      final provider = ApplicationsProvider(repository: repo);
      await provider.loadMine('s1');
      await provider.loadApplicants('j1');

      await provider.setStatus(applicationId: 'j1_s1', status: ApplicationStatus.contacted);

      expect(repo.all.single.status, ApplicationStatus.contacted);
      expect(provider.mine.single.status, ApplicationStatus.contacted);
      expect(provider.applicantsFor('j1').single.status, ApplicationStatus.contacted);
    });

    test('setNote persists a private note', () async {
      final repo = FakeApplicationRepository()
        ..seed([JobApplication(id: 'j1_s1', jobId: 'j1', seekerUid: 's1')]);
      final provider = ApplicationsProvider(repository: repo);
      await provider.loadApplicants('j1');

      await provider.setNote(applicationId: 'j1_s1', note: 'ممتازة');

      expect(repo.all.single.recruiterNote, 'ممتازة');
      expect(provider.applicantsFor('j1').single.recruiterNote, 'ممتازة');
    });
  });
}