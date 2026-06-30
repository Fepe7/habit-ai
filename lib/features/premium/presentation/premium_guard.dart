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
    // Fase de lanzamiento gratis: las funciones marcadas se abren a todos bajo
    // cuota semanal (impuesta en backend). Al activar el plan de pago, poner
    // PremiumLimits.freeLaunchPhase=false y vuelve el gating premium.
    if (PremiumLimits.freeLaunchPhase && feature.openDuringFreeLaunch) {
      return child;
    }
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumService.instance.isPremium,
      builder: (context, isPremium, _) =>
          isPremium ? child : PremiumLockedScreen(feature: feature),
    );
  }
}
