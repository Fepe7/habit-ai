import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/ux/app_snackbar.dart' show AppSnackBar;
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_model.dart';
import '../../profile/data/public_profile_repository.dart';
import '../../profile/presentation/widgets/username_input_sheet.dart';
import '../../social/data/user_directory_repository.dart';
import '../../social/domain/privacy_level.dart';

/// Pantalla de ajustes de privacidad.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late final UserRepository _userRepo;
  late final UserDirectoryRepository _dirRepo;
  late final HabitRepository _habitRepo;
  late final PublicProfileRepository _publicProfileRepo;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
    _dirRepo = UserDirectoryRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
    _publicProfileRepo = PublicProfileRepository(uid: uid);
  }

  Future<void> _updateChallengePrivacy(PrivacyLevel level) async {
    try {
      await _dirRepo.updatePrivacySettings(challengePrivacy: level);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al guardar: $e');
    }
  }

  Future<void> _updateSectionVisibility(String field, bool value) async {
    try {
      await _dirRepo.updatePrivacySettings(
        showStats: field == 'showStats' ? value : null,
        showHabits: field == 'showHabits' ? value : null,
        showAchievements: field == 'showAchievements' ? value : null,
        showFollowerCount: field == 'showFollowerCount' ? value : null,
      );
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad'),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<UserModel>(
        stream: _userRepo.watchUser(),
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final challengeLevel = PrivacyLevelX.fromString(user.challengePrivacy);
          final hasUsername = user.username != null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // banner informativo si aún no tiene username
              if (!hasUsername)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: scheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Elige un nombre de usuario para que otros puedan encontrarte.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              // master switch: perfil público / privado
              _SectionLabel(label: 'Visibilidad'),
              _ProfilePublicityCard(
                userData: user,
                publicProfileRepo: _publicProfileRepo,
              ).animate().fadeIn(delay: 50.ms),

              if (hasUsername) ...[
                const SizedBox(height: 24),

                // header dinámico: el label cambia según público/privado
                _SectionLabel(
                  label: user.isProfilePublic
                      ? 'Qué ve todo el mundo'
                      : 'Qué ven tus seguidores',
                ),
                _SectionVisibilityCard(
                  user: user,
                  onToggle: _updateSectionVisibility,
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // hábitos visibles individualmente — siempre visible
                _VisibleHabitsSection(
                  habitRepo: _habitRepo,
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 24),

                // retos
                _SectionLabel(label: 'Retos'),
                _PrivacyCard(
                  icon: Icons.sports_score_rounded,
                  title: 'Quién puede enviarme retos',
                  description: 'Controla quién puede invitarte a competir en un hábito',
                  selected: challengeLevel,
                  onChanged: _updateChallengePrivacy,
                ).animate().fadeIn(delay: 200.ms),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ==================== WIDGETS INTERNOS ====================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

/// Master switch: activar/desactivar perfil público + gestión de username.
/// Cuando está ON → apareces en el directorio, cualquiera puede seguirte.
/// Cuando está OFF → no apareces, el seguimiento requiere aprobación.
class _ProfilePublicityCard extends StatefulWidget {
  final UserModel? userData;
  final PublicProfileRepository publicProfileRepo;

  const _ProfilePublicityCard({
    required this.userData,
    required this.publicProfileRepo,
  });

  @override
  State<_ProfilePublicityCard> createState() => _ProfilePublicityCardState();
}

class _ProfilePublicityCardState extends State<_ProfilePublicityCard> {
  bool _loading = false;

  bool get _isPublic => widget.userData?.isProfilePublic ?? false;
  String? get _username => widget.userData?.username;

  Future<void> _toggle(BuildContext context) async {
    if (_loading) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isPublic && _username != null) {
      final confirm = await _showDisableConfirm(context);
      if (confirm != true) return;
      setState(() => _loading = true);
      try {
        await widget.publicProfileRepo.disablePublicProfile(_username!);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else if (!_isPublic && _username != null) {
      // ya tiene username — reactivar sin pedir username de nuevo
      setState(() => _loading = true);
      try {
        await widget.publicProfileRepo.reenablePublicProfile();
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // primera vez: pedir username y crear el perfil
      final chosenUsername = await UsernameInputSheet.show(
        context,
        widget.publicProfileRepo,
      );
      if (chosenUsername == null || !mounted) return;
      setState(() => _loading = true);
      try {
        final displayName = user.displayName ?? user.email ?? 'Usuario';
        final initials = AvatarCircle.fromName(user.displayName, user.email);
        final ok = await widget.publicProfileRepo.enablePublicProfile(
          username: chosenUsername,
          displayName: displayName,
          avatarInitials: initials,
          photoUrl: widget.userData?.photoUrl,
        );
        if (!mounted) return;
        if (!ok) {
          AppSnackBar.showInfo(context, 'El username ya está ocupado'); // ignore: use_build_context_synchronously
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeUsername(BuildContext context) async {
    if (_loading || _username == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newUsername = await UsernameInputSheet.show(
      context,
      widget.publicProfileRepo,
      currentUsername: _username,
    );
    if (newUsername == null || newUsername == _username || !mounted) return;

    setState(() => _loading = true);
    try {
      final displayName = user.displayName ?? user.email ?? 'Usuario';
      final initials = AvatarCircle.fromName(user.displayName, user.email);
      final ok = await widget.publicProfileRepo.changeUsername(
        _username!,
        newUsername,
        displayName,
        initials,
      );
      if (!mounted) return;
      if (!ok) {
        AppSnackBar.showInfo(context, 'El username ya está ocupado'); // ignore: use_build_context_synchronously
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _showDisableConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar perfil público'),
        content: const Text(
          'Tu perfil desaparecerá del directorio. Tus seguidores actuales '
          'podrán seguir viéndote hasta que los elimines.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfil público',
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _isPublic
                          ? 'Apareces en el directorio, cualquiera puede seguirte'
                          : 'Solo tus seguidores pueden verte',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _isPublic,
                      onChanged: (_) => _toggle(context),
                    ),
            ],
          ),

          // username + botón cambiar (solo si ya tiene username)
          if (_username != null) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '@$_username',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _loading ? null : () => _changeUsername(context),
                  child: const Text('Cambiar username'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Toggles de visibilidad de secciones del perfil.
/// Aplican tanto para público (lo ve todo el mundo) como privado (lo ven seguidores).
class _SectionVisibilityCard extends StatelessWidget {
  final UserModel user;
  final void Function(String field, bool value) onToggle;

  const _SectionVisibilityCard({
    required this.user,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final items = [
      (
        icon: Icons.bar_chart_rounded,
        label: 'Estadísticas',
        field: 'showStats',
        value: user.showStats,
      ),
      (
        icon: Icons.checklist_rounded,
        label: 'Hábitos activos',
        field: 'showHabits',
        value: user.showHabits,
      ),
      (
        icon: Icons.emoji_events_rounded,
        label: 'Logros',
        field: 'showAchievements',
        value: user.showAchievements,
      ),
      (
        icon: Icons.people_outline_rounded,
        label: 'Seguidores / Siguiendo',
        field: 'showFollowerCount',
        value: user.showFollowerCount,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: items.map((item) {
          return SwitchListTile(
            secondary: Icon(item.icon, color: scheme.primary, size: 22),
            title: Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            value: item.value,
            onChanged: (val) => onToggle(item.field, val),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        }).toList(),
      ),
    );
  }
}

/// Lista de hábitos activos con toggle individual de visibilidad.
/// Visible tanto en perfil público como privado (aplica a seguidores).
class _VisibleHabitsSection extends StatelessWidget {
  final HabitRepository habitRepo;

  const _VisibleHabitsSection({required this.habitRepo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'Hábitos visibles en tu perfil'),
        StreamBuilder<List<HabitModel>>(
          stream: habitRepo.watchActiveHabits(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final habits = snap.data!;
            if (habits.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'No tienes hábitos activos',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.ambientShadow(),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: habits.map((habit) {
                  return SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.categoryBg(habit.category),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        AppTheme.categoryIcon(habit.category),
                        size: 18,
                        color: AppTheme.categoryFg(habit.category),
                      ),
                    ),
                    title: Text(
                      habit.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      AppTheme.categoryLabel(habit.category),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    value: habit.isPubliclyVisible,
                    onChanged: (val) =>
                        habitRepo.setHabitPublicVisibility(habit.id, val),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final PrivacyLevel selected;
  final ValueChanged<PrivacyLevel> onChanged;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(description,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: PrivacyLevel.values.map((level) {
              final isSelected = selected == level;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => onChanged(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          level.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
