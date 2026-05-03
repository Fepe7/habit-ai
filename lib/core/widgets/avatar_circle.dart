import 'package:flutter/material.dart';

/// Widget reutilizable de avatar circular.
/// Muestra la foto de red si se proporciona photoUrl, con fallback a iniciales.
class AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;

  /// URL de la foto de perfil. Si es null o vacío, muestra las iniciales.
  final String? photoUrl;

  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 48,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = textColor ?? scheme.onPrimaryContainer;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.network(
            photoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _buildInitials(bg, fg),
            errorBuilder: (_, __, ___) => _buildInitials(bg, fg),
          ),
        ),
      );
    }

    return _buildInitials(bg, fg);
  }

  Widget _buildInitials(Color bg, Color fg) {
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
