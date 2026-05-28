import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Servicio singleton para feedback háptico al completar hábitos.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  /// Vibración con patrón: 250ms ON · 100ms pausa · 250ms ON.
  Future<void> habitCompleted() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(pattern: [0, 250, 100, 250]);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  // haptic ligero al seleccionar un emoji de ánimo
  Future<void> moodSelected() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 40);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Vibración corta para des-completar un hábito.
  Future<void> habitUncompleted() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 80);
    } else {
      await HapticFeedback.lightImpact();
    }
  }
}
