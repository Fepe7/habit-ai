import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/ai/presentation/ai_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'main_shell.dart';

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
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            builder: (context, state) => const AIScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // auth (fuera del shell, sin bottom nav)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
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
