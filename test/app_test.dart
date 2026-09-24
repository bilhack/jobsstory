import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jobsstory/core/media/media_picker.dart';
import 'package:jobsstory/core/models/app_user.dart';
import 'package:jobsstory/core/models/job.dart';
import 'package:jobsstory/core/models/job_application.dart';
import 'package:jobsstory/core/models/story.dart';
import 'package:jobsstory/main.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

/// Helper: navigate the running app's router to [route].
Future<void> go(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator));
  GoRouter.of(ctx).go(route);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Guest sees welcome with slogan and CTA', (tester) async {
    await tester.pumpWidget(JobsStoryApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();

    expect(find.text('جوبز ستوري'), findsOneWidget);
    expect(find.text('لا ترسل سيرة ذاتية... احكِ قصتك.'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });

  testWidgets('Get Started leads a guest to role selection', (tester) async {
    await tester.pumpWidget(JobsStoryApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();

    expect(find.text('باحث عن عمل'), findsOneWidget);
    expect(find.text('مسؤول توظيف'), findsOneWidget);
  });

  testWidgets('Signed-in user without role is redirected to onboarding', (tester) async {
    await tester.pumpWidget(JobsStoryApp(authService: FakeAuthService(FakeStatus.signedInNoProfile)));
    await tester.pumpAndSettle();

    await go(tester, '/home');

    expect(find.text('من أنت؟'), findsOneWidget);
    expect(find.textContaining('أهلاً'), findsNothing);
  });

  testWidgets('Guests hitting /home are guarded to login', (tester) async {
    await tester.pumpWidget(JobsStoryApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();

    await go(tester, '/home');

    expect(find.text('مرحباً بعودتك'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsWidgets);
  });

  testWidgets('Signed-in seeker with role reaches home', (tester) async {
    await tester.pumpWidget(JobsStoryApp(authService: FakeAuthService(FakeStatus.signedInSeeker)));
    await tester.pumpAndSettle();

    await go(tester, '/home');

    expect(find.textContaining('أهلاً'), findsOneWidget);
  });

  testWidgets('Registering from onboarding lands on home', (tester) async {
    final service = FakeAuthService();
    await tester.pumpWidget(JobsStoryApp(authService: service));
    await tester.pumpAndSettle();

    // Reach role selection first, then tap "Job Seeker" (guest → register?role=seeker).
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('باحث عن عمل'));
    await tester.pumpAndSettle();

    // Fill the registration form.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'سارة');
    await tester.enterText(fields.at(1), 'sara@test.dev');
    await tester.enterText(fields.at(2), 'password123');
    await tester.tap(find.text('إنشاء حساب'));
    await tester.pumpAndSettle();

    // Signed up + has role → home.
    expect(find.textContaining('أهلاً'), findsOneWidget);
  });

  testWidgets('Sign out returns to welcome', (tester) async {
    await tester.pumpWidget(JobsStoryApp(authService: FakeAuthService(FakeStatus.signedInSeeker)));
    await tester.pumpAndSettle();

    await go(tester, '/home');
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    // Guests are guarded to the login screen after signing out.
    expect(find.text('مرحباً بعودتك'), findsOneWidget);
  });

  testWidgets('Seeker home shows story actions', (tester) async {
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInSeeker),
      storyService: FakeStoryService(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/home');

    expect(find.text('إنشاء قصة'), findsOneWidget);
    await tester.dragUntilVisible(find.text('قصصي'), find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(find.text('قصصي'), findsOneWidget);
  });

  testWidgets('Recruiters are guarded away from the studio', (tester) async {
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInRecruiter),
      storyService: FakeStoryService(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/studio');

    // Back on home (recruiter has no studio cards).
    expect(find.text('إنشاء قصة'), findsNothing);
    expect(find.textContaining('أهلاً'), findsOneWidget);
  });

  testWidgets('Full studio flow: gallery → publish → appears in my stories', (tester) async {
    final storyService = FakeStoryService();
    await tester.pumpWidget(
      Provider<MediaPicker>.value(
        value: FakeMediaPicker(),
        child: JobsStoryApp(
          authService: FakeAuthService(FakeStatus.signedInSeeker),
          storyService: storyService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await go(tester, '/studio');

    // No camera in tests: the gallery CTA is shown directly.
    await tester.tap(find.text('اختر من المعرض'));
    await tester.pumpAndSettle();

    // Caption + publish.
    await tester.enterText(find.byType(TextField), 'قصتي الأولى');
    await tester.ensureVisible(find.text('نشر القصة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نشر القصة'));
    await tester.pumpAndSettle();

    expect(storyService.publishCount, 1);
    // Landed on "my stories" which lists the freshly published caption.
    expect(find.text('قصتي', skipOffstage: false), findsNothing);
    expect(find.text('قصتي الأولى'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
  });

  testWidgets('My stories shows seeded list and delete empties it', (tester) async {
    final storyService = FakeStoryService();
    storyService.seed([
      const Story(id: 'a', ownerUid: 'u1', caption: 'قصتي المنشورة', status: StoryStatus.approved, thumbnailUrl: ''),
    ]);
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInSeeker),
      storyService: storyService,
    ));
    await tester.pumpAndSettle();

    await go(tester, '/my-stories');

    expect(find.text('قصتي المنشورة'), findsOneWidget);
    expect(find.text('منشورة'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد قصص بعد'), findsOneWidget);
  });

  testWidgets('Recruiter home shows feed and candidates cards', (tester) async {
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInRecruiter),
      storyService: FakeStoryService(),
      interactionService: FakeStoryInteractionService(),
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/home');

    expect(find.text('استكشف'), findsOneWidget);
    expect(find.text('المرشحون'), findsOneWidget);
    expect(find.text('إنشاء قصة'), findsNothing);
  });

  testWidgets('Feed shows approved stories; like toggles; swiping shows next story', (tester) async {
    final storyService = FakeStoryService();
    storyService.seed([
      const Story(
        id: 's1',
        ownerUid: 'seeker_a',
        caption: 'أول قصتي',
        status: StoryStatus.approved,
        videoUrl: 'https://cdn/1.mp4',
      ),
      const Story(
        id: 's2',
        ownerUid: 'seeker_b',
        caption: 'قصة ثانية',
        status: StoryStatus.approved,
        videoUrl: 'https://cdn/2.mp4',
      ),
    ]);
    final users = FakeUserRepository()
      ..seed([
        AppUser(uid: 'seeker_a', email: 'a@test.dev', displayName: 'ليلى', headline: 'مصممة واجهات', role: UserRole.seeker),
        AppUser(uid: 'seeker_b', email: 'b@test.dev', displayName: 'سمر', headline: 'مطوّرة', role: UserRole.seeker),
      ]);
    final interactions = FakeStoryInteractionService();

    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInRecruiter),
      storyService: storyService,
      interactionService: interactions,
      userRepository: users,
      feedVideoTile: FakeFeedVideoTile(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/explore');

    // First story visible with its seeker info.
    expect(find.text('أول قصتي'), findsOneWidget);
    expect(find.text('ليلى'), findsOneWidget);
    expect(find.text('مصممة واجهات'), findsOneWidget);

    // Like toggles and persists to the service.
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(interactions.liked, contains('s1_u1'));

    // Swipe up to the second story.
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('قصة ثانية'), findsOneWidget);
    expect(find.text('سمر'), findsOneWidget);
  });

  testWidgets('Reporting a story records the report', (tester) async {
    final storyService = FakeStoryService()
      ..seed(const [
        Story(id: 's1', ownerUid: 'seeker_a', caption: 'قصتي', status: StoryStatus.approved, videoUrl: 'https://cdn/1.mp4'),
      ]);
    final interactions = FakeStoryInteractionService();

    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInRecruiter),
      storyService: storyService,
      interactionService: interactions,
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/explore');

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محتوى غير لائق'));
    await tester.pumpAndSettle();

    expect(interactions.reportCount, 1);
    expect(find.text('شكراً لك، تم استلام البلاغ.'), findsOneWidget);
  });

  testWidgets('Recruiter opens a seeker profile, saves them, and finds them in candidates', (tester) async {
    final storyService = FakeStoryService()
      ..seed(const [
        Story(id: 's1', ownerUid: 'seeker_a', caption: 'قصتي', status: StoryStatus.approved, videoUrl: 'https://cdn/1.mp4'),
      ]);
    final users = FakeUserRepository()
      ..seed([
        AppUser(
          uid: 'seeker_a',
          email: 'laila@test.dev',
          displayName: 'ليلى',
          headline: 'مصممة واجهات',
          bio: 'أصنع تجارب رقمية جميلة.',
          location: 'القاهرة',
          skills: const ['Flutter', 'UI'],
          languages: const ['العربية', 'English'],
          role: UserRole.seeker,
        ),
      ]);
    final interactions = FakeStoryInteractionService();

    // Tall portrait surface so the 9:16 hero + full CV stay visible.
    await tester.binding.setSurfaceSize(const Size(600, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInRecruiter),
      storyService: storyService,
      interactionService: interactions,
      userRepository: users,
      feedVideoTile: FakeFeedVideoTile(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/explore');
    await tester.tap(find.text('عرض الملف'));
    await tester.pumpAndSettle();

    // Simplified CV page is rendered.
    expect(find.text('ليلى'), findsOneWidget);
    expect(find.text('مصممة واجهات'), findsOneWidget);
    expect(find.text('المهارات'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('تواصل'), findsOneWidget);

    // Save the candidate.
    await tester.ensureVisible(find.text('حفظ المرشح'));
    await tester.tap(find.text('حفظ المرشح'));
    await tester.pumpAndSettle();
    expect(interactions.saved, contains('u1_seeker_a'));

    // The candidates list shows her.
    await go(tester, '/candidates');
    expect(find.text('ليلى'), findsOneWidget);
    expect(find.text('مصممة واجهات'), findsOneWidget);

    // Removing the save empties the list.
    await tester.tap(find.byIcon(Icons.bookmark_remove_outlined));
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد مرشحون محفوظون بعد'), findsOneWidget);
  });

  testWidgets('Seekers are guarded away from the candidates list', (tester) async {
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInSeeker),
      storyService: FakeStoryService(),
      interactionService: FakeStoryInteractionService(),
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/candidates');

    // Redirected back home.
    expect(find.textContaining('أهلاً'), findsOneWidget);
    expect(find.text('المرشحون'), findsNothing);
  });

  testWidgets('Seeker browses open jobs and opens the detail', (tester) async {
    final jobs = FakeJobRepository()
      ..seed([
        Job(id: 'j1', title: 'مطور فلاتر', company: 'شركة النور', location: 'دبي', description: 'نبحث عن مهندس واجهات متحمس.', createdBy: 'r1'),
      ]);
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInSeeker),
      storyService: FakeStoryService(),
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
      jobRepository: jobs,
      applicationRepository: FakeApplicationRepository(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/jobs');

    expect(find.text('مطور فلاتر'), findsOneWidget);
    expect(find.text('شركة النور • دبي'), findsOneWidget);

    await tester.tap(find.text('مطور فلاتر'));
    await tester.pumpAndSettle();

    expect(find.text('نبحث عن مهندس واجهات متحمس.'), findsOneWidget);
    expect(find.text('قدّم بقصتك'), findsOneWidget);
  });

  testWidgets('Seeker applies with their approved story and tracks it', (tester) async {
    final storyService = FakeStoryService()
      ..seed(const [
        Story(id: 's1', ownerUid: 'u1', caption: 'قصتي', status: StoryStatus.approved),
      ]);
    final applications = FakeApplicationRepository();
    final jobs = FakeJobRepository()
      ..seed([
        Job(id: 'j1', title: 'مطور فلاتر', company: 'شركة النور', createdBy: 'r1'),
      ]);
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInSeeker),
      storyService: storyService,
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
      jobRepository: jobs,
      applicationRepository: applications,
    ));
    await tester.pumpAndSettle();

    await go(tester, '/jobs');
    await tester.tap(find.text('مطور فلاتر'));
    await tester.pumpAndSettle();

    // One-tap apply attaches the approved story.
    await tester.tap(find.text('قدّم بقصتك'));
    await tester.pumpAndSettle();

    expect(applications.all.single.jobId, 'j1');
    expect(applications.all.single.storyId, 's1');
    expect(find.text('تم التقديم'), findsOneWidget);

    // The seeker can track the application status.
    await go(tester, '/my-applications');
    expect(find.text('مطور فلاتر'), findsOneWidget);
    expect(find.text('جديد'), findsOneWidget);
  });

  testWidgets('Seeker without an approved story is prompted to create one', (tester) async {
    final jobs = FakeJobRepository()
      ..seed([
        Job(id: 'j1', title: 'مطور فلاتر', company: 'شركة النور', createdBy: 'r1'),
      ]);
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInSeeker),
      storyService: FakeStoryService(),
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
      jobRepository: jobs,
      applicationRepository: FakeApplicationRepository(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/jobs');
    await tester.tap(find.text('مطور فلاتر'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('قدّم بقصتك'));
    await tester.pumpAndSettle();

    expect(find.text('أنشئ قصتك أولاً'), findsOneWidget);
  });

  testWidgets('Recruiter posts a job and sees it in my jobs', (tester) async {
    final jobs = FakeJobRepository();
    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInRecruiter),
      storyService: FakeStoryService(),
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
      jobRepository: jobs,
      applicationRepository: FakeApplicationRepository(),
    ));
    await tester.pumpAndSettle();

    await go(tester, '/my-jobs');
    expect(find.text('نشر وظيفة'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'نشر وظيفة').first);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'مهندس جودة');
    await tester.enterText(fields.at(1), 'شركة الشمس');
    await tester.enterText(fields.at(2), 'الرياض');
    await tester.enterText(fields.at(3), 'خبرة ثلاث سنوات');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'نشر وظيفة'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'نشر وظيفة'));
    await tester.pumpAndSettle();

    expect(jobs.all.single.title, 'مهندس جودة');
    expect(find.text('مهندس جودة'), findsOneWidget);
    expect(find.text('مفتوحة'), findsOneWidget);
  });

  testWidgets('Recruiter reviews applicants: status, note and contact', (tester) async {
    final jobs = FakeJobRepository()
      ..seed([
        Job(id: 'j1', title: 'مطور فلاتر', company: 'شركة النور', createdBy: 'u1'),
      ]);
    final applications = FakeApplicationRepository()
      ..seed([
        JobApplication(
          id: 'j1_sa1',
          jobId: 'j1',
          seekerUid: 'sa1',
          seekerName: 'ليلى',
          seekerHeadline: 'مصممة واجهات',
          seekerEmail: 'laila@test.dev',
        ),
      ]);
    final interactions = FakeStoryInteractionService();

    await tester.pumpWidget(JobsStoryApp(
      authService: FakeAuthService(FakeStatus.signedInRecruiter),
      storyService: FakeStoryService(),
      interactionService: interactions,
      userRepository: FakeUserRepository(),
      feedVideoTile: FakeFeedVideoTile(),
      jobRepository: jobs,
      applicationRepository: applications,
    ));
    await tester.pumpAndSettle();

    await go(tester, '/my-jobs');
    await tester.tap(find.text('مطور فلاتر'));
    await tester.pumpAndSettle();

    // The interested seeker is listed with a pending status.
    expect(find.text('ليلى'), findsOneWidget);
    expect(find.text('جديد'), findsOneWidget);

    // Update to "contacted".
    await tester.tap(find.text('جديد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تم التواصل'));
    await tester.pumpAndSettle();
    expect(applications.all.single.status, ApplicationStatus.contacted);
    expect(find.text('تم التواصل'), findsOneWidget);

    // Add a private note.
    await tester.tap(find.text('ملاحظة خاصة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ممتازة');
    await tester.tap(find.text('حفظ الملاحظة'));
    await tester.pumpAndSettle();
    expect(applications.all.single.recruiterNote, 'ممتازة');
    expect(find.text('ممتازة'), findsOneWidget);

    // One-tap contact: copy the email.
    await tester.tap(find.text('تواصل'));
    await tester.pumpAndSettle();
    expect(find.text('laila@test.dev'), findsOneWidget);
    await tester.tap(find.text('نسخ البريد'));
    await tester.pumpAndSettle();
    expect(find.text('تم نسخ البريد'), findsOneWidget);
  });

  testWidgets('Guard rails: job sections are role-specific', (tester) async {
    final auth = FakeAuthService(FakeStatus.signedInRecruiter);
    await tester.pumpWidget(JobsStoryApp(
      authService: auth,
      storyService: FakeStoryService(),
      jobRepository: FakeJobRepository(),
      applicationRepository: FakeApplicationRepository(),
    ));
    await tester.pumpAndSettle();

    // Recruiters cannot browse seeker jobs.
    await go(tester, '/jobs');
    expect(find.textContaining('أهلاً'), findsOneWidget);
    expect(find.text('وظائف'), findsNothing);

    // Flip the session to a seeker (provider instances are re-used,
    // so switching roles must go through the auth service).
    await auth.setStatus(FakeStatus.signedInSeeker);
    await tester.pumpAndSettle();

    // Seekers cannot reach the recruiter's posting screens.
    await go(tester, '/my-jobs');
    expect(find.textContaining('أهلاً'), findsOneWidget);
    expect(find.text('وظائفي'), findsNothing);

    await go(tester, '/jobs/new');
    expect(find.textContaining('أهلاً'), findsOneWidget);
    expect(find.text('نشر وظيفة'), findsNothing);
  });
}