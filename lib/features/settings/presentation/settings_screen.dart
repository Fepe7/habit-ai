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
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/review_service.dart';
import '../../../services/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

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
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      const DrawerMenuButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.settingsTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tarjeta de cuenta (gradiente hero) ──────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: _AccountHeroCard(
                    userData: userData,
                    onTap: () => context.pushNamed('edit-profile'),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

                const SizedBox(height: 24),

                // ── 1. Privacidad y visibilidad ──────────────────────────
                SettingsSectionCard(
                  icon: Icons.shield_outlined,
                  title: s.privacySectionVisibility,
                  children: [
                    SettingsRow(
                      title: s.settingsPrivacy,
                      subtitle: s.settingsPrivacySubtitle,
                      onTap: () => context.pushNamed('privacy-settings'),
                      divider: false,
                    ),
                  ],
                ).animate().fadeIn(delay: 40.ms, duration: 260.ms),

                const SizedBox(height: 16),

                // ── 2. Preferencias (tema + idioma + notificaciones) ─────
                SettingsSectionCard(
                  icon: Icons.tune_rounded,
                  title: s.settingsSectionAppearance,
                  children: [
                    _ThemeRow(
                      currentMode: themeProvider.themeMode,
                      onChanged: (mode) => themeProvider.setThemeMode(mode),
                    ),
                    _LanguageRow(
                      currentLocale: localeProvider.locale,
                      onChanged: (locale) => localeProvider.setLocale(locale),
                    ),
                    const _NotificationsRow(),
                  ],
                ).animate().fadeIn(delay: 80.ms, duration: 260.ms),

                const SizedBox(height: 16),

                // ── 3. Tu progreso (logros + protección de racha) ────────
                SettingsSectionCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppTheme.tertiaryContainer,
                  title: s.settingsSectionStreakProtection,
                  children: [
                    SettingsRow(
                      title: s.settingsAchievements,
                      subtitle: s.settingsAchievementsSubtitle,
                      onTap: () => context.pushNamed('achievements'),
                    ),
                    _ShieldRow(shieldsCount: userData?.shieldsCount ?? 0),
                    _SickModeRow(userData: userData, userRepo: _userRepo),
                  ],
                ).animate().fadeIn(delay: 120.ms, duration: 260.ms),

                const SizedBox(height: 16),

                // ── 4. Comunidad ─────────────────────────────────────────
                SettingsSectionCard(
                  icon: Icons.people_outline_rounded,
                  title: s.settingsSectionCommunity,
                  children: [
                    SettingsRow(
                      title: s.settingsExploreDirectory,
                      subtitle: s.settingsExploreDirectorySubtitle,
                      onTap: () => context.pushNamed('public-profiles-feed'),
                    ),
                    SettingsRow(
                      title: s.settingsFollowers,
                      subtitle: s.settingsFollowersSubtitle,
                      onTap: () => context.pushNamed('followers'),
                      divider: false,
                    ),
                  ],
                ).animate().fadeIn(delay: 160.ms, duration: 260.ms),

                const SizedBox(height: 16),

                // ── 5. Información ───────────────────────────────────────
                SettingsSectionCard(
                  icon: Icons.info_outline_rounded,
                  iconColor: scheme.onSurfaceVariant,
                  title: s.settingsSectionInfo,
                  children: [
                    SettingsRow(
                      title: s.settingsAbout,
                      subtitle: s.settingsAboutSubtitle,
                      onTap: () => _showAbout(context),
                    ),
                    SettingsRow(
                      title: s.settingsRateApp,
                      subtitle: s.settingsRateAppSubtitle,
                      onTap: () async {
                        await FeedbackService.instance.moodSelected();
                        await ReviewService.instance.openStoreListing();
                      },
                    ),
                    SettingsRow(
                      title: s.settingsPrivacyPolicy,
                      subtitle: s.settingsPrivacyPolicySubtitle,
                      onTap: () => launchUrl(
                        Uri.parse('https://habit-ai-184ad.web.app/privacy.html'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    SettingsRow(
                      title: s.settingsTerms,
                      subtitle: s.settingsTermsSubtitle,
                      onTap: () => launchUrl(
                        Uri.parse('https://habit-ai-184ad.web.app/terms.html'),
                        mode: LaunchMode.externalApplication,
                      ),
                      divider: false,
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 260.ms),

                const SizedBox(height: 16),

                // ── 6. Zona de cuenta (destructivo) ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scheme.error.withValues(alpha: 0.12),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        SettingsRow(
                          title: s.settingsSignOut,
                          isDestructive: true,
                          destructiveIcon: Icons.logout_rounded,
                          onTap: () => _confirmSignOut(context, auth),
                        ),
                        SettingsRow(
                          title: s.settingsDeleteAccount,
                          subtitle: s.settingsDeleteAccountSubtitle,
                          isDestructive: true,
                          destructiveIcon: Icons.delete_forever_rounded,
                          onTap: () => _confirmDeleteAccount(context, auth),
                          divider: false,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 240.ms, duration: 260.ms),
              ],
            ),
          ),
        );
      },
    );
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

    final typed = await showDialog<String>(
      context: context, // ignore: use_build_context_synchronously
      builder: (_) => const _ConfirmDeleteDialog(),
    );
    if (typed != 'ELIMINAR' || !mounted) return;

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

