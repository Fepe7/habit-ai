import 'package:flutter/material.dart';

import '../../../core/services/premium_service.dart';
import 'paywall_screen.dart';

/// Envuelve una pantalla premium: si el usuario es free muestra el paywall
/// en su lugar (también cubre deep links de push a contenido premium).
/// Reactivo: al activarse premium la pantalla real aparece sin recargar.
class PremiumGuard extends StatelessWidget {
  const PremiumGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumService.instance.isPremium,
      builder: (context, isPremium, _) =>
          isPremium ? child : const PaywallScreen(),
    );
  }
}
