import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // crashlytics: capturar errores del framework y errores asíncronos
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // google_sign_in v7 requiere inicialización explícita con el web client ID
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '958324745015-j5sd17c4ttccmriqs34gcv4ctbpq8hk2.apps.googleusercontent.com',
    );

    await NotificationService.instance.init();
    await ConnectivityService.instance.init();

    runApp(const ThemeScope(child: LocaleScope(child: HabitAIApp())));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
