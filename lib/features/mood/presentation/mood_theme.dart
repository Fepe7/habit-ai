import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

// colores por rating de ánimo (1-5) y definiciones de labels emocionales
class MoodTheme {
  MoodTheme._();

  static const emojis = ['😞', '😕', '😐', '🙂', '😄'];

  static String emojiFor(int rating) => emojis[(rating - 1).clamp(0, 4)];

  static const _lightBgs = [
    Color(0xFFEDE9FE), // 1 — violeta suave
    Color(0xFFDBEAFE), // 2 — azul suave
    Color(0xFFFEF3C7), // 3 — ámbar cálido
    Color(0xFFD1FAE5), // 4 — menta
    Color(0xFFFEF3C7), // 5 — dorado
  ];

  static const _lightAccents = [
    Color(0xFF7C3AED), // 1
    Color(0xFF3B82F6), // 2
    Color(0xFFD97706), // 3
    Color(0xFF059669), // 4
    Color(0xFFF59E0B), // 5
  ];

  static const _darkBgs = [
    Color(0xFF2E1065), // 1
    Color(0xFF1E3A5F), // 2
    Color(0xFF422006), // 3
    Color(0xFF064E3B), // 4
    Color(0xFF451A03), // 5
  ];

  static const _darkAccents = [
    Color(0xFFA78BFA), // 1
    Color(0xFF60A5FA), // 2
    Color(0xFFFBBF24), // 3
    Color(0xFF34D399), // 4
    Color(0xFFFBBF24), // 5
  ];

  static Color ratingBg(int rating, Brightness brightness) {
    final i = (rating - 1).clamp(0, 4);
    return brightness == Brightness.light ? _lightBgs[i] : _darkBgs[i];
  }

  static Color ratingAccent(int rating, Brightness brightness) {
    final i = (rating - 1).clamp(0, 4);
    return brightness == Brightness.light ? _lightAccents[i] : _darkAccents[i];
  }

  // colores del sheet dark (independiente del tema de la app)
  static const _sheetZoneBgs = [
    Color(0xFF5C2A18), // 1 — terracota
    Color(0xFF4D3A10), // 2 — ámbar
    Color(0xFF1A3A2A), // 3 — sage
    Color(0xFF0F3535), // 4 — teal
    Color(0xFF3D3008), // 5 — dorado
  ];

  static const _sheetZoneAccents = [
    Color(0xFFD4754A), // 1
    Color(0xFFD4A03A), // 2
    Color(0xFF5DAA78), // 3
    Color(0xFF45AEAD), // 4
    Color(0xFFE8BA4A), // 5
  ];

  static Color sheetZoneBg(int rating) =>
      _sheetZoneBgs[(rating - 1).clamp(0, 4)];

  static Color sheetZoneAccent(int rating) =>
      _sheetZoneAccents[(rating - 1).clamp(0, 4)];

  static String ratingLabel(int rating, S s) {
    return switch (rating) {
      1 => s.moodRating1,
      2 => s.moodRating2,
      3 => s.moodRating3,
      4 => s.moodRating4,
      5 => s.moodRating5,
      _ => '',
    };
  }

  static List<MoodLabelDef> labels(S s) => [
        // negativas
        MoodLabelDef('anxiety', s.moodLabelAnxiety, '😰',
            const Color(0xFFFEE2E2), const Color(0xFFDC2626),
            darkBg: const Color(0xFF450A0A), darkFg: const Color(0xFFFCA5A5),
            isPositive: false),
        MoodLabelDef('tiredness', s.moodLabelTiredness, '😴',
            const Color(0xFFE0E7FF), const Color(0xFF6366F1),
            darkBg: const Color(0xFF1E1B4B), darkFg: const Color(0xFFA5B4FC),
            isPositive: false),
        MoodLabelDef('stress', s.moodLabelStress, '😤',
            const Color(0xFFFCE7F3), const Color(0xFFDB2777),
            darkBg: const Color(0xFF500724), darkFg: const Color(0xFFF9A8D4),
            isPositive: false),
        MoodLabelDef('sadness', s.moodLabelSadness, '😢',
            const Color(0xFFDBEAFE), const Color(0xFF2563EB),
            darkBg: const Color(0xFF1E3A5F), darkFg: const Color(0xFF93C5FD),
            isPositive: false),
        MoodLabelDef('anger', s.moodLabelAnger, '💢',
            const Color(0xFFFEE2E2), const Color(0xFFB91C1C),
            darkBg: const Color(0xFF450A0A), darkFg: const Color(0xFFFCA5A5),
            isPositive: false),
        // positivas
        MoodLabelDef('motivation', s.moodLabelMotivation, '🔥',
            const Color(0xFFFFEDD5), const Color(0xFFEA580C),
            darkBg: const Color(0xFF431407), darkFg: const Color(0xFFFDBA74),
            isPositive: true),
        MoodLabelDef('calm', s.moodLabelCalm, '🧘',
            const Color(0xFFD1FAE5), const Color(0xFF059669),
            darkBg: const Color(0xFF064E3B), darkFg: const Color(0xFF6EE7B7),
            isPositive: true),
        MoodLabelDef('energy', s.moodLabelEnergy, '⚡',
            const Color(0xFFFEF9C3), const Color(0xFFCA8A04),
            darkBg: const Color(0xFF422006), darkFg: const Color(0xFFFDE047),
            isPositive: true),
        MoodLabelDef('gratitude', s.moodLabelGratitude, '🙏',
            const Color(0xFFECFDF5), const Color(0xFF047857),
            darkBg: const Color(0xFF022C22), darkFg: const Color(0xFF6EE7B7),
            isPositive: true),
        MoodLabelDef('focus', s.moodLabelFocus, '🎯',
            const Color(0xFFEDE9FE), const Color(0xFF7C3AED),
            darkBg: const Color(0xFF2E1065), darkFg: const Color(0xFFA78BFA),
            isPositive: true),
      ];
}

class MoodLabelDef {
  final String key;
  final String display;
  final String emoji;
  final Color lightBg;
  final Color lightFg;
  final Color darkBg;
  final Color darkFg;
  final bool isPositive;

  const MoodLabelDef(
    this.key,
    this.display,
    this.emoji,
    this.lightBg,
    this.lightFg, {
    required this.darkBg,
    required this.darkFg,
    required this.isPositive,
  });

  Color bg(Brightness b) => b == Brightness.light ? lightBg : darkBg;
  Color fg(Brightness b) => b == Brightness.light ? lightFg : darkFg;
}
