import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Etiqueta de sección — uppercase, spacing 1.2, onSurfaceVariant.
/// Usada en settings y privacy para consistencia visual.
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

/// Contenedor de grupo de tiles con radio 20 + ambient shadow.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.ambientShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

/// Tile genérico de ajustes con Semantics, touch target ≥48dp y separador opcional.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool divider;
  final Widget? trailing;
  final Color? iconBgColor;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.divider = true,
    this.trailing,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurface;
    final effectiveIconColor = iconColor ??
        (isDestructive ? scheme.error : scheme.primary);
    final effectiveIconBg = iconBgColor ??
        (isDestructive
            ? scheme.errorContainer.withValues(alpha: 0.3)
            : scheme.primaryContainer.withValues(alpha: 0.2));

    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: effectiveIconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing ??
                      (isDestructive
                          ? const SizedBox.shrink()
                          : Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                              size: 20,
                            )),
                ],
              ),
            ),
          ),
          if (divider)
            Divider(
              height: 1,
              indent: 72,
              endIndent: 0,
              color: scheme.outlineVariant.withValues(alpha: 0.12),
            ),
        ],
      ),
    );
  }
}
