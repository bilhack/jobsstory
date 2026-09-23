import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_strings.dart';
import 'core/firebase/bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  await AppBootstrap.initialize();
  runApp(const JobsStoryApp());
}

/// Root widget — Arabic-first, full RTL support, vibrant dark theme.
class JobsStoryApp extends StatelessWidget {
  const JobsStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: AppRouter.createRouter(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        // Arabic-first: default to Arabic even for non-AR devices.
        return const Locale('ar');
      },
    );
  }
}