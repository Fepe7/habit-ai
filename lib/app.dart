import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/router/app_router.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/widgets/ux/update_dialog.dart';
import 'services/push_notification_service.dart';
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
    // Permite que los push (FCM) y las notificaciones locales naveguen al tocarse.
    PushNotificationService.instance.attachRouter((route) => _router.go(route));
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  void _initDeepLinks() {
    // links recibidos con la app ya en memoria (warm/hot start)
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) {
      _router.go(uri.path, extra: uri.queryParameters);
    });
  }

  static const _softShownPrefKey = 'update_soft_shown_for_version';

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    final status = await UpdateService.instance.checkStatus();
    if (!mounted || status == UpdateStatus.none) return;

    if (status == UpdateStatus.soft) {
      // mostrar aviso soft máximo una vez por versión instalada
      final info = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      final shownFor = prefs.getString(_softShownPrefKey) ?? '';
      if (shownFor == info.version) return;
      await prefs.setString(_softShownPrefKey, info.version);
    }

    if (mounted) {
      await showUpdateDialogIfNeeded(context, status); // ignore: use_build_context_synchronously
    }
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
