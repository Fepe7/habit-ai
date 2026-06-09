import 'package:shared_preferences/shared_preferences.dart';

/// Persiste qué grupos de hábitos están colapsados (minimizados) por usuario,
/// para que el estado sobreviva a cambios de pantalla y reinicios de la app.
///
/// Solo se almacena la lista de IDs colapsados: por defecto un grupo está
/// expandido, así que la ausencia en la lista equivale a "expandido".
class GroupCollapseStore {
  GroupCollapseStore._();

  static String _key(String uid) => 'collapsed_groups_$uid';

  /// Devuelve el conjunto de IDs de grupos colapsados para [uid].
  static Future<Set<String>> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(uid)) ?? const <String>[]).toSet();
  }

  /// Guarda el conjunto de IDs de grupos colapsados para [uid].
  static Future<void> save(String uid, Set<String> collapsedIds) async {
    final prefs = await SharedPreferences.getInstance();
    if (collapsedIds.isEmpty) {
      await prefs.remove(_key(uid));
    } else {
      await prefs.setStringList(_key(uid), collapsedIds.toList());
    }
  }
}
