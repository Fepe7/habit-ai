import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../mood_theme.dart';

// selector de ánimo con 5 emojis, colores por mood y glow al seleccionar
class MoodEmojiSelector extends StatelessWidget {
  final int? selectedRating;
  final ValueChanged<int> onRatingChanged;
  final double emojiSize;

  const MoodEmojiSelector({
    super.key,
    required this.selectedRating,
    required this.onRatingChanged,
    this.emojiSize = 52,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final s = S.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final rating = i + 1;
            final selected = selectedRating == rating;
            final dimmed = selectedRating != null && !selected;

            return _EmojiCircle(
              emoji: MoodTheme.emojis[i],
              rating: rating,
              selected: selected,
              dimmed: dimmed,
              size: emojiSize,
              brightness: brightness,
              onTap: () {
                FeedbackService.instance.moodSelected();
                onRatingChanged(rating);
              },
            );
          }),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: selectedRating != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    MoodTheme.ratingLabel(selectedRating!, s),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: MoodTheme.ratingAccent(
                              selectedRating!, brightness),
                        ),
                  )
                      .animate(key: ValueKey(selectedRating))
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: 0.3, duration: 200.ms),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _EmojiCircle extends StatelessWidget {
  final String emoji;
  final int rating;
  final bool selected;
  final bool dimmed;
  final double size;
  final Brightness brightness;
  final VoidCallback onTap;

  const _EmojiCircle({
    required this.emoji,
    required this.rating,
    required this.selected,
    required this.dimmed,
    required this.size,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = MoodTheme.ratingBg(rating, brightness);
    final accent = MoodTheme.ratingAccent(rating, brightness);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dimmed ? 0.35 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: selected ? size * 1.2 : size,
          height: selected ? size * 1.2 : size,
          decoration: BoxDecoration(
            color: selected ? bg : bg.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: selected ? size * 0.55 : size * 0.48),
              child: Text(emoji),
            ),
          ),
        ),
      ),
    );
  }
}
