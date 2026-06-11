import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Límites del plan free. Centralizados aquí para que el paywall,
/// los gates y los textos de UI cuenten siempre la misma historia.
class PremiumLimits {
  PremiumLimits._();

  /// Máximo de hábitos activos en el plan free
  static const int maxFreeHabits = 7;

  /// Mensajes/mes del chat de generación de planes en free
  /// (debe coincidir con FREE_PLAN_MESSAGES_PER_MONTH en functions/index.js)
  static const int freePlanMessagesPerMonth = 7;

  /// Precio mostrado en el paywall (el real lo fijará la tienda)
  static const String monthlyPriceLabel = '3,99 €/mes';
}

/// Singleton que expone si el usuario actual tiene premium activo.
/// Suscrito a users/{uid} en tiempo real y re-suscrito en cada cambio de
/// sesión. Fail-closed: sin doc, sin sesión o con error → free (los gates
/// reales están en backend; esto solo decide qué UI mostrar).
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  final ValueNotifier<bool> isPremium = ValueNotifier(false);

  /// Mensajes free restantes este mes en el chat de planes
  /// (null = desconocido todavía; el backend es la fuente de verdad)
  final ValueNotifier<int?> freePlanMessagesLeft = ValueNotifier(null);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  Future<void> init() async {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSub?.cancel();
      if (user == null) {
        isPremium.value = false;
        freePlanMessagesLeft.value = null;
        return;
      }
      _userSub = FirebaseFirestore.instance
          .doc('users/${user.uid}')
          .snapshots()
          .listen(
            (snap) {
              final data = snap.data();
              isPremium.value = _hasPremium(data);
              freePlanMessagesLeft.value = _remainingFreeMessages(data);
            },
            onError: (_) => isPremium.value = false,
          );
    });
  }

  bool _hasPremium(Map<String, dynamic>? data) {
    if (data == null || data['isPremium'] != true) return false;
    final until = data['premiumUntil'];
    if (until is Timestamp && until.toDate().isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  /// Calcula los mensajes restantes con la misma lógica que el backend:
  /// freePlanUsage = { month: "2026-06", count } se resetea por mes natural.
  int? _remainingFreeMessages(Map<String, dynamic>? data) {
    if (_hasPremium(data)) return null; // premium = sin límite
    final usage = data?['freePlanUsage'];
    if (usage is! Map) return PremiumLimits.freePlanMessagesPerMonth;
    final now = DateTime.now();
    final monthId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (usage['month'] != monthId) {
      return PremiumLimits.freePlanMessagesPerMonth;
    }
    final count = usage['count'] as int? ?? 0;
    final left = PremiumLimits.freePlanMessagesPerMonth - count;
    return left < 0 ? 0 : left;
  }

  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    isPremium.dispose();
    freePlanMessagesLeft.dispose();
  }
}
