import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Servicio singleton para feedback háptico al completar hábitos.
///
/// iOS y Android se tratan por separado: en iPhone `Vibration.hasVibrator()`
/// devuelve true pero los patrones personalizados del plugin se ignoran sin
/// CoreHaptics, así que allí se usa siempre el Taptic Engine via
/// [HapticFeedback] (UIFeedbackGenerator), que es nítido y nunca falla.
/// En Android se usan patrones con control de amplitud cuando el hardware
/// lo soporta.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  bool get _isIOS => Platform.isIOS;

  /// Secuencia de impactos en el Taptic Engine separados por pausas.
  Future<void> _tapticSequence(
    List<(Duration, Future<void> Function())> steps,
  ) async {
    for (final (delay, impact) in steps) {
      if (delay > Duration.zero) await Future.delayed(delay);
      await impact();
    }
  }

  /// Celebración al completar un hábito — patrón "crescendo de recompensa":
  /// dos toques suaves en subida + pausa breve + acento fuerte final.
  /// La anticipación (tic-tic… ¡TUM!) es lo que dispara la sensación de
  /// logro, no la duración total. Corto (<400ms) para que pida repetirse.
  Future<void> habitCompleted() async {
    if (_isIOS) {
      await _tapticSequence([
        (Duration.zero, HapticFeedback.lightImpact),
        (const Duration(milliseconds: 70), HapticFeedback.mediumImpact),
        (const Duration(milliseconds: 110), HapticFeedback.heavyImpact),
        (const Duration(milliseconds: 60), HapticFeedback.lightImpact),
      ]);
      return;
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) {
      await HapticFeedback.heavyImpact();
      return;
    }
    final hasAmplitude = await Vibration.hasAmplitudeControl();
    if (hasAmplitude) {
      // crescendo real: amplitud creciente 60 → 140 → 255 + eco suave
      Vibration.vibrate(
        pattern: [0, 35, 60, 45, 90, 80, 50, 30],
        intensities: [0, 60, 0, 140, 0, 255, 0, 70],
      );
    } else {
      // sin control de amplitud: la duración creciente simula la subida
      Vibration.vibrate(pattern: [0, 30, 60, 50, 90, 110]);
    }
  }

  /// Patrón celebratorio al recibir una reacción social: doble toque
  /// medio→fuerte (el haptic de "éxito" de iOS, replicado en Android).
  Future<void> reactionReceived() async {
    if (_isIOS) {
      await _tapticSequence([
        (Duration.zero, HapticFeedback.mediumImpact),
        (const Duration(milliseconds: 90), HapticFeedback.heavyImpact),
      ]);
      return;
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(pattern: [0, 100, 80, 100, 80, 150]);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  // haptic ligero al seleccionar un emoji de ánimo
  Future<void> moodSelected() async {
    if (_isIOS) {
      await HapticFeedback.selectionClick();
      return;
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(duration: 40);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Vibración corta y neutra para des-completar un hábito — a propósito
  /// menos satisfactoria que completar: deshacer no debe dar recompensa.
  Future<void> habitUncompleted() async {
    if (_isIOS) {
      await HapticFeedback.lightImpact();
      return;
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(duration: 80);
    } else {
      await HapticFeedback.lightImpact();
    }
  }
}
