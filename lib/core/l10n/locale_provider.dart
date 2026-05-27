import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Gestiona el idioma de la app y lo persiste en SharedPreferences + Firestore
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';

  // null = usar idioma del dispositivo
  Locale? _locale;

  Locale? get locale => _locale;

  // Código de locale actual accesible sin context — útil en capas data
  // Se actualiza cada vez que cambia el locale (o al arrancar desde SharedPrefs)
  static String currentCode = 'es';

  LocaleProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      _locale = Locale(value);
      currentCode = value;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    currentCode = locale?.languageCode ?? 'es';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
      // sincronizar con Firestore para que Cloud Functions use el idioma correcto
      _syncLocaleToFirestore(locale.languageCode);
    }
  }

  // escribe el locale al perfil del usuario en Firestore (best-effort, sin await)
  void _syncLocaleToFirestore(String languageCode) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'locale': languageCode})
        .ignore();
  }

  // para acceder desde cualquier parte del árbol
  static LocaleProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LocaleInherited>()!.provider;
  }
}

// InheritedWidget que expone el LocaleProvider
class LocaleScope extends StatefulWidget {
  final Widget child;

  const LocaleScope({super.key, required this.child});

  @override
  State<LocaleScope> createState() => _LocaleScopeState();
}

class _LocaleScopeState extends State<LocaleScope> {
  final _provider = LocaleProvider();

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
        return _LocaleInherited(
          provider: _provider,
          child: widget.child,
        );
      },
    );
  }
}

class _LocaleInherited extends InheritedWidget {
  final LocaleProvider provider;

  const _LocaleInherited({
    required this.provider,
    required super.child,
  });

  // siempre true: ListenableBuilder ya controla cuándo rebuildar
  @override
  bool updateShouldNotify(_LocaleInherited oldWidget) => true;
}
