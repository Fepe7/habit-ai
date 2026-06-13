import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/spark_check_logo.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_error_l10n.dart';

// Pantalla de login — diseño Editorial Vitality
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // soltar el foco para que el teclado se cierre antes de navegar;
    // si no, queda colgado sobre la pantalla destino tras el login
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = AuthProvider.of(context);
      await authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      AnalyticsService.instance.logLogin('email');
    } catch (e) {
      if (isAuthCancelled(e) || !mounted) return;
      setState(() => _errorMessage = authErrorMessage(S.of(context), e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Restablecer contraseña: pide el email en un diálogo y delega en
  // Firebase Auth (envía el correo gratis con la plantilla de la consola).
  // El mensaje de éxito es genérico a propósito: no revela si la cuenta existe.
  Future<void> _handleForgotPassword() async {
    final s = S.of(context);

    // el diálogo posee su propio controller (no se puede hacer dispose aquí:
    // la animación de cierre del diálogo aún depende de él)
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
      ),
    );

    if (email == null || !mounted) return;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.authForgotPasswordInvalid)),
      );
      return;
    }

    try {
      await AuthProvider.of(context).sendPasswordResetEmail(email);
    } catch (_) {
      // silenciar a propósito: mismo mensaje exista o no la cuenta
      // (Firebase ya protege contra enumeración de emails por defecto)
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.authForgotPasswordSent)),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = AuthProvider.of(context);
      await authRepository.signInWithGoogle();
      AnalyticsService.instance.logLogin('google');
    } catch (e) {
      if (isAuthCancelled(e) || !mounted) return;
      setState(() => _errorMessage = authErrorMessage(S.of(context), e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = AuthProvider.of(context);
      await authRepository.signInWithApple();
      AnalyticsService.instance.logLogin('apple');
    } catch (e) {
      if (isAuthCancelled(e) || !mounted) return;
      setState(() => _errorMessage = authErrorMessage(S.of(context), e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Sign in with Apple solo se ofrece en plataformas Apple (requisito y soporte nativo).
  bool get _showAppleButton =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // hero — icono con glow en surface container
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.ambientShadow(opacity: 0.18),
                    ),
                    child: const SparkCheckLogo(size: 56, mono: true),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 28),

                Text(
                  s.appTitle,
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  s.authTagline,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                const SizedBox(height: 48),

                // campo email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: s.authEmail,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return s.authEmailHint;
                    }
                    if (!value.contains('@')) {
                      return s.authEmailInvalid;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                const SizedBox(height: 16),

                // campo contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: s.authPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return s.authPasswordHint;
                    }
                    if (value.length < 6) {
                      return s.authPasswordMin;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                // enlace de recuperación de contraseña
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    child: Text(
                      s.authForgotPassword,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                const SizedBox(height: 12),

                // error
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 20, color: colorScheme.onErrorContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(hz: 3, offset: const Offset(4, 0)),

                // botón login con gradiente
                GradientButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  label: s.authSignIn,
                  loading: _isLoading,
                ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                const SizedBox(height: 24),

                // separador "o"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        s.authOrSeparator,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        thickness: 1,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                const SizedBox(height: 24),

                // botón Apple — solo en iOS/macOS, por encima de Google
                if (_showAppleButton) ...[
                  _AppleButton(
                    onPressed: _isLoading ? null : _handleAppleSignIn,
                  ).animate().fadeIn(delay: 640.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                ],

                // botón Google — outlined sin borde duro
                _GoogleButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
                const SizedBox(height: 20),

                // link registro
                TextButton(
                  onPressed: _isLoading ? null : () => context.goNamed('register'),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(text: s.authNoAccount),
                        TextSpan(
                          text: s.authRegisterLink,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 750.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Botón Google con fondo surface y ghost border
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(56),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: AppTheme.ambientShadow(opacity: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleLogo(),
            const SizedBox(width: 12),
            Text(
              S.of(context)!.authContinueWithGoogle,
              style: textTheme.titleSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Botón Apple — negro con el glifo de Apple (HIG). Solo se muestra en iOS/macOS,
// donde el glifo  (U+F8FF) se renderiza con la fuente del sistema.
class _AppleButton extends StatelessWidget {
  const _AppleButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(56),
          boxShadow: AppTheme.ambientShadow(opacity: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              S.of(context)!.authContinueWithApple,
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Logo simple de Google (G azul) — sin assets externos
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

/// Diálogo de recuperación de contraseña. Posee su TextEditingController
/// para que se libere con el ciclo de vida del diálogo (hacer dispose desde
/// fuera rompe la animación de cierre: el campo aún depende del controller).
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return AlertDialog(
      title: Text(s.authForgotPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.authForgotPasswordBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
            decoration: InputDecoration(
              labelText: s.authEmail,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(s.authForgotPasswordSend),
        ),
      ],
    );
  }
}
