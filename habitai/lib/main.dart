import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Punto de entrada de la aplicación.
/// Inicializa Firebase antes de montar el árbol de widgets.
void main() async {
  // Necesario antes de llamar a código asíncrono en main()
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con la configuración generada por FlutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitAI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('HabitAI - Firebase conectado'),
        ),
      ),
    );
  }
}
