import 'package:go_router/go_router.dart';

import '../../features/feed/saved_candidates_screen.dart';
import '../../features/feed/story_feed_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/seeker_profile_screen.dart';
import '../../features/register/register_screen.dart';
import '../../features/story/my_stories_screen.dart';
import '../../features/story/studio_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

/// Central navigation. Creates a fresh router (and redirects) per call.
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: WelcomeScreen.route,
      refreshListenable: auth,
      redirect: (context, state) => _redirect(auth, state.matchedLocation),
      routes: [
        GoRoute(path: WelcomeScreen.route, name: 'welcome', builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: OnboardingScreen.route, name: 'onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: LoginScreen.route, name: 'login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: RegisterScreen.route,
          name: 'register',
          builder: (context, state) {
            final role = UserRole.fromValue(state.uri.queryParameters['role']);
            return RegisterScreen(initialRole: role);
          },
        ),
        GoRoute(path: HomeScreen.route, name: 'home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: StoryStudioScreen.route, name: 'studio', builder: (_, __) => const StoryStudioScreen()),
        GoRoute(path: MyStoriesScreen.route, name: 'my-stories', builder: (_, __) => const MyStoriesScreen()),
        GoRoute(path: StoryFeedScreen.route, name: 'explore', builder: (_, __) => const StoryFeedScreen()),
        GoRoute(path: SavedCandidatesScreen.route, name: 'candidates', builder: (_, __) => const SavedCandidatesScreen()),
        GoRoute(
          path: '/seeker/:uid',
          name: 'seeker',
          builder: (context, state) => SeekerProfileScreen(uid: state.pathParameters['uid']!),
        ),
      ],
    );
  }

  static const _publicRoutes = {
    WelcomeScreen.route,
    OnboardingScreen.route,
    LoginScreen.route,
    RegisterScreen.route,
  };

  static const _seekersOnly = {
    StoryStudioScreen.route,
    MyStoriesScreen.route,
  };

  static const _recruitersOnly = {
    SavedCandidatesScreen.route,
  };

  static String? _redirect(AuthProvider auth, String location) {
    if (!auth.isAuthenticated) {
      // Guests may browse the marketing/auth pages only; guards land on login.
      return _publicRoutes.contains(location) ? null : LoginScreen.route;
    }

    if (!auth.hasRole) {
      // Signed in but no role yet: force role selection.
      final onboarding = OnboardingScreen.route;
      return location == onboarding || location == WelcomeScreen.route ? null : onboarding;
    }

    // Role-scoped sections.
    if (_seekersOnly.contains(location) && auth.role != UserRole.seeker) {
      return HomeScreen.route;
    }
    if (_recruitersOnly.contains(location) && auth.role != UserRole.recruiter) {
      return HomeScreen.route;
    }

    // Onboarded users land on home instead of the marketing welcome page.
    return location == WelcomeScreen.route ? HomeScreen.route : null;
  }
}