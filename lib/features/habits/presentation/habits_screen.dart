import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/router/main_shell.dart';
import '../data/habit_repository.dart';
import '../data/habit_group_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_group_model.dart';
import '../domain/habit_log_model.dart';
import 'widgets/habit_card.dart';
import 'widgets/empty_habits_view.dart';
import 'widgets/edit_habit_sheet.dart';
import 'widgets/create_habit_sheet.dart';
import 'widgets/create_choice_sheet.dart';
import 'widgets/create_group_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../core/widgets/ux/error_state_view.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/data/achievement_checker.dart';
import '../../achievements/presentation/achievement_overlay.dart';
import '../../auth/data/user_repository.dart';
import '../../ai/data/ai_repository.dart';
import '../../ai/domain/renegotiation_model.dart';

/// Pantalla principal — grupos de habitos y hábitos sueltos
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late HabitRepository _habitRepo;
  late HabitGroupRepository _groupRepo;
  late AchievementChecker _achievementChecker;
  late AIRepository _aiRepo;

  late Stream<List<HabitModel>> _habitsStream;
  late Stream<List<HabitGroupModel>> _groupsStream;

  final Map<String, bool> _completedToday = {};
  final Set<String> _logsFetched = {};
  final Map<String, bool> _expandedGroups = {};
  bool _initialized = false;
  String? _userName;
  List<HabitModel> _currentTodayHabits = [];
  Map<String, RenegotiationModel> _pendingRenegotiations = {};
  StreamSubscription? _renoSub;

  // modo selección múltiple
  bool _selectionMode = false;
  final Set<String> _selectedHabitIds = {};

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedHabitIds.add(id);
    });
  }

  void _toggleHabitSelection(String id) {
    setState(() {
      if (_selectedHabitIds.contains(id)) {
        _selectedHabitIds.remove(id);
      } else {
        _selectedHabitIds.add(id);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedHabitIds.clear();
    });
  }

  Future<void> _bulkDeleteHabits() async {
    final count = _selectedHabitIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar $count hábito${count == 1 ? '' : 's'}'),
        content: const Text(
          'Se desactivarán pero se conservará el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ids = List<String>.from(_selectedHabitIds);
    _exitSelection();
    try {
      for (final id in ids) {
        await _habitRepo.deactivateHabit(id);
        _completedToday.remove(id);
        _logsFetched.remove(id);
      }
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          '$count hábito${count == 1 ? '' : 's'} eliminado${count == 1 ? '' : 's'}',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al eliminar los hábitos');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        // Firebase Auth directamente — displayName puede ser null si no se configuró
        final fbUser = FirebaseAuth.instance.currentUser;
        _userName = fbUser?.displayName?.isNotEmpty == true
            ? fbUser!.displayName
            : fbUser?.email?.split('@').first;
        _habitRepo = HabitRepository(uid: user.uid);
        _groupRepo = HabitGroupRepository(uid: user.uid);
        _habitsStream = _habitRepo.watchTodayHabits();
        _groupsStream = _groupRepo.watchGroups();
        _achievementChecker = AchievementChecker(
          achievementRepo: AchievementRepository(uid: user.uid),
          habitRepo: _habitRepo,
          userRepo: UserRepository(uid: user.uid),
        );
        _aiRepo = AIRepository(uid: user.uid);
        _renoSub = _aiRepo.watchActiveRenegotiations().listen((list) {
          if (mounted) {
            setState(() {
              _pendingRenegotiations = {
                for (final r in list) r.habitId: r,
              };
            });
          }
        });
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _renoSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _habitsStream = _habitRepo.watchTodayHabits();
      _groupsStream = _groupRepo.watchGroups();
      _logsFetched.clear();
      _completedToday.clear();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _fetchLogsIfNeeded(List<HabitModel> habits) {
    for (final habit in habits) {
      if (_logsFetched.contains(habit.id)) continue;
      _logsFetched.add(habit.id);
      _habitRepo.getTodayLog(habit.id).then((log) {
        if (mounted) {
          setState(() => _completedToday[habit.id] = log?.completed ?? false);
        }
      });
    }
  }

  Future<void> _toggleHabit(HabitModel habit) async {
    final wasCompleted = _completedToday[habit.id] ?? false;
    setState(() => _completedToday[habit.id] = !wasCompleted);

    try {
      if (!wasCompleted) {
        final log = HabitLogModel(id: '', date: DateTime.now(), completed: true);
        await _habitRepo.addLog(habit.id, log);
        await _habitRepo.updateStreak(habit.id);
      } else {
        await _habitRepo.uncheckAndRecalculate(habit.id);
      }
    } catch (e) {
      if (mounted) setState(() => _completedToday[habit.id] = wasCompleted);
      return;
    }

    if (!wasCompleted) {
      try {
        final updated = await _habitRepo.getHabit(habit.id);
        if (updated != null && mounted) {
          final unlocked = await _achievementChecker.checkAfterToggle(
            habit: updated,
            todayHabits: _currentTodayHabits,
            completedToday: _completedToday,
          );
          if (unlocked.isNotEmpty && mounted) {
            AchievementOverlay.showUnlocked(context, unlocked);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _editHabit(HabitModel habit) async {
    final updated = await EditHabitSheet.show(context, habit);
    if (updated == null) return;
    try {
      await _habitRepo.updateHabit(habit.id, {
        'title': updated.title,
        'description': updated.description,
        'category': updated.category,
        'frequency': updated.frequency,
        'targetDays': updated.targetDays,
        'reminderTime': updated.reminderTime,
      });
      // reasignar grupo si cambió (actualiza groupId y contadores)
      if (updated.groupId != habit.groupId) {
        await _habitRepo.reassignGroup(habit.id, habit.groupId, updated.groupId);
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Hábito actualizado');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al actualizar el hábito');
      }
    }
  }

  Future<void> _deleteHabit(HabitModel habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text(
          '¿Seguro que quieres eliminar "${habit.title}"?\n\n'
          'Se desactivará pero se conservará el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _habitRepo.deactivateHabit(habit.id);
      _completedToday.remove(habit.id);
      _logsFetched.remove(habit.id);
      if (habit.groupId != null) {
        try {
          await _groupRepo.incrementHabitCount(habit.groupId!, -1);
        } catch (_) {}
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, '"${habit.title}" eliminado');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error al eliminar el hábito');
      }
    }
  }

  Future<void> _applyRenegotiation(HabitModel habit) async {
    final reno = _pendingRenegotiations[habit.id];
    if (reno == null) return;
    await _aiRepo.markRenegotiationApplied(habit.id);
    if (!mounted) return;
    final prefilled = habit.copyWith(
      title: reno.suggestedTitle,
      description: reno.suggestedDescription ?? habit.description,
      reminderTime: reno.suggestedReminderTime ?? habit.reminderTime,
      targetDays: reno.suggestedTargetDays ?? habit.targetDays,
    );
    final updated = await EditHabitSheet.show(context, prefilled);
    if (updated == null || !mounted) return;
    try {
      await _habitRepo.updateHabit(habit.id, {
        'title': updated.title,
        'description': updated.description,
        'category': updated.category,
        'frequency': updated.frequency,
        'targetDays': updated.targetDays,
        'reminderTime': updated.reminderTime,
      });
      if (mounted) AppSnackBar.showSuccess(context, 'Hábito ajustado ✓');
    } catch (_) {
      if (mounted) AppSnackBar.showError(context, 'Error al actualizar el hábito');
    }
  }

  Future<void> _dismissRenegotiation(String habitId) async {
    await _aiRepo.dismissRenegotiation(habitId);
  }

  Future<void> _handleFabTap() async {
    final choice = await CreateChoiceSheet.show(context);
    if (choice == null) return;

    if (choice == CreateChoice.habit) {
      await _doCreateHabit();
    } else {
      await _doCreateGroup();
    }
  }

  Future<void> _doCreateHabit() async {
    final habit = await CreateHabitSheet.show(context);
    if (habit == null) return;
    try {
      await _habitRepo.createHabit(habit);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al crear el hábito');
      return;
    }
    if (mounted) AppSnackBar.showSuccess(context, 'Hábito creado');
    try {
      final unlocked = await _achievementChecker.checkAfterCreate();
      if (unlocked.isNotEmpty && mounted) {
        AchievementOverlay.showUnlocked(context, unlocked);
      }
    } catch (_) {}
  }

  Future<void> _doCreateGroup() async {
    final group = await CreateGroupSheet.show(context);
    if (group == null || !mounted) return;
    try {
      final groupId = await _groupRepo.createGroup(group);
      if (mounted) {
        context.go('/group/$groupId');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al crear la rutina');
    }
  }

  Future<void> _deleteGroup(HabitGroupModel group) async {
    // 'group_only' | 'group_and_habits' | null (cancelar)
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar "${group.title}"'),
        content: const Text(
          '¿Qué quieres hacer con los hábitos de esta rutina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('group_only'),
            child: const Text('Solo la rutina'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('group_and_habits'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Rutina y hábitos'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    try {
      if (choice == 'group_and_habits') {
        await _groupRepo.deleteGroupAndHabits(group.id);
      } else {
        await _groupRepo.deleteGroup(group.id);
      }
      if (mounted) AppSnackBar.showSuccess(context, 'Rutina "${group.title}" eliminada');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error al eliminar la rutina');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      floatingActionButton: _selectionMode
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _handleFabTap();
                },
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                tooltip: 'Crear',
                child: const Icon(Icons.add_rounded),
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<HabitGroupModel>>(
          stream: _groupsStream,
          builder: (context, groupsSnapshot) {
            return StreamBuilder<List<HabitModel>>(
              stream: _habitsStream,
              builder: (context, habitsSnapshot) {
                if (habitsSnapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    children: [
                      _buildHeader(context),
                      SectionSkeleton(itemCount: 4),
                    ],
                  );
                }
                if (habitsSnapshot.hasError) {
                  return _buildError(context, habitsSnapshot.error);
                }

                final allHabits = habitsSnapshot.data ?? [];
                _currentTodayHabits = allHabits;

                // grupos antes del early-return para poder mostrarlos aunque no haya hábitos hoy
                final groups = groupsSnapshot.data ?? [];
                final groupsLoaded = groupsSnapshot.hasData;

                // estado vacío solo si no hay hábitos NI grupos activos
                if (allHabits.isEmpty && groups.isEmpty) {
                  return Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: EmptyHabitsView(
                          onCreatePlan: () => context.go('/ai'),
                        ),
                      ),
                    ],
                  );
                }

                _fetchLogsIfNeeded(allHabits);

                final groupIds = groups.map((g) => g.id).toSet();
                final completedCount =
                    allHabits.where((h) => _completedToday[h.id] == true).length;

                final habitsByGroup = <String, List<HabitModel>>{};
                final ungroupedHabits = <HabitModel>[];

                for (final habit in allHabits) {
                  final gid = habit.groupId;
                  if (gid == null) {
                    ungroupedHabits.add(habit);
                  } else if (groupsLoaded && !groupIds.contains(gid)) {
                    ungroupedHabits.add(habit);
                  } else {
                    habitsByGroup.putIfAbsent(gid, () => []).add(habit);
                  }
                }

                // todos los grupos activos, incluyendo los vacíos
                final activeGroups = groups.toList();

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // header editorial asimetrico
                      SliverToBoxAdapter(child: _buildHeader(context)),

                      // hero de progreso diario
                      SliverToBoxAdapter(
                        child: _DailyProgressHero(
                          completed: completedCount,
                          total: allHabits.length,
                        ),
                      ),

                      // grupos como acordeones
                      ...activeGroups.map((group) {
                        final groupHabits = habitsByGroup[group.id] ?? [];
                        final groupCompleted = groupHabits
                            .where((h) => _completedToday[h.id] == true)
                            .length;
                        return SliverToBoxAdapter(
                          key: ValueKey('group_${group.id}'),
                          child: _GroupSection(
                            group: group,
                            habits: groupHabits,
                            completedCount: groupCompleted,
                            isExpanded: _expandedGroups[group.id] ?? true,
                            onToggleExpanded: () => setState(() {
                              _expandedGroups[group.id] =
                                  !(_expandedGroups[group.id] ?? true);
                            }),
                            onEditGroup: () => context.go('/group/${group.id}'),
                            onDeleteGroup: () => _deleteGroup(group),
                            completedToday: _completedToday,
                            onToggleHabit: _toggleHabit,
                            onTapHabit: (h) => context.go('/habit/${h.id}'),
                            onEditHabit: _editHabit,
                            onDeleteHabit: _deleteHabit,
                            selectionMode: _selectionMode,
                            selectedIds: _selectedHabitIds,
                            onToggleSelect: _toggleHabitSelection,
                            onEnterSelection: _enterSelection,
                            pendingRenegotiations: _pendingRenegotiations,
                            onApplyRenegotiation: _applyRenegotiation,
                            onDismissRenegotiation: _dismissRenegotiation,
                          ),
                        );
                      }),

                      // habitos sin grupo
                      if (ungroupedHabits.isNotEmpty)
                        SliverToBoxAdapter(
                          key: const ValueKey('ungrouped'),
                          child: _UngroupedSection(
                            habits: ungroupedHabits,
                            completedToday: _completedToday,
                            onToggleHabit: _toggleHabit,
                            onTapHabit: (h) => context.go('/habit/${h.id}'),
                            onEditHabit: _editHabit,
                            onDeleteHabit: _deleteHabit,
                            selectionMode: _selectionMode,
                            selectedIds: _selectedHabitIds,
                            onToggleSelect: _toggleHabitSelection,
                            onEnterSelection: _enterSelection,
                            pendingRenegotiations: _pendingRenegotiations,
                            onApplyRenegotiation: _applyRenegotiation,
                            onDismissRenegotiation: _dismissRenegotiation,
                          ),
                        ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: context.bottomNavInset),
                    ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // header asimetrico: saludo izquierda, fecha derecha (o barra de selección)
  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_selectionMode) {
      final count = _selectedHabitIds.length;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _exitSelection,
              tooltip: 'Cancelar selección',
            ),
            Expanded(
              child: Text(
                '$count seleccionado${count == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: count > 0 ? AppTheme.error : scheme.onSurfaceVariant,
              ),
              tooltip: 'Eliminar seleccionados',
              onPressed: count > 0 ? _bulkDeleteHabits : null,
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final dayName = days[now.weekday - 1];
    final dateStr = '${now.day} ${months[now.month - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const DrawerMenuButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName != null ? 'Hola, $_userName' : 'HabitAI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _userName != null ? scheme.onSurface : scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayName, $dateStr',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // boton de notificaciones / perfil
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              boxShadow: AppTheme.ambientShadow(),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object? error) {
    return ErrorStateView(
      message: 'No se pudieron cargar tus hábitos. Comprueba tu conexión.',
      onRetry: _refresh,
    );
  }
}

// ==================== HERO DE PROGRESO ====================

class _DailyProgressHero extends StatelessWidget {
  final int completed;
  final int total;

  const _DailyProgressHero({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = completed == total && total > 0;
    final pct = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: allDone
              ? AppTheme.streakGradient
              : AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.ambientShadow(opacity: 0.14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone ? '¡Todo listo!' : 'Progreso de hoy',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '${(v * 100).toInt()}%',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completed de $total hábitos completados',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // circulo de progreso
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: v,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: allDone && pct == 100
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 28)
                            : Text(
                                '$pct%',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SECCIÓN DE GRUPO ====================

class _GroupSection extends StatelessWidget {
  final HabitGroupModel group;
  final List<HabitModel> habits;
  final int completedCount;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEditGroup;
  final VoidCallback onDeleteGroup;
  final Map<String, bool> completedToday;
  final void Function(HabitModel) onToggleHabit;
  final void Function(HabitModel) onTapHabit;
  final void Function(HabitModel) onEditHabit;
  final void Function(HabitModel) onDeleteHabit;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelect;
  final void Function(String) onEnterSelection;
  final Map<String, RenegotiationModel> pendingRenegotiations;
  final void Function(HabitModel) onApplyRenegotiation;
  final void Function(String) onDismissRenegotiation;

  const _GroupSection({
    required this.group,
    required this.habits,
    required this.completedCount,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onEditGroup,
    required this.onDeleteGroup,
    required this.completedToday,
    required this.onToggleHabit,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
    this.selectionMode = false,
    this.selectedIds = const {},
    required this.onToggleSelect,
    required this.onEnterSelection,
    this.pendingRenegotiations = const {},
    required this.onApplyRenegotiation,
    required this.onDismissRenegotiation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allDone = completedCount == habits.length && habits.isNotEmpty;
    final progress = habits.isNotEmpty ? completedCount / habits.length : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.ambientShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // cabecera del grupo
            InkWell(
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    if (group.emoji != null)
                      Text(group.emoji!, style: const TextStyle(fontSize: 24))
                    else
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 18),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    backgroundColor: scheme.outlineVariant.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      allDone ? AppTheme.tertiaryContainer : scheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                habits.isEmpty ? '–' : '$completedCount/${habits.length}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: allDone
                                      ? AppTheme.tertiaryContainer
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: scheme.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (v) {
                        if (v == 'edit') onEditGroup();
                        if (v == 'delete') onDeleteGroup();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Editar grupo'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                              const SizedBox(width: 12),
                              Text('Eliminar grupo', style: TextStyle(color: AppTheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            // lista de habitos (colapso animado)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.12)),
                  if (habits.isEmpty)
                    // grupo vacío: invitar a añadir hábitos
                    InkWell(
                      onTap: onEditGroup,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                size: 16, color: scheme.primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            Text(
                              'Toca para añadir hábitos',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.primary.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...habits.map((habit) => HabitCard(
                      key: ValueKey(habit.id),
                      habit: habit,
                      isCompletedToday: completedToday[habit.id] ?? false,
                      onToggle: () => onToggleHabit(habit),
                      onTap: () => onTapHabit(habit),
                      onEdit: () => onEditHabit(habit),
                      onDelete: () => onDeleteHabit(habit),
                      isInsideGroup: true,
                      selectionMode: selectionMode,
                      isSelected: selectedIds.contains(habit.id),
                      onEnterSelection: () => onEnterSelection(habit.id),
                      onToggleSelect: () => onToggleSelect(habit.id),
                      renegotiation: pendingRenegotiations[habit.id],
                      onApplyRenegotiation: () => onApplyRenegotiation(habit),
                      onDismissRenegotiation: () => onDismissRenegotiation(habit.id),
                    )),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SECCIÓN SIN GRUPO ====================

class _UngroupedSection extends StatelessWidget {
  final List<HabitModel> habits;
  final Map<String, bool> completedToday;
  final void Function(HabitModel) onToggleHabit;
  final void Function(HabitModel) onTapHabit;
  final void Function(HabitModel) onEditHabit;
  final void Function(HabitModel) onDeleteHabit;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelect;
  final void Function(String) onEnterSelection;
  final Map<String, RenegotiationModel> pendingRenegotiations;
  final void Function(HabitModel) onApplyRenegotiation;
  final void Function(String) onDismissRenegotiation;

  const _UngroupedSection({
    required this.habits,
    required this.completedToday,
    required this.onToggleHabit,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
    this.selectionMode = false,
    this.selectedIds = const {},
    required this.onToggleSelect,
    required this.onEnterSelection,
    this.pendingRenegotiations = const {},
    required this.onApplyRenegotiation,
    required this.onDismissRenegotiation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header seccion "Mis habitos"
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12, top: 6),
            child: Row(
              children: [
                Text(
                  'Mis hábitos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${habits.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // cards de habitos sueltos en contenedor
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.ambientShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ...habits.map((habit) => HabitCard(
                  key: ValueKey(habit.id),
                  habit: habit,
                  isCompletedToday: completedToday[habit.id] ?? false,
                  onToggle: () => onToggleHabit(habit),
                  onTap: () => onTapHabit(habit),
                  onEdit: () => onEditHabit(habit),
                  onDelete: () => onDeleteHabit(habit),
                  isInsideGroup: true,
                  selectionMode: selectionMode,
                  isSelected: selectedIds.contains(habit.id),
                  onEnterSelection: () => onEnterSelection(habit.id),
                  onToggleSelect: () => onToggleSelect(habit.id),
                  renegotiation: pendingRenegotiations[habit.id],
                  onApplyRenegotiation: () => onApplyRenegotiation(habit),
                  onDismissRenegotiation: () => onDismissRenegotiation(habit.id),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
