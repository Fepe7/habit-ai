import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // init del plugin de notificaciones antes de arrancar la app.
  // Los permisos se piden mas tarde, cuando el usuario ya esta logueado
  await NotificationService.instance.init();

  // ThemeScope envuelve toda la app para que el tema sea accesible en cualquier sitio
  runApp(const ThemeScope(child: HabitAIApp()));
}
