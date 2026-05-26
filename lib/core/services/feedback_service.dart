import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Servicio singleton para feedback sensorial al completar hábitos.
/// Combina vibración con patrón + sonido discreto de confirmación.
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

    // Nuevo player cada vez para garantizar reproducción desde el inicio
    try {
      final player = AudioPlayer();
      await player.setVolume(0.8);
      await player.play(AssetSource('sounds/habit_complete.mp3'));
      // Liberar recursos al terminar
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {
      // Audio no crítico — vibración ya se ejecutó
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
