import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// FAB circular con gradiente hero de la app.
/// Usar en todas las pantallas que necesiten un botón de acción principal.
class GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String? tooltip;

  const GradientFab({
    super.key,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fab = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: fab);
    }
    return fab;
  }
}
