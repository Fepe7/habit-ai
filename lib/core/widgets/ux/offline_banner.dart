import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';

/// Banner persistente que aparece en la parte superior cuando no hay conexión.
/// Se esconde automáticamente al reconectar.
/// Usa AnimatedSwitcher para la transición de entrada/salida.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, online, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: online
              ? const SizedBox.shrink(key: ValueKey('online'))
              : _BannerContent(key: const ValueKey('offline')),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sin conexión — los cambios se guardarán cuando vuelvas a conectar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
