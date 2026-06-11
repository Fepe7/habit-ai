import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../router/main_shell.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/data/ai_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/habits/data/habit_repository.dart';
import '../../features/habits/presentation/widgets/create_habit_sheet.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'premium_gate.dart';

/// Drawer lateral con atajos a features enterradas, acciones rápidas
/// y toggles de preferencias. SignOut vive solo en SettingsScreen.
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  UserRepository? _userRepo;
  AIRepository? _aiRepo;
  HabitRepository? _habitRepo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userRepo != null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _userRepo = UserRepository(uid: uid);
    _aiRepo = AIRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
  }

  // go() solo para los tabs del bottom nav (cambio de pestaña, sin apilar).
  void _goAndClose(String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  // push() para pantallas secundarias (no-tab): así "atrás" vuelve a donde
  // se abrió el drawer en vez de saltar a Hábitos.
  void _pushAndClose(String path) {
    Navigator.of(context).pop();
    context.push(path);
  }

  void _pushNamedAndClose(String name, {Map<String, String>? params}) {
    Navigator.of(context).pop();
    context.pushNamed(name, pathParameters: params ?? const {});
  }

  Future<void> _openLatestWeeklyReview() async {
    final review = await _aiRepo?.watchLatestWeeklyReview().first;
    if (!mounted) return;
    if (review == null) {
      _goAndClose('/dashboard');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.drawerNoWeeklyReview)),
      );
      return;
    }
    _pushNamedAndClose('weekly-review', params: {'weekId': review.weekId});
  }

  Future<void> _openLatestButterfly() async {
    final proj = await _aiRepo?.watchLatestButterfly().first;
    if (!mounted) return;
    if (proj == null) {
      _goAndClose('/dashboard');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.drawerNoButterfly)),
      );
      return;
    }
    _pushNamedAndClose(
      'butterfly-projection',
      params: {'monthId': proj.monthId},
    );
  }

  Future<void> _createHabit() async {
    Navigator.of(context).pop();
    if (_habitRepo == null) return;
    // límite free de hábitos activos: el gate muestra el upsell si toca
    if (!await PremiumGate.checkHabitLimit(context, _habitRepo!)) return;
    if (!mounted) return;
    final habit = await CreateHabitSheet.show(context);
    if (habit == null || _habitRepo == null || !mounted) return;
    final s = S.of(context)!;
    try {
      await _habitRepo!.createHabit(habit);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.drawerHabitCreated)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.drawerHabitCreateError),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: scheme.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<UserModel>(
          stream: _userRepo?.watchUser(),
          builder: (context, snapshot) {
            final userData = snapshot.data;
            final s = S.of(context)!;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerHeader(
                  user: user,
                  userData: userData,
                  onTap: () => _pushAndClose('/settings'),
                ),
                _SectionLabel(label: s.drawerProgress),
                _DrawerTile(
                  icon: Icons.emoji_events_rounded,
                  title: s.drawerAchievements,
                  subtitle: s.drawerAchievementsSubtitle,
                  onTap: () => _pushNamedAndClose('achievements'),
                ),
                // "Niveles" se quitó del menú: ya vive en Perfil → Maestría
                _DrawerTile(
                  icon: Icons.mood_rounded,
                  title: s.drawerMoodCalendar,
                  subtitle: s.drawerMoodCalendarSubtitle,
                  onTap: () => _pushNamedAndClose('mood-calendar'),
                ),
                _DrawerTile(
                  icon: Icons.list_alt_rounded,
                  title: s.drawerAllHabits,
                  subtitle: s.drawerAllHabitsSubtitle,
                  onTap: () => _pushNamedAndClose('all-habits'),
                ),
                _DrawerTile(
                  icon: Icons.calendar_month_rounded,
                  title: s.drawerWeeklyReview,
                  subtitle: s.drawerWeeklyReviewSubtitle,
                  onTap: _openLatestWeeklyReview,
                ),
                _DrawerTile(
                  icon: Icons.auto_awesome_rounded,
                  title: s.drawerButterfly,
                  subtitle: s.drawerButterflySubtitle,
                  onTap: _openLatestButterfly,
                ),
                const SizedBox(height: 8),
                _SectionLabel(label: s.drawerQuickActions),
                _DrawerTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: s.drawerCreateHabit,
                  subtitle: s.drawerCreateHabitSubtitle,
                  onTap: _createHabit,
                ),
                _DrawerTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: s.drawerChatAI,
                  subtitle: s.drawerChatAISubtitle,
                  onTap: () => _goAndClose('/ai'),
                ),
                const SizedBox(height: 8),
                _SectionLabel(label: s.drawerPreferences),
                _SickModeQuickTile(
                  userData: userData,
                  userRepo: _userRepo,
                ),
                const SizedBox(height: 8),
                _SectionLabel(label: s.settingsTitle),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  title: s.drawerSettings,
                  subtitle: s.drawerSettingsSubtitle,
                  onTap: () => _pushAndClose('/settings'),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Botón hamburguesa redondo que abre el drawer. Reutilizable en headers.
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        shape: BoxShape.circle,
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: IconButton(
        iconSize: 22,
        padding: EdgeInsets.zero,
        icon: Icon(Icons.menu_rounded, color: scheme.onSurfaceVariant),
        tooltip: S.of(context)?.drawerMenu ?? 'Menú',
        onPressed: () => MainShell.scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }
}

