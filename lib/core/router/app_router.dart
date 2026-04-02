import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

// Home temporal, esto se cambiará por el MainShell con tabs
class _HomeScreen extends StatelessWidget {
  final AuthRepository authRepository;

  const _HomeScreen({required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authRepository.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenido a HabitAI'),
      ),
    );
  }
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
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => _HomeScreen(
          authRepository: authRepository,
        ),
      ),
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
