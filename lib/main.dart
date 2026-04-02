import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/user_model.dart';
import 'features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return MaterialApp(
      title: 'HabitAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
      ),
      // StreamBuilder escucha cambios de autenticación en tiempo real.
      // Cuando el usuario inicia o cierra sesión, se reconstruye automáticamente.
      home: StreamBuilder<UserModel?>(
        stream: authRepository.authStateChanges,
        builder: (context, snapshot) {
          // Mientras Firebase comprueba si hay sesión activa
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si no hay usuario autenticado, mostrar login
          if (snapshot.data == null) {
            return LoginScreen(authRepository: authRepository);
          }

          // Si hay usuario autenticado, mostrar pantalla temporal de home
          return _HomeScreen(
            user: snapshot.data!,
            authRepository: authRepository,
          );
        },
      ),
    );
  }
}

/// Pantalla temporal de home para verificar que el auth funciona.
/// La reemplazaremos por el MainShell con tabs más adelante.
class _HomeScreen extends StatelessWidget {
  final UserModel user;
  final AuthRepository authRepository;

  const _HomeScreen({
    required this.user,
    required this.authRepository,
  });

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
      body: Center(
        child: Text(
          'Bienvenido, ${user.email}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}