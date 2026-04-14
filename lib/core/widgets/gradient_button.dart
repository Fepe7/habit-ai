import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Boton primario con gradiente hero (primary -> primaryContainer)
/// Usa estilo pill + sombra ambiente en estado activo
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height = 56,
    this.gradient,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double height;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final g = gradient ?? AppTheme.heroGradient;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(height),
            boxShadow: enabled ? AppTheme.ambientShadow(opacity: 0.12) : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(height),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
