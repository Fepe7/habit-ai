import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/achivement_model.dart';

// Muestra un banner celebratorio cuando se desbloquea un logro
class AchievementOverlay {
  // mostrar notificacion para cada logro desbloqueado
  static void showUnlocked(BuildContext context, List<String> types) {
    for (int i = 0; i < types.length; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (!context.mounted) return;
        _showBanner(context, types[i]);
      });
    }
  }

  static void _showBanner(BuildContext context, String type) {
    final info = AchievementCatalog.getInfo(type);
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AchievementBanner(
        info: info,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // se quita solo despues de la animacion
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _AchievementBanner extends StatelessWidget {
  final AchievementInfo info;
  final VoidCallback onDismiss;

  const _AchievementBanner({
    required this.info,
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: info.color.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: info.color.withValues(alpha: 0.2),
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
                // icono con brillo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: info.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(info.icon, color: info.color, size: 26),
                )
                    .animate(onComplete: (c) => c.repeat(reverse: true))
                    .shimmer(
                      delay: 300.ms,
                      duration: 1200.ms,
                      color: info.color.withValues(alpha: 0.3),
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Logro desbloqueado!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: info.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.title,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        info.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
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
