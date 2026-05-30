import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateStatus { none, soft, force }

/// Compara la versión instalada con los umbrales de Remote Config.
///
/// Parámetros esperados en Remote Config:
///   min_version     (string) — por debajo → force update
///   latest_version  (string) — por debajo → soft update (aviso)
///   update_message  (string) — texto del diálogo
///   store_url       (string) — URL de la ficha en Play Store
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const _storeUrlFallback =
      'https://play.google.com/store/apps/details?id=com.habitai.habitai';

  late FirebaseRemoteConfig _rc;

  Future<void> init() async {
    _rc = FirebaseRemoteConfig.instance;
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _rc.setDefaults({
      'min_version': '1.0.0',
      'latest_version': '1.0.0',
      'update_message': 'Hay una nueva versión disponible con mejoras importantes.',
      'store_url': _storeUrlFallback,
    });
    try {
      await _rc.fetchAndActivate();
    } catch (_) {
      // offline o error de red: usar defaults, no bloquear
    }
  }

  Future<UpdateStatus> checkStatus() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final installed = info.version; // ej. "1.0.0"
      final minVersion = _rc.getString('min_version');
      final latestVersion = _rc.getString('latest_version');

      if (_isBelow(installed, minVersion)) return UpdateStatus.force;
      if (_isBelow(installed, latestVersion)) return UpdateStatus.soft;
    } catch (_) {
      // fail-open
    }
    return UpdateStatus.none;
  }

  String get updateMessage => _rc.getString('update_message');
  String get storeUrl {
    final url = _rc.getString('store_url');
    return url.isNotEmpty ? url : _storeUrlFallback;
  }

  /// Devuelve true si [installed] < [threshold] (comparación semver simple).
  bool _isBelow(String installed, String threshold) {
    final a = _parts(installed);
    final b = _parts(threshold);
    for (var i = 0; i < 3; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return false;
  }

  List<int> _parts(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}
