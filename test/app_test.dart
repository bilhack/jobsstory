import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jobsstory/main.dart';

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
}