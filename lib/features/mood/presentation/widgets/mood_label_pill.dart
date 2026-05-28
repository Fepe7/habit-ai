import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../mood_theme.dart';

// pill individual para una etiqueta emocional — emoji + texto + color propio
class MoodLabelPill extends StatelessWidget {
  final MoodLabelDef label;
  final bool selected;
  final VoidCallback onTap;

  const MoodLabelPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = label.bg(brightness);
    final fg = label.fg(brightness);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? bg : bg.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? fg.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label.display,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? fg : fg.withValues(alpha: 0.7),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_rounded, size: 14, color: fg)
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 200.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ],
        ),
      )
          .animate(target: selected ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 150.ms,
          ),
    );
  }
}
