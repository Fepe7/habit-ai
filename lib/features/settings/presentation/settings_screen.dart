import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/review_service.dart';
import '../../../services/notification_service.dart';
import '../../../l10n/app_localizations.dart';

/// Pantalla de ajustes — Editorial Vitality
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final UserRepository _userRepo;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = AuthProvider.of(context);
    final user = auth.currentUser;
    final themeProvider = ThemeProvider.of(context);
    final localeProvider = LocaleProvider.of(context);
    final s = S.of(context);

    return StreamBuilder<UserModel>(
      stream: _userRepo.watchUser(),
      builder: (context, snapshot) {
        final userData = snapshot.data;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const DrawerMenuButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.settingsTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // tarjeta de perfil con gradiente hero — toda la tarjeta lleva a editar perfil
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: GestureDetector(
                onTap: () => context.pushNamed('edit-profile'),
                child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.ambientShadow(opacity: 0.14),
                ),
                child: Row(
                  children: [
                    // avatar grande: foto o iniciales
                    _buildSettingsAvatar(
                      context,
                      photoUrl: userData?.photoUrl,
                      initials: _initials(user?.displayName, user?.email),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                                          ? FirebaseAuth.instance.currentUser!.displayName!
                                          : FirebaseAuth.instance.currentUser?.email?.split('@').first) ??
                                      s.settingsFallbackUsername,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  userData?.username?.isNotEmpty == true
                                      ? Icons.alternate_email_rounded
                                      : Icons.mail_outline_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  userData?.username?.isNotEmpty == true
                                      ? userData!.username!
                                      : (FirebaseAuth.instance.currentUser?.email ??
                                          s.settingsFallbackUsername),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 8),

            // privacidad y visibilidad — primer nivel (principio privacy-first)
            _SectionLabel(label: s.privacySectionVisibility),
            _SectionGroup(
              children: [
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: s.settingsPrivacy,
                  subtitle: s.settingsPrivacySubtitle,
                  onTap: () => context.pushNamed('privacy-settings'),
                  divider: false,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // accesos a la parte social
            _SectionLabel(label: s.settingsSectionCommunity),
            _SectionGroup(
              children: [
                _SettingsTile(
                  icon: Icons.explore_rounded,
                  title: s.settingsExploreDirectory,
                  subtitle: s.settingsExploreDirectorySubtitle,
                  onTap: () => context.pushNamed('public-profiles-feed'),
                ),
                _SettingsTile(
                  icon: Icons.people_rounded,
                  title: s.settingsFollowers,
                  subtitle: s.settingsFollowersSubtitle,
                  onTap: () => context.pushNamed('followers'),
                  divider: false,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // apariencia
            _SectionLabel(label: s.settingsSectionAppearance),
            _SectionGroup(
              children: [
                _ThemeTile(
                  currentMode: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // idioma
            _SectionLabel(label: s.settingsSectionLanguage),
            _SectionGroup(
              children: [
                _LanguageTile(
                  currentLocale: localeProvider.locale,
                  onChanged: (locale) => localeProvider.setLocale(locale),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // general
            _SectionLabel(label: s.settingsSectionGeneral),
            _SectionGroup(
              children: [
                _SettingsTile(
                  icon: Icons.emoji_events_rounded,
                  title: s.settingsAchievements,
                  subtitle: s.settingsAchievementsSubtitle,
                  onTap: () => context.goNamed('achievements'),
                ),
                const _NotificationsTile(),
              ],
            ),

            const SizedBox(height: 12),

            // protección de racha: escudos y modo enfermedad (feature de juego, antes que info/legal)
            _SectionLabel(label: s.settingsSectionStreakProtection),
            _SectionGroup(
              children: [
                _ShieldCountTile(shieldsCount: userData?.shieldsCount ?? 0),
                _SickModeTile(
                  userData: userData,
                  userRepo: _userRepo,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // información
            _SectionLabel(label: s.settingsSectionInfo),
            _SectionGroup(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: s.settingsAbout,
                  subtitle: s.settingsAboutSubtitle,
                  onTap: () => _showAbout(context),
                ),
                _SettingsTile(
                  icon: Icons.star_rounded,
                  title: s.settingsRateApp,
                  subtitle: s.settingsRateAppSubtitle,
                  onTap: () async {
                    await FeedbackService.instance.moodSelected();
                    await ReviewService.instance.openStoreListing();
                  },
                  divider: false,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // legal
            _SectionLabel(label: s.settingsSectionLegal),
            _SectionGroup(
              children: [
                _SettingsTile(
                  icon: Icons.policy_outlined,
                  title: s.settingsPrivacyPolicy,
                  subtitle: s.settingsPrivacyPolicySubtitle,
                  onTap: () => launchUrl(
                    Uri.parse('https://habit-ai-184ad.web.app/privacy.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: s.settingsTerms,
                  subtitle: s.settingsTermsSubtitle,
                  onTap: () => launchUrl(
                    Uri.parse('https://habit-ai-184ad.web.app/terms.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                  divider: false,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // cerrar sesión en su propio grupo con color de error
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.ambientShadow(),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: s.settingsSignOut,
                      subtitle: null,
                      isDestructive: true,
                      onTap: () => _confirmSignOut(context, auth),
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      title: s.settingsDeleteAccount,
                      subtitle: s.settingsDeleteAccountSubtitle,
                      isDestructive: true,
                      onTap: () => _confirmDeleteAccount(context, auth),
                      divider: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    }, // StreamBuilder builder
    ); // StreamBuilder
  }

  Widget _buildSettingsAvatar(
    BuildContext context, {
    required String? photoUrl,
    required String initials,
  }) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return SizedBox(
        width: 64,
        height: 64,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _buildInitialsAvatar(context, initials),
          ),
        ),
      );
    }
    return _buildInitialsAvatar(context, initials);
  }

  Widget _buildInitialsAvatar(BuildContext context, String initials) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  String _initials(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  void _confirmSignOut(BuildContext context, dynamic auth) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.settingsSignOutConfirmTitle),
        content: Text(s.settingsSignOutConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(s.settingsSignOut),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, dynamic auth) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.settingsDeleteAccount),
        content: Text(s.settingsDeleteAccountConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // segunda confirmación: escribir ELIMINAR
    final typed = await showDialog<String>(
      context: context, // ignore: use_build_context_synchronously
      builder: (_) => const _ConfirmDeleteDialog(),
    );
    if (typed != 'ELIMINAR' || !mounted) return;

    // mostrar loading
    showDialog(
      context: context, // ignore: use_build_context_synchronously
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await auth.deleteAccount();
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // ignore: use_build_context_synchronously
      if (mounted) {
        AppSnackBar.showError(
          context, // ignore: use_build_context_synchronously
          e.toString().contains('requires-recent-login')
              ? s.settingsDeleteRequiresRelogin
              : s.settingsDeleteAccountError(e.toString()),
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: S.of(context).appTitle,
      applicationVersion: '1.0.0',
      applicationLegalese: 'Trabajo Final de Grado — 2º DAM\nAndrei Felipe Staicu',
    );
  }
}

// ==================== WIDGETS ====================

/// Etiqueta de sección tipo Manrope headline
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Contenedor de grupo de tiles sin divisores visuales duros
class _SectionGroup extends StatelessWidget {
  final List<Widget> children;
  const _SectionGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.ambientShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

/// Tile genérico de ajustes con separador opcional
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool divider;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurface;
    final iconColor = isDestructive ? scheme.error : scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDestructive
                  ? scheme.errorContainer.withValues(alpha: 0.3)
                  : scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          trailing: isDestructive
              ? null
              : Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
          onTap: onTap,
        ),
        if (divider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 0,
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
      ],
    );
  }
}

/// Selector de tema con SegmentedButton
class _ThemeTile extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeTile({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.palette_outlined, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.settingsThemeLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selectedBackgroundColor:
                        scheme.primaryContainer.withValues(alpha: 0.3),
                    selectedForegroundColor: scheme.primary,
                  ),
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined, size: 16),
                      label: Text(s.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.phone_android_outlined, size: 16),
                      label: Text(s.themeAuto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined, size: 16),
                      label: Text(s.themeDark),
                    ),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (s) => onChanged(s.first),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de idioma con SegmentedButton — mismo estilo que _ThemeTile
class _LanguageTile extends StatelessWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale?> onChanged;

  const _LanguageTile({required this.currentLocale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    // null = idioma del dispositivo; lo mostramos como español si no hay nada
    final selectedCode = currentLocale?.languageCode ?? 'es';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.language_rounded, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.settingsSectionLanguage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selectedBackgroundColor:
                        scheme.primaryContainer.withValues(alpha: 0.3),
                    selectedForegroundColor: scheme.primary,
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'es',
                      label: Text(s.languageEs),
                    ),
                    ButtonSegment(
                      value: 'en',
                      label: Text(s.languageEn),
                    ),
                  ],
                  selected: {selectedCode},
                  onSelectionChanged: (sel) {
                    onChanged(Locale(sel.first));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile que muestra los escudos disponibles con tooltip explicativo
class _ShieldCountTile extends StatelessWidget {
  final int shieldsCount;
  const _ShieldCountTile({required this.shieldsCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    // puntos visuales: hasta 5 escudos
    final shields = List.generate(
      5,
      (i) => Icon(
        i < shieldsCount ? Icons.shield_rounded : Icons.shield_outlined,
        size: 18,
        color: i < shieldsCount
            ? scheme.primary
            : scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );

    return Tooltip(
      message: s.settingsShieldsTooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shield_rounded, size: 18, color: scheme.primary),
            ),
            title: Text(
              s.settingsShieldsTile,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              s.settingsShieldsCount(shieldsCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: shields,
            ),
          ),
          Divider(
            height: 1,
            indent: 70,
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

/// Tile con switch para activar/desactivar todas las notificaciones locales
class _NotificationsTile extends StatefulWidget {
  const _NotificationsTile();

  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await NotificationService.instance.isEnabled();
    if (mounted) setState(() { _enabled = v; _loading = false; });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    try {
      if (value) {
        // al activar, pedimos permiso del SO. si lo deniega, no guardamos
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted) {
          if (mounted) {
            AppSnackBar.showInfo(context,
                S.of(context).settingsNotificationsSystemPrompt); // ignore: use_build_context_synchronously
          }
          return;
        }
        await NotificationService.instance.setEnabled(true);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final repo = HabitRepository(uid: uid);
          final habits = await repo.getActiveHabits();
          await NotificationService.instance.rescheduleAll(habits);
        }
      } else {
        await NotificationService.instance.setEnabled(false);
        await NotificationService.instance.cancelAll();
      }
      if (mounted) setState(() => _enabled = value);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.notifications_outlined, size: 18, color: scheme.primary),
      ),
      title: Text(
        s.settingsNotifications,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _enabled ? s.settingsNotificationsEnabled : s.settingsNotificationsDisabled,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _enabled,
              onChanged: _toggle,
            ),
    );
  }
}

/// Tile para activar/desactivar el modo enfermedad
class _SickModeTile extends StatefulWidget {
  final UserModel? userData;
  final UserRepository userRepo;

  const _SickModeTile({required this.userData, required this.userRepo});

  @override
  State<_SickModeTile> createState() => _SickModeTileState();
}

class _SickModeTileState extends State<_SickModeTile> {
  bool _loading = false;

  bool get _isActive {
    final until = widget.userData?.sickModeUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  String _subtitle(BuildContext context) {
    final s = S.of(context);
    if (_isActive) {
      final until = widget.userData!.sickModeUntil!;
      final diff = until.difference(DateTime.now()).inDays + 1;
      return s.settingsSickModeActive(diff);
    }
    return s.settingsSickModeSubtitle;
  }

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      if (_isActive) {
        await widget.userRepo.cancelSickMode();
      } else {
        // mostrar selector de días
        if (!mounted) return;
        final days = await _showDaysPicker(context);
        if (days == null) {
          setState(() => _loading = false);
          return;
        }
        await widget.userRepo.activateSickMode(days);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int?> _showDaysPicker(BuildContext context) async {
    final s = S.of(context);
    int selectedDays = 1;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(s.settingsSickModeDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.settingsSickModeDialogContent),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('${s.days}: '),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: selectedDays.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: s.daysLabel(selectedDays),
                      onChanged: (v) =>
                          setDlg(() => selectedDays = v.round()),
                    ),
                  ),
                  Text('$selectedDays'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(selectedDays),
              child: Text(s.activate),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.medical_services_outlined,
            size: 18, color: scheme.primary),
      ),
      title: Text(
        S.of(context).settingsSickMode,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _subtitle(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _isActive,
              onChanged: (_) => _toggle(),
            ),
    );
  }
}

class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    // la palabra clave "ELIMINAR" es intencional y no se localiza:
    // actúa como barrera de seguridad invariante
    _controller.addListener(
      () => setState(() => _matches = _controller.text.trim() == 'ELIMINAR'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.settingsDeleteConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.settingsDeleteConfirmPrompt,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'ELIMINAR',
              hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _matches ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(s.settingsDeleteAccount),
        ),
      ],
    );
  }
}
