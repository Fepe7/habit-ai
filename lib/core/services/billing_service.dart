import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Envoltorio de RevenueCat para las suscripciones de HabitAI Premium.
///
/// RevenueCat solo se encarga de COBRAR (envuelve Play Billing / StoreKit) y
/// de notificar la compra a nuestro webhook. La fuente de verdad del estado
/// premium sigue siendo `users/{uid}.isPremium` en Firestore (lo escribe el
/// webhook con Admin SDK y `PremiumService` lo lee por stream). Este servicio
/// nunca toca Firestore: solo lanza la compra y restaura.
///
/// Las API keys PÚBLICAS de RevenueCat van aquí (son públicas por diseño, no
/// son secretos). Mientras estén vacías el servicio queda inerte: la app
/// arranca igual y el paywall avisa de que el billing aún no está configurado.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  /// Entitlement configurado en el panel de RevenueCat. Si está activo en el
  /// CustomerInfo, el usuario tiene premium.
  static const String entitlementId = 'premium';

  // TODO(billing): pegar las API keys públicas del panel de RevenueCat
  // (Project Settings → API Keys). Una por plataforma.
  static const String _androidApiKey = '';
  static const String _iosApiKey = 'appl_XhhFnvXVkBPMDatFyHfSsofGxdZ';

  bool _configured = false;
  bool get isConfigured => _configured;

  StreamSubscription<User?>? _authSub;
  String? _identifiedUid;

  /// Configura el SDK una sola vez. Tolerante a fallos: si no hay API key o
  /// la plataforma no soporta billing, no rompe el arranque. Tras configurar,
  /// sigue el estado de auth para mantener el `app_user_id` = uid de Firebase.
  Future<void> init() async {
    if (_configured) return;
    final apiKey = _apiKeyForPlatform();
    if (apiKey.isEmpty) {
      debugPrint('BillingService: API key de RevenueCat sin configurar.');
      return;
    }
    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;

      // Identifica al usuario actual y reacciona a cambios de sesión: así el
      // app_user_id de RevenueCat siempre coincide con el uid de Firebase.
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) await logIn(current.uid);
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) {
          logOut();
        } else if (user.uid != _identifiedUid) {
          logIn(user.uid);
        }
      });
    } catch (e) {
      debugPrint('BillingService: fallo al configurar RevenueCat: $e');
    }
  }

  String _apiKeyForPlatform() {
    if (Platform.isAndroid) return _androidApiKey;
    if (Platform.isIOS) return _iosApiKey;
    return '';
  }

  /// Asocia la compra al uid de Firebase: el `app_user_id` de RevenueCat pasa
  /// a ser el uid, que es lo que el webhook usa para escribir el premium en el
  /// doc correcto. Llamar tras login y en cada cambio de sesión.
  Future<void> logIn(String uid) async {
    if (!_configured) return;
    try {
      await Purchases.logIn(uid);
      _identifiedUid = uid;
    } catch (e) {
      debugPrint('BillingService: logIn falló: $e');
    }
  }

  /// Desvincula al cerrar sesión para no mezclar compras entre cuentas.
  Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
      _identifiedUid = null;
    } catch (e) {
      debugPrint('BillingService: logOut falló: $e');
    }
  }

  /// Paquete mensual del offering por defecto (o null si no hay oferta).
  Future<Package?> monthlyPackage() async {
    if (!_configured) return null;
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return null;
    return current.monthly ?? current.availablePackages.firstOrNull;
  }

  /// Lanza el flujo de compra nativo. Devuelve true si el entitlement queda
  /// activo. Propaga `PurchasesErrorCode.purchaseCancelledError` como
  /// cancelación (la pantalla la distingue de un error real).
  Future<bool> purchaseMonthly() async {
    if (!_configured) {
      throw const BillingNotConfiguredException();
    }
    final pkg = await monthlyPackage();
    if (pkg == null) {
      throw const BillingNotConfiguredException();
    }
    final info = await Purchases.purchasePackage(pkg);
    return _hasEntitlement(info);
  }

  /// Restaura compras previas (obligatorio en iOS). Devuelve true si tras
  /// restaurar el usuario tiene el entitlement activo.
  Future<bool> restore() async {
    if (!_configured) {
      throw const BillingNotConfiguredException();
    }
    final info = await Purchases.restorePurchases();
    return _hasEntitlement(info);
  }

  bool _hasEntitlement(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlementId);

  void dispose() {
    _authSub?.cancel();
    _authSub = null;
  }
}

/// El billing aún no tiene API keys / offering configurado en RevenueCat.
class BillingNotConfiguredException implements Exception {
  const BillingNotConfiguredException();
}
