import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _emojis = ['😞', '😕', '😐', '🙂', '😄'];

// Selector de ánimo con 5 emojis (rating 1-5)
class MoodEmojiSelector extends StatelessWidget {
  final int? selectedRating;
  final ValueChanged<int> onRatingChanged;

  const MoodEmojiSelector({
    super.key,
    required this.selectedRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final rating = i + 1;
        final selected = selectedRating == rating;

        return GestureDetector(
          onTap: () => onRatingChanged(rating),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _emojis[i],
                style: TextStyle(fontSize: selected ? 32 : 26),
              ),
            ),
          )
              .animate(target: selected ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),
        );
      }),
    );
  }
}
