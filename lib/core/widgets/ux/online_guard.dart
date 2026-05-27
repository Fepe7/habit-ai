import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';
import 'app_snackbar.dart';

/// Wrapper reutilizable para acciones que requieren conexión a internet.
/// Si el dispositivo está offline, muestra un snackbar informativo en vez
/// de ejecutar la acción.
///
/// Uso:
/// ```dart
/// OnlineGuard(
///   message: 'El asistente IA necesita conexión a internet',
///   child: ElevatedButton(
///     onPressed: () => _doSomethingOnline(),
///     child: Text('Generar'),
///   ),
/// )
/// ```
class OnlineGuard extends StatelessWidget {
  const OnlineGuard({
    super.key,
    required this.child,
    this.message = 'Esta función necesita conexión a internet',
  });

  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, online, _) {
        if (online) return child;
        // offline: interceptar onPressed envolviéndolo en un GestureDetector
        return GestureDetector(
          onTap: () => AppSnackBar.showInfo(context, message),
          behavior: HitTestBehavior.opaque,
          child: AbsorbPointer(child: child),
        );
      },
    );
  }
}
