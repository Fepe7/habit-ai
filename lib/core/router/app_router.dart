import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/habits/presentation/habit_detail_screen.dart';
import '../../features/habits/presentation/group_detail_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/weekly_detail_screen.dart';
import '../../features/dashboard/presentation/category_detail_screen.dart';
import '../../features/dashboard/presentation/streaks_detail_screen.dart';
import '../../features/ai/presentation/ai_screen.dart';
import '../../features/ai/presentation/weekly_review_screen.dart';
import '../../features/ai/presentation/butterfly_projection_screen.dart';
import '../../features/ai/presentation/pattern_insights_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/levels/presentation/levels_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/public_profiles_feed_screen.dart';
import '../../features/profile/presentation/public_profile_screen.dart';
import '../../features/community/presentation/community_templates_feed_screen.dart';
import '../../features/community/presentation/community_template_detail_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/challenges/presentation/challenges_screen.dart';
import '../../features/challenges/presentation/challenge_detail_screen.dart';
import '../../features/social/presentation/followers_screen.dart';
import '../../features/habits/presentation/all_habits_screen.dart';
import '../../features/settings/presentation/privacy_settings_screen.dart';
import 'main_shell.dart';

// transicion suave fade + slide para pantallas internas
CustomTransitionPage<void> _fadeSlideTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

// Configura el router con las rutas y el auth guard
GoRouter createRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: '/',
    // Cada vez que cambia el estado de auth, se vuelve a comprobar el redirect
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // No logueado y no está en login/register -> mandar a login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Ya logueado pero intenta ir a login/register -> mandar a home
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      // Todo bien, no hace falta redirigir
      return null;
    },
    routes: [
      // tabs principales con bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HabitsScreen(),
            routes: [
              GoRoute(
                path: 'habit/:habitId',
                name: 'habit-detail',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: HabitDetailScreen(
                    habitId: state.pathParameters['habitId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'group/:groupId',
                name: 'group-detail',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: GroupDetailScreen(
                    groupId: state.pathParameters['groupId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'all-habits',
                name: 'all-habits',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: const AllHabitsScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
            routes: [
              GoRoute(
                path: 'weekly',
                name: 'dashboard-weekly',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: const WeeklyDetailScreen(),
                ),
              ),
              GoRoute(
                path: 'categories',
                name: 'dashboard-categories',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: const CategoryDetailScreen(),
                ),
              ),
              GoRoute(
                path: 'streaks',
                name: 'dashboard-streaks',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: const StreaksDetailScreen(),
                ),
              ),
              GoRoute(
                path: 'achievements',
                name: 'achievements',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: const AchievementsScreen(),
                ),
              ),
              GoRoute(
                path: 'weekly-review/:weekId',
                name: 'weekly-review',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: WeeklyReviewScreen(
                    weekId: state.pathParameters['weekId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'butterfly/:monthId',
                name: 'butterfly-projection',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: ButterflyProjectionScreen(
                    monthId: state.pathParameters['monthId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'patterns/:periodId',
                name: 'pattern-insights',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: PatternInsightsScreen(
                    periodId: state.pathParameters['periodId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'levels',
                name: 'levels',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: const LevelsScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            builder: (context, state) => const AIScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/profiles',
            name: 'public-profiles-feed',
            builder: (context, state) => const PublicProfilesFeedScreen(),
            routes: [
              GoRoute(
                path: ':userId',
                name: 'public-profile',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: PublicProfileScreen(
                    userId: state.pathParameters['userId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/explore',
            name: 'explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/challenges',
            name: 'challenges',
            builder: (context, state) => const ChallengesScreen(),
            routes: [
              GoRoute(
                path: ':challengeId',
                name: 'challenge-detail',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: ChallengeDetailScreen(
                    challengeId: state.pathParameters['challengeId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/community',
            name: 'community-feed',
            builder: (context, state) =>
                const CommunityTemplatesFeedScreen(),
            routes: [
              GoRoute(
                path: ':templateId',
                name: 'community-template-detail',
                pageBuilder: (context, state) => _fadeSlideTransition(
                  state: state,
                  child: CommunityTemplateDetailScreen(
                    templateId: state.pathParameters['templateId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/followers',
            name: 'followers',
            pageBuilder: (context, state) {
              final tab = int.tryParse(
                    state.uri.queryParameters['tab'] ?? '',
                  ) ??
                  0;
              return _fadeSlideTransition(
                state: state,
                child: FollowersScreen(initialTab: tab),
              );
            },
          ),
          GoRoute(
            path: '/privacy-settings',
            name: 'privacy-settings',
            pageBuilder: (context, state) => _fadeSlideTransition(
              state: state,
              child: const PrivacySettingsScreen(),
            ),
          ),
        ],
      ),

      // auth (fuera del shell, sin bottom nav)
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _fadeSlideTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
    ],
  );
}

// Wrapper para que GoRouter pueda escuchar un Stream
// (refreshListenable necesita un Listenable, no un Stream)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
