import 'package:go_router/go_router.dart';

import '../../features/onboarding/onboarding_screen.dart';
import '../../features/welcome/welcome_screen.dart';

/// Central navigation factory. Each call returns a fresh GoRouter so that
/// every test (and hot restart) starts from the initial location.
class AppRouter {
  AppRouter._();

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: WelcomeScreen.route,
      routes: [
        GoRoute(
          path: WelcomeScreen.route,
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: OnboardingScreen.route,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    );
  }
}