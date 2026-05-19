import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ux/app_snackbar.dart' show AppSnackBar;
import '../../auth/data/user_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/domain/habit_model.dart';
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

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userRepo = UserRepository(uid: uid);
    _dirRepo = UserDirectoryRepository(uid: uid);
    _habitRepo = HabitRepository(uid: uid);
  }

  Future<void> _updateChallengePrivacy(PrivacyLevel level) async {
    try {
      await _dirRepo.updatePrivacySettings(challengePrivacy: level);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al guardar: $e');
    }
  }

  Future<void> _updateProfileVisibility(PrivacyLevel level) async {
    try {
      await _dirRepo.updatePrivacySettings(profileVisibility: level);
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
          final profileLevel = PrivacyLevelX.fromString(user.profileVisibility);
          final hasUsername = user.username != null;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
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
                          'Necesitas un nombre de usuario para que otros puedan encontrarte.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              _SectionLabel(label: 'Retos'),
              _PrivacyCard(
                icon: Icons.sports_score_rounded,
                title: 'Quién puede enviarme retos',
                description: 'Controla quién puede invitarte a competir en un hábito',
                selected: challengeLevel,
                enabled: hasUsername,
                onChanged: _updateChallengePrivacy,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              _SectionLabel(label: 'Perfil'),
              _PrivacyCard(
                icon: Icons.person_outline_rounded,
                title: 'Quién puede ver mi perfil completo',
                description: 'Stats, hábitos activos y logros en el directorio público',
                selected: profileLevel,
                enabled: hasUsername,
                onChanged: _updateProfileVisibility,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              _SectionLabel(label: 'Seguimiento'),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.ambientShadow(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  value: !user.isProfilePublic,
                  onChanged: hasUsername
                      ? (val) {
                          _userRepo.setProfilePublic(!val).catchError((e) {
                            if (mounted) {
                              AppSnackBar.showError(
                                  context, 'Error al guardar: $e');
                            }
                          });
                        }
                      : null,
                  title: const Text(
                    'Perfil privado',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Las solicitudes de seguimiento requieren aprobación',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),

              // Visibilidad de secciones del perfil
              _SectionLabel(label: 'Qué se muestra en tu perfil'),
              _SectionVisibilityCard(
                user: user,
                enabled: hasUsername,
                onToggle: _updateSectionVisibility,
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 20),

              // Selector de hábitos visibles
              if (hasUsername && user.isProfilePublic)
                _VisibleHabitsSection(
                  habitRepo: _habitRepo,
                ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () => context.pushNamed('followers'),
                icon: const Icon(Icons.people_outline_rounded),
                label: const Text('Gestionar seguidores'),
              ).animate().fadeIn(delay: 450.ms),
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

/// Toggles de visibilidad de secciones del perfil
class _SectionVisibilityCard extends StatelessWidget {
  final UserModel user;
  final bool enabled;
  final void Function(String field, bool value) onToggle;

  const _SectionVisibilityCard({
    required this.user,
    required this.enabled,
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
        label: 'Seguidores/Siguiendo',
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
            onChanged: enabled
                ? (val) => onToggle(item.field, val)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        }).toList(),
      ),
    );
  }
}

/// Lista de hábitos activos con toggle individual de visibilidad
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
  final bool enabled;
  final ValueChanged<PrivacyLevel> onChanged;
  final List<PrivacyLevel> options;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    this.options = PrivacyLevel.values,
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
            children: options.map((level) {
              final isSelected = selected == level;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: enabled ? () => onChanged(level) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: enabled ? 0.5 : 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          level.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? scheme.onPrimary
                                : enabled
                                    ? scheme.onSurface
                                    : scheme.onSurface
                                        .withValues(alpha: 0.4),
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
