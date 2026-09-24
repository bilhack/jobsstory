import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_strings.dart';
import 'core/firebase/bootstrap.dart';
import 'core/media/feed_video_tile.dart';
import 'core/providers/applications_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/feed_provider.dart';
import 'core/providers/jobs_provider.dart';
import 'core/providers/story_interaction_provider.dart';
import 'core/providers/story_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/application_repository.dart';
import 'core/services/auth_service.dart';
import 'core/services/job_repository.dart';
import 'core/services/notification_service.dart';
import 'core/services/story_interaction_service.dart';
import 'core/services/story_service.dart';
import 'core/services/user_repository.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  await AppBootstrap.initialize();
  runApp(const JobsStoryApp());
}

/// Root widget — Arabic-first, full RTL support, vibrant dark theme.
class JobsStoryApp extends StatelessWidget {
  const JobsStoryApp({
    super.key,
    this.authService,
    this.storyService,
    this.interactionService,
    this.userRepository,
    this.feedVideoTile,
    this.jobRepository,
    this.applicationRepository,
    this.notificationService,
  });

  /// Injectable for tests; production uses the real Firebase services.
  final AuthService? authService;
  final StoryService? storyService;
  final StoryInteractionService? interactionService;
  final UserRepository? userRepository;
  final FeedVideoTile? feedVideoTile;
  final JobRepository? jobRepository;
  final ApplicationRepository? applicationRepository;
  final NotificationService? notificationService;

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
        ChangeNotifierProvider(
          create: (_) => FeedProvider(service: storyService ?? FirebaseStoryService()),
        ),
        ChangeNotifierProvider(
          create: (_) => StoryInteractionProvider(
            service: interactionService ?? FirebaseStoryInteractionService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => JobsProvider(
            repository: jobRepository ?? FirestoreJobRepository(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ApplicationsProvider(
            repository: applicationRepository ?? FirestoreApplicationRepository(),
          ),
        ),
        Provider<UserRepository>(
          create: (_) => userRepository ?? FirestoreUserRepository(),
        ),
        Provider<FeedVideoTile>(
          create: (_) => feedVideoTile ?? RealFeedVideoTile(),
        ),
        Provider<StoryService>(
          create: (_) => storyService ?? FirebaseStoryService(),
        ),
        Provider<NotificationService>(
          create: (_) => notificationService ?? FirebaseNotificationService(),
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
  // Captured for the listener/dispose (never read via context after the
  // element may be deactivated).
  late final AuthProvider _auth = context.read<AuthProvider>();

  String? _registeredUid;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_syncNotifications);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncNotifications());
  }

  @override
  void dispose() {
    _auth.removeListener(_syncNotifications);
    super.dispose();
  }

  /// Keeps the device's FCM token on the signed-in user's profile.
  void _syncNotifications() {
    final uid = _auth.isAuthenticated ? _auth.snapshot.profile?.uid : null;
    final notifications = context.read<NotificationService>();
    if (uid != null && uid.isNotEmpty) {
      if (_registeredUid != uid) {
        _registeredUid = uid;
        notifications.register(uid);
      }
    } else if (_registeredUid != null) {
      notifications.unregister(_registeredUid!);
      _registeredUid = null;
    }
  }

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