import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsstory/core/router/app_router.dart';
import 'package:jobsstory/core/theme/app_theme.dart';

import 'package:jobsstory/main.dart';

void main() {
  Widget buildApp() {
    return MaterialApp.router(
      routerConfig: AppRouter.createRouter(),
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  testWidgets('Welcome screen shows slogan and CTA', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('JobsStory'), findsOneWidget);
    expect(find.text("Don't send a CV. Tell your story."), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Get Started navigates to role selection', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Job Seeker'), findsOneWidget);
    expect(find.text('Recruiter'), findsOneWidget);
  });

  testWidgets('JobsStoryApp boots with Arabic locale', (tester) async {
    await tester.pumpWidget(const JobsStoryApp());
    await tester.pumpAndSettle();

    expect(find.text('جوبز ستوري'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });
}