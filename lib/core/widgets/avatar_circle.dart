import 'package:flutter/material.dart';

/// Widget reutilizable de avatar con iniciales.
/// Extraído de SettingsScreen para usarlo en perfiles públicos también.
class AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;

  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 48,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = textColor ?? scheme.onPrimaryContainer;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: textStyle ??
              TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.38,
              ),
        ),
      ),
    );
  }

  /// Calcula las iniciales desde un nombre o email
  static String fromName(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }
}
