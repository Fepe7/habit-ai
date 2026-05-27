import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../social/data/user_directory_repository.dart';
import '../../../l10n/app_localizations.dart';

// Pantalla de registro — diseño Editorial Vitality
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  // null = sin comprobar, true = disponible, false = ocupado
  bool? _usernameAvailable;
  bool _checkingUsername = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String value) async {
    if (!UserDirectoryRepository.isValidUsername(value)) {
      setState(() {
        _usernameAvailable = null;
        _checkingUsername = false;
      });
      return;
    }
    setState(() => _checkingUsername = true);
    // instancia temporal sin uid para solo validar disponibilidad
    final repo = UserDirectoryRepository(uid: 'tmp');
    final available = await repo.isUsernameAvailable(value);
    if (mounted) {
      setState(() {
        _usernameAvailable = available;
        _checkingUsername = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameAvailable != true) {
      setState(() => _errorMessage = S.of(context)!.authUsernameRequiredFull);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = AuthProvider.of(context);
      final name = _nameController.text.trim();
      final user = await authRepository.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: name.isNotEmpty ? name : null,
      );

      // reclamar username en /user_directory y /usernames
      final dirRepo = UserDirectoryRepository(uid: user.uid);
      await dirRepo.claimUsername(
        username: _usernameController.text.trim(),
        displayName: name.isNotEmpty ? name : _emailController.text.split('@').first,
        photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
      );
      AnalyticsService.instance.logSignUp('email');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = AuthProvider.of(context);
      await authRepository.signInWithGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // hero — icono con gradiente
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.ambientShadow(opacity: 0.08),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 38,
                      color: colorScheme.primary,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),

                Text(
                  s.authRegisterTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  s.authRegisterTagline,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 40),

                // email
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
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 16),

                // nombre real — aparece en el perfil y como identidad visible
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: s.authName,
                    hintText: s.authNameHint,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return s.authNameRequired;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 325.ms, duration: 400.ms),
                const SizedBox(height: 16),

                // username — obligatorio para ser buscable por amigos y retos
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  onChanged: (v) => _checkUsername(v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    labelText: s.authUsername,
                    prefixText: '@',
                    hintText: s.authUsernameHint,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    suffixIcon: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameAvailable == true
                            ? const Icon(Icons.check_circle_rounded,
                                color: Colors.green)
                            : _usernameAvailable == false
                                ? Icon(Icons.error_outline_rounded,
                                    color: colorScheme.error)
                                : null,
                    helperText: _usernameAvailable == true
                        ? s.authUsernameAvailable
                        : _usernameAvailable == false
                            ? s.authUsernameTaken
                            : s.authUsernameHelp,
                    helperStyle: TextStyle(
                      color: _usernameAvailable == true
                          ? Colors.green
                          : _usernameAvailable == false
                              ? colorScheme.error
                              : null,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return s.authUsernameRequired;
                    }
                    if (!UserDirectoryRepository.isValidUsername(
                        value.trim())) {
                      return s.authUsernameFormat;
                    }
                    if (_usernameAvailable != true) {
                      return s.authUsernameCheckFirst;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 375.ms, duration: 400.ms),
                const SizedBox(height: 16),

                // contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
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
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 16),

                // confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    labelText: s.authPasswordConfirm,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return s.authPasswordMismatch;
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                const SizedBox(height: 28),

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

                // botón registro con gradiente
                GradientButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  label: s.authRegisterTitle,
                  loading: _isLoading,
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
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
                ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
                const SizedBox(height: 24),

                // botón Google
                _GoogleButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                const SizedBox(height: 20),

                // texto legal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: s.authPrivacyPrefix),
                        TextSpan(
                          text: s.authPrivacyPolicy,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(
                                  Uri.parse('https://habit-ai-184ad.web.app/privacy.html'),
                                  mode: LaunchMode.externalApplication,
                                ),
                        ),
                        TextSpan(text: s.authPrivacyMiddle),
                        TextSpan(
                          text: s.authTermsOfUse,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(
                                  Uri.parse('https://habit-ai-184ad.web.app/terms.html'),
                                  mode: LaunchMode.externalApplication,
                                ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 725.ms, duration: 400.ms),
                const SizedBox(height: 12),

                // link login
                TextButton(
                  onPressed: _isLoading ? null : () => context.goNamed('login'),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(text: s.authHaveAccount),
                        TextSpan(
                          text: s.authSignInLink,
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
