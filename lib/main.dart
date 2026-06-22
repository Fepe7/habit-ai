import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/services/ai_availability_service.dart';
import 'core/services/premium_service.dart';
import 'core/services/billing_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/update_service.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'app.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // App Check: bloquea peticiones de clientes que no sean la app real,
    // protegiendo las Cloud Functions (y Gemini) frente a abuso.
    // En debug usa el provider de depuración; en release, Play Integrity.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );

    // Caché local más grande = más lecturas servidas desde disco = menos
    // lecturas facturadas en Firestore. El SDK ya persiste por defecto.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024,
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
    await PushNotificationService.instance.init();
    await ConnectivityService.instance.init();
    await UpdateService.instance.init();
    await AiAvailabilityService.instance.init();
    await PremiumService.instance.init();
    await BillingService.instance.init();
    await HomeWidgetService.instance.init();
    // refrescar el widget de pantalla de inicio con el estado de hoy
    unawaited(HomeWidgetService.instance.syncToday());

    runApp(const ThemeScope(child: LocaleScope(child: HabitAIApp())));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
