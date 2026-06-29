import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/app_emoji.dart';

/// Banner flotante amber (estilo AchievementOverlay) que notifica al propietario
/// del perfil cuando alguien reacciona a uno de sus logros.
class ReactionReceivedOverlay {
  static void show(
    BuildContext context, {
    required String reactorUsername,
    required String emoji,
    int totalCount = 1,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ReactionBanner(
        reactorUsername: reactorUsername,
        emoji: emoji,
        totalCount: totalCount,
        onDismiss: () { if (entry.mounted) entry.remove(); },
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _ReactionBanner extends StatelessWidget {
  final String reactorUsername;
  final String emoji;
  final int totalCount;
  final VoidCallback onDismiss;

  const _ReactionBanner({
    required this.reactorUsername,
    required this.emoji,
    required this.totalCount,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);

    final body = totalCount == 1
        ? '@$reactorUsername reaccionó a tu perfil'
        : '$totalCount personas reaccionaron a tu perfil';

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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: amber.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: amber.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: amber.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: AppEmoji.reaction(emoji, size: 28),
                  ),
                )
                    .animate(onComplete: (c) => c.repeat(reverse: true))
                    .shimmer(
                      delay: 300.ms,
                      duration: 1200.ms,
                      color: amber.withValues(alpha: 0.3),
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Nueva reacción!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: amber,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.3, curve: Curves.easeOutBack)
              .then(delay: 2500.ms)
              .fadeOut(duration: 400.ms)
              .slideY(begin: 0, end: -0.2),
        ),
      ),
    );
  }
}
