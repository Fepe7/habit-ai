import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Gestiona el tema (claro/oscuro/sistema) y lo persiste en SharedPreferences
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  // Para acceder desde cualquier parte del arbol
  static ThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeInherited>()!.provider;
  }
}

// InheritedWidget que expone el ThemeProvider
class ThemeScope extends StatefulWidget {
  final Widget child;

  const ThemeScope({super.key, required this.child});

  @override
  State<ThemeScope> createState() => _ThemeScopeState();
}

class _ThemeScopeState extends State<ThemeScope> {
  final _provider = ThemeProvider();

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        return _ThemeInherited(
          provider: _provider,
          child: widget.child,
        );
      },
    );
  }
}

class _ThemeInherited extends InheritedWidget {
  final ThemeProvider provider;

  const _ThemeInherited({
    required this.provider,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ThemeInherited oldWidget) {
    return provider.themeMode != oldWidget.provider.themeMode;
  }
}
