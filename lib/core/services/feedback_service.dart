import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Servicio singleton para feedback sensorial al completar hábitos.
/// Combina vibración prolongada + sonido de check.
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

  /// Vibración doble (medio + pesado) y sonido de check completado.
  Future<void> habitCompleted() async {
    // Vibración más prolongada: dos pulsos
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();

    // Sonido de check
    try {
      await _init();
      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (_) {
      // Si falla el audio, la vibración ya se ejecutó — no es crítico
    }
  }

  /// Vibración ligera para des-completar un hábito.
  Future<void> habitUncompleted() async {
    await HapticFeedback.lightImpact();
  }
}
