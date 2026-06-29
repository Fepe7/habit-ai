import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Emoticonos propios de HabitAI (SVG vectoriales en assets/emojis/), en vez
/// de los emoji del sistema. Identidad estable: el ánimo se mapea por rating
/// (1-5) y la reacción por su clave unicode (🔥/❤️/⭐/⚡/🏆), que es lo
/// que ya se guarda en Firestore — no hace falta migrar datos.
///
/// Si llega una clave desconocida, cae con elegancia al glyph unicode como
/// `Text`, así nada se rompe si aparece un emoji antiguo o no contemplado.
class AppEmoji extends StatelessWidget {
  final String _asset;
  final String? _fallbackGlyph;
  final double size;

  const AppEmoji._(this._asset, this._fallbackGlyph, this.size, {super.key});

  /// Cara de ánimo según el rating 1-5.
  factory AppEmoji.mood(int rating, {double size = 24, Key? key}) {
    final i = rating.clamp(1, 5);
    return AppEmoji._('assets/emojis/mood/mood_$i.svg', null, size, key: key);
  }

  /// Reacción social a partir de su clave unicode (la que vive en Firestore).
  factory AppEmoji.reaction(String emoji, {double size = 24, Key? key}) {
    final asset = _reactionAssets[emoji];
    return AppEmoji._(
      asset ?? '',
      asset == null ? emoji : null,
      size,
      key: key,
    );
  }

  /// Reacciones disponibles, en orden de presentación.
  static const reactionKeys = ['🔥', '❤️', '⭐', '⚡', '🏆'];

  static const _reactionAssets = {
    '🔥': 'assets/emojis/reactions/fire.svg',
    '❤️': 'assets/emojis/reactions/heart.svg',
    '⭐': 'assets/emojis/reactions/star.svg',
    '⚡': 'assets/emojis/reactions/bolt.svg',
    '🏆': 'assets/emojis/reactions/trophy.svg',
  };

  @override
  Widget build(BuildContext context) {
    if (_asset.isEmpty) {
      // clave desconocida → glyph del sistema, escalado al tamaño pedido
      return Text(
        _fallbackGlyph ?? '',
        style: TextStyle(fontSize: size * 0.9),
      );
    }
    return SvgPicture.asset(_asset, width: size, height: size);
  }
}