// ==================== INTERNOS ====================

class _DrawerHeader extends StatelessWidget {
  final User? user;
  final UserModel? userData;
  final VoidCallback onTap;

  const _DrawerHeader({
    required this.user,
    required this.userData,
    required this.onTap,
  });

  Widget _buildDrawerAvatar(BuildContext context) {
    final photoUrl = userData?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return SizedBox(
        width: 52,
        height: 52,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialsAvatar(context),
          ),
        ),
      );
    }
    return _buildInitialsAvatar(context);
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _initials() {
    final name = user?.displayName;
    final email = user?.email;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final shields = userData?.shieldsCount ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.ambientShadow(opacity: 0.12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _buildDrawerAvatar(context),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // nombre real: Firestore > Firebase Auth > fallback email prefix
                        Text(
                          (userData?.displayName?.isNotEmpty == true
                                  ? userData!.displayName!
                                  : null) ??
                              (user?.displayName?.isNotEmpty == true
                                  ? user!.displayName!
                                  : null) ??
                              user?.email?.split('@').first ??
                              'Usuario',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // @username si existe, si no el email
                        Text(
                          (userData?.username?.isNotEmpty == true)
                              ? '@${userData!.username}'
                              : user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                S.of(context)!.drawerShields(shields),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
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

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: scheme.primary),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}


/// Toggle rápido de modo enfermedad — reusa la lógica de UserRepository.
class _SickModeQuickTile extends StatefulWidget {
  final UserModel? userData;
  final UserRepository? userRepo;

  const _SickModeQuickTile({required this.userData, required this.userRepo});

  @override
  State<_SickModeQuickTile> createState() => _SickModeQuickTileState();
}

class _SickModeQuickTileState extends State<_SickModeQuickTile> {
  bool _loading = false;

  bool get _isActive {
    final until = widget.userData?.sickModeUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  String _subtitle(BuildContext context) {
    if (_isActive) {
      final until = widget.userData!.sickModeUntil!;
      final diff = until.difference(DateTime.now()).inDays + 1;
      return 'Activo — ${S.of(context)!.daysLabel(diff)}';
    }
    return S.of(context)!.drawerStreakFreeze;
  }

  Future<void> _toggle() async {
    if (_loading || widget.userRepo == null) return;
    setState(() => _loading = true);
    try {
      if (_isActive) {
        await widget.userRepo!.cancelSickMode();
      } else {
        if (!mounted) return;
        final days = await _showDaysPicker(context);
        if (days == null) {
          setState(() => _loading = false);
          return;
        }
        await widget.userRepo!.activateSickMode(days);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int?> _showDaysPicker(BuildContext context) {
    int selected = 1;
    final s = S.of(context)!;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(s.settingsSickModeDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.settingsSickModeDialogContent),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('${s.days}: '),
                  Expanded(
                    child: Slider(
                      value: selected.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: '$selected',
                      onChanged: (v) => setDlg(() => selected = v.round()),
                    ),
                  ),
                  Text('$selected'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.medical_services_outlined,
          size: 18,
          color: scheme.primary,
        ),
      ),
      title: Text(
        S.of(context)!.drawerSickMode,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(_subtitle(context), style: Theme.of(context).textTheme.bodySmall),
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
