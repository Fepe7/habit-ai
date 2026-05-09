import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // google_sign_in v7 requiere inicialización explícita con el web client ID
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '958324745015-j5sd17c4ttccmriqs34gcv4ctbpq8hk2.apps.googleusercontent.com',
  );

  // init del plugin de notificaciones antes de arrancar la app.
  // Los permisos se piden mas tarde, cuando el usuario ya esta logueado
  await NotificationService.instance.init();

  // ThemeScope envuelve toda la app para que el tema sea accesible en cualquier sitio
  runApp(const ThemeScope(child: HabitAIApp()));
}
