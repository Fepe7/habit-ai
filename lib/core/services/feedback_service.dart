import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Servicio singleton para feedback sensorial al completar hábitos.
/// Combina vibración continua de 500ms + sonido de check.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _player.setSource(AssetSource('sounds/habit_complete.mp3'));
    await _player.setVolume(0.8);
    _initialized = true;
  }

  /// Vibración continua de 500ms y sonido de check completado.
  Future<void> habitCompleted() async {
    // Vibración de 500ms continuos (con fallback a HapticFeedback si el device no soporta)
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      // Patrón: [delay, on, off, on] en ms → 250ms ON · 100ms pausa · 250ms ON
      Vibration.vibrate(pattern: [0, 250, 100, 250]);
    } else {
      await HapticFeedback.heavyImpact();
    }

    // Sonido de check (en paralelo con la vibración)
    try {
      await _init();
      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (_) {
      // Si falla el audio no es crítico
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
