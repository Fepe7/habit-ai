import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Etiqueta de sección suelta (uppercase) — usada por la pantalla de privacidad,
/// donde los grupos no llevan cabecera interna.
class SettingsSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const SettingsSectionLabel({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? scheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de sección de ajustes al estilo "Editorial Vitality":
/// cabecera interna con icono en chip de color + título grande, separador
/// sutil, y debajo las filas. Reemplaza al patrón etiqueta-fuera + grupo.
class SettingsSectionCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = iconColor ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.ambientShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.12),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Fila de ajustes sin icono propio (el icono representativo vive en la
/// cabecera de la sección). Soporta subtítulo, control a la derecha (switch,
/// chips…) o chevron por defecto, y estilo destructivo con icono a la izquierda.
class SettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool divider;
  final bool isDestructive;
  final IconData? destructiveIcon;

  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.divider = true,
    this.isDestructive = false,
    this.destructiveIcon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = isDestructive ? scheme.error : scheme.onSurface;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          if (isDestructive && destructiveIcon != null) ...[
            Icon(destructiveIcon, size: 22, color: scheme.error),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDestructive
                                  ? scheme.error.withValues(alpha: 0.7)
                                  : scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          trailing ??
              (onTap != null && !isDestructive
                  ? Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 20,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: onTap != null,
          label: title,
          hint: subtitle,
          child: onTap != null
              ? InkWell(onTap: onTap, child: row)
              : row,
        ),
        if (divider)
          Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: scheme.outlineVariant.withValues(alpha: 0.10),
          ),
      ],
    );
  }
}
