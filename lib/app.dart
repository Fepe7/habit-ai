import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'l10n/app_localizations.dart';

// Para poder acceder al AuthRepository desde cualquier pantalla
// sin tener que pasarlo por constructor
class AuthProvider extends InheritedWidget {
  final AuthRepository authRepository;

  const AuthProvider({
    super.key,
    required this.authRepository,
    required super.child,
  });

  static AuthRepository of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AuthProvider>();
    assert(
      provider != null,
      'AuthProvider no encontrado en el árbol de widgets',
    );
    return provider!.authRepository;
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) => false;
}

class HabitAIApp extends StatefulWidget {
  const HabitAIApp({super.key});

  @override
  State<HabitAIApp> createState() => _HabitAIAppState();
}

class _HabitAIAppState extends State<HabitAIApp> {
  final _authRepository = AuthRepository();
  late final GoRouter _router;
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _router = createRouter(_authRepository);
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // links recibidos con la app ya en memoria (warm/hot start)
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) {
      _router.go(uri.path, extra: uri.queryParameters);
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProvider.of(context);

    return AuthProvider(
      authRepository: _authRepository,
      child: MaterialApp.router(
        title: 'HabitAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeProvider.of(context).themeMode,
        locale: localeProvider.locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        routerConfig: _router,
      ),
    );
  }
}
