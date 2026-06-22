import 'package:flutter/material.dart';

import '../../../core/services/premium_service.dart';
import 'premium_locked_screen.dart';

export 'premium_locked_screen.dart' show PremiumFeature;

/// Envuelve una pantalla premium: si el usuario es free muestra la versión
/// "bloqueada" (teaser difuminado + candado + CTA) en su lugar, contextual a
/// la función ([feature]). También cubre deep links de push a contenido
/// premium. Reactivo: al activarse premium la pantalla real aparece sin
/// recargar.
class PremiumGuard extends StatelessWidget {
  const PremiumGuard({super.key, required this.child, required this.feature});

  final Widget child;
  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumService.instance.isPremium,
      builder: (context, isPremium, _) =>
          isPremium ? child : PremiumLockedScreen(feature: feature),
    );
  }
}
