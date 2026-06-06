import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Singleton que expone si la IA está pausada por presupuesto o manualmente.
/// Suscrito a system/ai_state en Firestore en tiempo real.
/// Fail-open: si el doc no existe o hay error de red, asume no pausado.
class AiAvailabilityService {
  AiAvailabilityService._();
  static final AiAvailabilityService instance = AiAvailabilityService._();

  final ValueNotifier<bool> isPaused = ValueNotifier(false);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Future<void> init() async {
    _sub = FirebaseFirestore.instance
        .doc('system/ai_state')
        .snapshots()
        .listen(
          (snap) {
            isPaused.value = snap.exists && (snap.data()?['paused'] == true);
          },
          onError: (_) => isPaused.value = false,
        );
  }

  void dispose() {
    _sub?.cancel();
    isPaused.dispose();
  }
}
