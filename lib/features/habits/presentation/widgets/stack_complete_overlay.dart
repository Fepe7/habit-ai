import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// Overlay celebratorio que aparece al completar toda una cadena de hábitos.
/// Sigue el mismo patrón que AchievementOverlay.
class StackCompleteOverlay {
  static void show(BuildContext context, {required int habitCount}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _StackCompleteBanner(
        habitCount: habitCount,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 3800), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _StackCompleteBanner extends StatelessWidget {
  final int habitCount;
  final VoidCallback onDismiss;

  const _StackCompleteBanner({
    required this.habitCount,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.streakGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.tertiary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // icono central con pulso
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 26)),
                  ),
                )
                    .animate(onComplete: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.12, 1.12),
                      duration: 700.ms,
                      curve: Curves.easeInOut,
                    )
                    .shimmer(
                      delay: 300.ms,
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡CADENA COMPLETA!',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$habitCount hábitos seguidos. ¡Imparable!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Así se construye un hábito atómico.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // chispas decorativas
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 16))
                        .animate(onComplete: (c) => c.repeat(reverse: true))
                        .fadeIn(duration: 400.ms)
                        .then(delay: 300.ms)
                        .fadeOut(duration: 400.ms),
                    const SizedBox(height: 4),
                    Text('⚡', style: TextStyle(fontSize: 14))
                        .animate(onComplete: (c) => c.repeat(reverse: true))
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .then(delay: 300.ms)
                        .fadeOut(duration: 400.ms),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: -0.4, curve: Curves.easeOutBack)
              .then(delay: 2800.ms)
              .fadeOut(duration: 450.ms)
              .slideY(begin: 0, end: -0.25),
        ),
      ),
    );
  }
}
