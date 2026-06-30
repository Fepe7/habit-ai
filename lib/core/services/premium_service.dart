import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Límites del plan free. Centralizados aquí para que el paywall,
/// los gates y los textos de UI cuenten siempre la misma historia.
class PremiumLimits {
  PremiumLimits._();

  /// Máximo de hábitos activos en el plan free
  static const int maxFreeHabits = 20;

  /// Cuotas SEMANALES del plan free para IA (deben coincidir con
  /// FREE_WEEKLY_LIMITS en functions/index.js). El onboarding es gratis aparte
  /// y no consume.
  static const int freeWeeklyHabitChat = 3; // mensajes/semana en el chat IA
  static const int freeWeeklyRoutineChat = 2; // conversaciones/semana de coach
  static const int freeWeeklyReview = 1;
  static const int freeWeeklyButterfly = 1;
  static const int freeWeeklyPatterns = 1;
  static const int freeWeeklyRenegotiation = 2; // ajustes inteligentes/semana

  /// Fase de lanzamiento gratis: mientras sea true, las funciones de IA
  /// "premium" se abren a todos bajo cuota semanal. Ponlo en false al activar
  /// el plan de pago para que vuelva el gating premium.
  static const bool freeLaunchPhase = true;

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

  /// Mensajes free restantes esta semana en el chat IA general
  /// (null = sin límite: premium o aún en onboarding).
  final ValueNotifier<int?> freePlanMessagesLeft = ValueNotifier(null);

  /// Usos free restantes ESTA SEMANA por función de IA (keys = las de
  /// FREE_WEEKLY_LIMITS en backend). Valor null para una key = sin límite
  /// (premium, o habitChat durante el onboarding). Mapa vacío = desconocido.
  final ValueNotifier<Map<String, int?>> weeklyRemaining = ValueNotifier({});

  /// Límite semanal de cada función (debe coincidir con FREE_WEEKLY_LIMITS).
  static const Map<String, int> _weeklyLimits = {
    'habitChat': PremiumLimits.freeWeeklyHabitChat,
    'routineChat': PremiumLimits.freeWeeklyRoutineChat,
    'weeklyReview': PremiumLimits.freeWeeklyReview,
    'butterfly': PremiumLimits.freeWeeklyButterfly,
    'patterns': PremiumLimits.freeWeeklyPatterns,
    'renegotiation': PremiumLimits.freeWeeklyRenegotiation,
  };

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  Future<void> init() async {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSub?.cancel();
      if (user == null) {
        isPremium.value = false;
        freePlanMessagesLeft.value = null;
        weeklyRemaining.value = {};
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
              weeklyRemaining.value = _computeWeeklyRemaining(data);
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

  /// Mensajes de chat IA gratis restantes ESTA SEMANA, con la misma lógica que
  /// el backend: el onboarding es gratis (sin contador hasta completarlo) y, ya
  /// completado, hay una cuota semanal `weeklyUsage.habitChat` que se resetea
  /// sola al cambiar el ISO week id.
  int? _remainingFreeMessages(Map<String, dynamic>? data) {
    if (_hasPremium(data)) return null; // premium = sin límite
    // Onboarding gratis: no aplica cupo hasta completarlo.
    if (data?['onboardingCompleted'] != true) return null;
    final used = _weeklyCount(data, 'habitChat');
    final left = PremiumLimits.freeWeeklyHabitChat - used;
    return left < 0 ? 0 : left;
  }

  /// Usos restantes esta semana de cada función. null para una key = sin
  /// límite (premium; o habitChat mientras el onboarding no esté completado).
  Map<String, int?> _computeWeeklyRemaining(Map<String, dynamic>? data) {
    final premium = _hasPremium(data);
    final onboardingDone = data?['onboardingCompleted'] == true;
    return {
      for (final entry in _weeklyLimits.entries)
        entry.key: (premium || (entry.key == 'habitChat' && !onboardingDone))
            ? null
            : (entry.value - _weeklyCount(data, entry.key))
                .clamp(0, entry.value),
    };
  }

  /// Usos consumidos esta semana de una clave de `weeklyUsage`. Si la entrada
  /// es de otra semana, cuenta 0 (el contador se renueva solo).
  int _weeklyCount(Map<String, dynamic>? data, String key) {
    final usage = data?['weeklyUsage'];
    final entry = usage is Map ? usage[key] : null;
    if (entry is! Map) return 0;
    if (entry['week'] != _isoWeekId(DateTime.now())) return 0;
    return (entry['count'] as int?) ?? 0;
  }

  /// ID ISO de la semana ("YYYY-Www"), idéntico a getIsoWeekId en el backend
  /// para que cliente y servidor cuenten la misma ventana semanal.
  static String _isoWeekId(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final dayNum = d.weekday; // 1=lun..7=dom (ya en convención ISO)
    final thursday = d.add(Duration(days: 4 - dayNum));
    final yearStart = DateTime.utc(thursday.year, 1, 1);
    final weekNum =
        ((thursday.difference(yearStart).inDays + 1) / 7).ceil();
    return '${thursday.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    isPremium.dispose();
    freePlanMessagesLeft.dispose();
    weeklyRemaining.dispose();
  }
}
