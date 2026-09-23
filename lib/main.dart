import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_strings.dart';
import 'core/firebase/bootstrap.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/story_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/story_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  await AppBootstrap.initialize();
  runApp(const JobsStoryApp());
}

/// Root widget — Arabic-first, full RTL support, vibrant dark theme.
class JobsStoryApp extends StatelessWidget {
  const JobsStoryApp({super.key, this.authService, this.storyService});

  /// Injectable for tests; production uses the real Firebase services.
  final AuthService? authService;
  final StoryService? storyService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(service: authService ?? FirebaseAuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => StoryProvider(service: storyService ?? FirebaseStoryService()),
        ),
      ],
      child: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  // Created once: the router listens to auth changes via refreshListenable.
  late final GoRouter _router = AppRouter.createRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: _router,
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