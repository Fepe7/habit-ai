import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

// Handler de mensajes con la app en segundo plano o terminada.
// DEBE ser una función top-level con @pragma('vm:entry-point'): se ejecuta en
// un isolate separado que no comparte estado con la app, por eso reinicializa
// Firebase. No mostramos nada a mano: si el mensaje trae `notification`, el SO
// lo pinta solo en la bandeja; el tap se maneja al abrir la app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] mensaje en background: ${message.messageId}');
}

/// Servicio singleton de notificaciones push (Firebase Cloud Messaging).
/// Complementa a [NotificationService] (locales): este recibe avisos remotos
/// enviados desde las Cloud Functions (revisión semanal, follows, etc.).
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  // Callback de navegación: lo inyecta app.dart con el GoRouter.
  void Function(String route)? _navigate;
  // Ruta pendiente cuando la notificación llega antes de que el router exista
  // (app abierta desde estado terminado al tocar la notificación).
  String? _pendingRoute;

  // Inicializa listeners de FCM. Llamar una vez en main(), tras Firebase.init.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Registrar el handler de background antes que cualquier otro listener.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // iOS: mostrar también banner/sonido cuando la app está en primer plano.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Primer plano: FCM no muestra nada por sí solo → lo pintamos como local.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap en la notificación con la app en segundo plano (warm start).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);

    // App abierta desde estado terminado al tocar una notificación.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNavigation(initial);

    // El token de FCM rota: re-guardarlo cuando cambie.
    _messaging.onTokenRefresh.listen((token) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _saveToken(uid, token);
    });
  }

  // Pide permiso de notificaciones y registra el token del dispositivo para el
  // usuario actual. Llamar cuando ya hay sesión (p.ej. desde MainShell).
  Future<void> registerForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (e) {
      debugPrint('[FCM] no se pudo obtener token: $e');
    }
  }

  // Borra el token del dispositivo al cerrar sesión para que el usuario no siga
  // recibiendo push de una cuenta que ya no usa en este teléfono.
  Future<void> unregisterForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final token = await _messaging.getToken();
      if (uid != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('fcm_tokens')
            .doc(token)
            .delete();
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] no se pudo borrar token: $e');
    }
  }

  // Conecta el router (app.dart). Si había una ruta pendiente, la consume.
  void attachRouter(void Function(String route) navigate) {
    _navigate = navigate;
    final pending = _pendingRoute;
    if (pending != null) {
      _pendingRoute = null;
      navigate(pending);
    }
  }

  // Navega a [route] o la guarda si el router aún no está listo.
  // Usado también por NotificationService al tocar una notificación local.
  void navigateTo(String route) {
    final navigate = _navigate;
    if (navigate != null) {
      navigate(route);
    } else {
      _pendingRoute = route;
    }
  }

  // ==================== privados ====================

  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FCM] no se pudo guardar token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    // Pushes marcados con skipForeground (p.ej. logros) no se pintan con la
    // app abierta: la UI in-app ya celebra el evento y duplicaría el aviso.
    if (message.data['skipForeground'] == '1') return;
    NotificationService.instance.showSocialNotification(
      title: notification.title ?? 'HabitAI',
      body: notification.body ?? '',
      payload: message.data['route'] as String?,
    );
  }

  void _handleNavigation(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) navigateTo(route);
  }
}
