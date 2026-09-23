import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jobsstory/core/media/media_picker.dart';
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
}