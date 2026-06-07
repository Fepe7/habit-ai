import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AvatarBadge { none, camera, verified }

/// Widget reutilizable de avatar circular.
/// Muestra la foto de red si se proporciona photoUrl, con fallback a iniciales.
/// [badge] muestra un indicador en la esquina inferior-derecha:
///   - [AvatarBadge.camera]: botón de editar foto (círculo primario con icono cámara)
///   - [AvatarBadge.verified]: check de perfil público
///   - [AvatarBadge.none]: sin badge
/// [ringGradient] envuelve el avatar en un anillo con el gradiente hero de la marca.
class AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final String? photoUrl;
  final AvatarBadge badge;
  final bool ringGradient;

  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 48,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.photoUrl,
    this.badge = AvatarBadge.none,
    this.ringGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = textColor ?? scheme.onPrimaryContainer;

    Widget avatar = _buildCore(bg, fg);

    if (ringGradient) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppTheme.primaryContainer, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface,
          ),
          child: avatar,
        ),
      );
    }

    if (badge == AvatarBadge.none) return avatar;

    final badgeSize = size * 0.30;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: badge == AvatarBadge.camera
              ? Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: badgeSize * 0.55,
                    color: scheme.onPrimary,
                  ),
                )
              : Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: badgeSize * 0.55,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCore(Color bg, Color fg) {
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
