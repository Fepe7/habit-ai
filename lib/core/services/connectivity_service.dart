import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton que expone el estado de conexión a red.
/// Usa ValueNotifier para que los widgets puedan escuchar cambios reactivamente.
/// Firestore ya tiene persistencia offline, así que solo necesitamos detectar
/// "sin red" para comunicárselo al usuario y proteger las llamadas a IA.
class ConnectivityService {
  ConnectivityService._();
  static final instance = ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Inicializar: check inicial + escuchar cambios.
  /// Llamar desde main() antes de runApp.
  Future<void> init() async {
    final results = await Connectivity().checkConnectivity();
    isOnline.value = _isConnected(results);

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = _isConnected(results);
    });
  }

  /// Liberar recursos (raramente necesario en apps móviles).
  void dispose() {
    _sub?.cancel();
    isOnline.dispose();
  }

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