/// Tarjeta hero de cuenta con gradiente de marca — lleva a editar perfil.
class _AccountHeroCard extends StatelessWidget {
  final UserModel? userData;
  final VoidCallback onTap;

  const _AccountHeroCard({
    required this.userData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fbUser = FirebaseAuth.instance.currentUser;
    final displayName = (userData?.displayName?.isNotEmpty == true
            ? userData!.displayName!
            : null) ??
        (fbUser?.displayName?.isNotEmpty == true ? fbUser!.displayName! : null) ??
        s.settingsFallbackUsername;
    final initials = AvatarCircle.fromName(
      userData?.displayName ?? fbUser?.displayName,
      userData?.email ?? fbUser?.email,
    );
    final hasUsername = userData?.username?.isNotEmpty == true;
    final isPublic = userData?.isProfilePublic == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.ambientShadow(opacity: 0.18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarCircle(
                  initials: initials,
                  size: 64,
                  photoUrl: userData?.photoUrl,
                  badge: AvatarBadge.camera,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  textColor: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasUsername
                                  ? Icons.alternate_email_rounded
                                  : Icons.mail_outline_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasUsername
                                  ? userData!.username!
                                  : (fbUser?.email ?? s.settingsFallbackUsername),
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                ),
              ],
            ),
            // línea inferior con separador: estado de visibilidad del perfil
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.20)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPublic
                        ? s.privacyPublicProfileDescOn
                        : s.privacyPublicProfileDescOff,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de selección de tema (label + SegmentedButton debajo).
class _ThemeRow extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeRow({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.settingsThemeLabel,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            style: SegmentedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              selectedBackgroundColor:
                  scheme.primaryContainer.withValues(alpha: 0.35),
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
            onSelectionChanged: (sel) => onChanged(sel.first),
          ),
        ],
      ),
    );
  }
}

/// Fila de selección de idioma (label + SegmentedButton debajo).
class _LanguageRow extends StatelessWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale?> onChanged;

  const _LanguageRow({required this.currentLocale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final selectedCode = currentLocale?.languageCode ?? 'es';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.settingsSectionLanguage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              selectedBackgroundColor:
                  scheme.primaryContainer.withValues(alpha: 0.35),
              selectedForegroundColor: scheme.primary,
            ),
            segments: [
              ButtonSegment(value: 'es', label: Text(s.languageEs)),
              ButtonSegment(value: 'en', label: Text(s.languageEn)),
            ],
            selected: {selectedCode},
            onSelectionChanged: (sel) => onChanged(Locale(sel.first)),
          ),
        ],
      ),
    );
  }
}

/// Fila de escudos disponibles con puntos visuales y tooltip.
class _ShieldRow extends StatelessWidget {
  final int shieldsCount;
  const _ShieldRow({required this.shieldsCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    final shields = List.generate(
      5,
      (i) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Icon(
          i < shieldsCount ? Icons.shield_rounded : Icons.shield_outlined,
          size: 18,
          color: i < shieldsCount
              ? AppTheme.tertiaryContainer
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
    );

    return Tooltip(
      message: s.settingsShieldsTooltip,
      child: SettingsRow(
        title: s.settingsShieldsTile,
        subtitle: s.settingsShieldsCount(shieldsCount),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: shields),
      ),
    );
  }
}

/// Fila de modo enfermedad con switch.
class _SickModeRow extends StatefulWidget {
  final UserModel? userData;
  final UserRepository userRepo;

  const _SickModeRow({required this.userData, required this.userRepo});

  @override
  State<_SickModeRow> createState() => _SickModeRowState();
}

class _SickModeRowState extends State<_SickModeRow> {
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
                      onChanged: (v) => setDlg(() => selectedDays = v.round()),
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
    return SettingsRow(
      title: S.of(context).settingsSickMode,
      subtitle: _subtitle(context),
      divider: false,
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(value: _isActive, onChanged: (_) => _toggle()),
    );
  }
}

/// Fila de notificaciones con switch.
class _NotificationsRow extends StatefulWidget {
  const _NotificationsRow();

  @override
  State<_NotificationsRow> createState() => _NotificationsRowState();
}

class _NotificationsRowState extends State<_NotificationsRow> {
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
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted) {
          if (mounted) {
            AppSnackBar.showInfo(
              context, // ignore: use_build_context_synchronously
              S.of(context).settingsNotificationsSystemPrompt,
            );
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
    final s = S.of(context);
    return SettingsRow(
      title: s.settingsNotifications,
      subtitle: _enabled
          ? s.settingsNotificationsEnabled
          : s.settingsNotificationsDisabled,
      divider: false,
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(value: _enabled, onChanged: _toggle),
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
          Text(s.settingsDeleteConfirmPrompt,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'ELIMINAR',
              hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
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
          onPressed: _matches
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
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
