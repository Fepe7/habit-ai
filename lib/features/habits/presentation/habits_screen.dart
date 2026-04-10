import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../data/habit_repository.dart';
import '../data/habit_group_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_group_model.dart';
import '../domain/habit_log_model.dart';
import 'widgets/habit_card.dart';
import 'widgets/empty_habits_view.dart';
import 'widgets/edit_habit_sheet.dart';
import 'widgets/create_habit_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/data/achievement_checker.dart';
import '../../achievements/presentation/achievement_overlay.dart';

// Pantalla principal con habitos organizados en grupos (rutinas de IA) y sueltos
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late HabitRepository _habitRepo;
  late HabitGroupRepository _groupRepo;
  late AchievementChecker _achievementChecker;

  // streams cacheados para que no se recreen en cada rebuild
  late Stream<List<HabitModel>> _habitsStream;
  late Stream<List<HabitGroupModel>> _groupsStream;

  final Map<String, bool> _completedToday = {};
  final Set<String> _logsFetched = {};
  // estado de expansion de cada grupo (por defecto expandido)
  final Map<String, bool> _expandedGroups = {};
  bool _initialized = false;
  List<HabitModel> _currentTodayHabits = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _habitRepo = HabitRepository(uid: user.uid);
        _groupRepo = HabitGroupRepository(uid: user.uid);
        _habitsStream = _habitRepo.watchTodayHabits();
        _groupsStream = _groupRepo.watchGroups();
        _achievementChecker = AchievementChecker(
          achievementRepo: AchievementRepository(uid: user.uid),
          habitRepo: _habitRepo,
        );
      }
      _initialized = true;
    }
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
          setState(() {
            _completedToday[habit.id] = log?.completed ?? false;
          });
        }
      });
    }
  }

  Future<void> _toggleHabit(HabitModel habit) async {
    final wasCompleted = _completedToday[habit.id] ?? false;

    setState(() {
      _completedToday[habit.id] = !wasCompleted;
    });

    try {
      if (!wasCompleted) {
        final log = HabitLogModel(
          id: '',
          date: DateTime.now(),
          completed: true,
        );
        await _habitRepo.addLog(habit.id, log);
        await _habitRepo.updateStreak(habit.id);
      } else {
        await _habitRepo.uncheckAndRecalculate(habit.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _completedToday[habit.id] = wasCompleted;
        });
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hábito actualizado'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al actualizar el hábito'),
            backgroundColor: AppTheme.error,
          ),
        );
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

      // si pertenece a un grupo, decrementar el contador
      if (habit.groupId != null) {
        try {
          await _groupRepo.incrementHabitCount(habit.groupId!, -1);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${habit.title}" eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al eliminar el hábito'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createHabit() async {
    final habit = await CreateHabitSheet.show(context);
    if (habit == null) return;

    try {
      await _habitRepo.createHabit(habit);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al crear el hábito'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hábito creado'),
          backgroundColor: AppTheme.success,
        ),
      );
    }

    try {
      final unlocked = await _achievementChecker.checkAfterCreate();
      if (unlocked.isNotEmpty && mounted) {
        AchievementOverlay.showUnlocked(context, unlocked);
      }
    } catch (_) {}
  }

  Future<void> _deleteGroup(HabitGroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text(
          '¿Eliminar el grupo "${group.title}"?\n\n'
          'Los hábitos no se borran, pasan a "Mis hábitos".',
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
      await _groupRepo.deleteGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo "${group.title}" eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al eliminar el grupo'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('HabitAI'),
            Text(
              _todayFormatted(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createHabit,
        tooltip: 'Crear hábito',
        child: const Icon(Icons.add),
      ),
      // escuchar los dos streams: grupos y habitos
      body: StreamBuilder<List<HabitGroupModel>>(
        stream: _groupsStream,
        builder: (context, groupsSnapshot) {
          return StreamBuilder<List<HabitModel>>(
            stream: _habitsStream,
            builder: (context, habitsSnapshot) {
              if (habitsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (habitsSnapshot.hasError) {
                return _buildError(context, habitsSnapshot.error);
              }

              final allHabits = habitsSnapshot.data ?? [];
              _currentTodayHabits = allHabits;

              if (allHabits.isEmpty) {
                return EmptyHabitsView(onCreatePlan: () => context.go('/ai'));
              }

              _fetchLogsIfNeeded(allHabits);

              final groups = groupsSnapshot.data ?? [];
              final groupsLoaded = groupsSnapshot.hasData;
              final groupIds = groups.map((g) => g.id).toSet();
              final completedCount = allHabits
                  .where((h) => _completedToday[h.id] == true)
                  .length;

              // separar habitos por grupo
              final habitsByGroup = <String, List<HabitModel>>{};
              final ungroupedHabits = <HabitModel>[];

              for (final habit in allHabits) {
                final gid = habit.groupId;
                if (gid == null) {
                  ungroupedHabits.add(habit);
                } else if (groupsLoaded && !groupIds.contains(gid)) {
                  // huerfano: el grupo no existe (borrado o fallo de carga),
                  // lo mostramos en "Mis habitos" para que no desaparezca
                  ungroupedHabits.add(habit);
                } else {
                  habitsByGroup.putIfAbsent(gid, () => []).add(habit);
                }
              }

              // solo mostrar grupos que tienen habitos hoy
              final activeGroups = groups
                  .where((g) => habitsByGroup.containsKey(g.id))
                  .toList();

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // barra de progreso
                    SliverToBoxAdapter(
                      child: _DailyProgress(
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
                          onToggleExpanded: () {
                            setState(() {
                              _expandedGroups[group.id] =
                                  !(_expandedGroups[group.id] ?? true);
                            });
                          },
                          onEditGroup: () => context.go('/group/${group.id}'),
                          onDeleteGroup: () => _deleteGroup(group),
                          completedToday: _completedToday,
                          onToggleHabit: _toggleHabit,
                          onTapHabit: (h) => context.go('/habit/${h.id}'),
                          onEditHabit: _editHabit,
                          onDeleteHabit: _deleteHabit,
                        ),
                      );
                    }),

                    // habitos sin grupo ("Mis habitos")
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
                        ),
                      ),

                    // espacio para el FAB
                    const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, Object? error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error al cargar hábitos',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _todayFormatted() {
    final now = DateTime.now();
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

// ==================== SECCIÓN DE GRUPO (acordeón) ====================

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
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allDone = completedCount == habits.length && habits.isNotEmpty;
    final progress = habits.isNotEmpty ? completedCount / habits.length : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // cabecera del grupo (tap para expandir/colapsar)
            InkWell(
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  children: [
                    // emoji del grupo
                    if (group.emoji != null)
                      Text(group.emoji!, style: const TextStyle(fontSize: 22))
                    else
                      Icon(Icons.star, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 12),

                    // titulo y progreso
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // barra de progreso del grupo
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: colorScheme.outlineVariant
                                        .withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      allDone
                                          ? AppTheme.success
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$completedCount/${habits.length}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: allDone
                                      ? AppTheme.success
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // menu del grupo
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'edit') onEditGroup();
                        if (value == 'delete') onDeleteGroup();
                      },
                      itemBuilder: (context) => [
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
                              Text('Eliminar grupo',
                                  style: TextStyle(color: AppTheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // flecha de expandir
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.expand_more,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // habitos del grupo (animacion de colapso)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const Divider(height: 1),
                  ...habits.map((habit) => Padding(
                    key: ValueKey(habit.id),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: HabitCard(
                      habit: habit,
                      isCompletedToday: completedToday[habit.id] ?? false,
                      onToggle: () => onToggleHabit(habit),
                      onTap: () => onTapHabit(habit),
                      onEdit: () => onEditHabit(habit),
                      onDelete: () => onDeleteHabit(habit),
                    ),
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

  const _UngroupedSection({
    required this.habits,
    required this.completedToday,
    required this.onToggleHabit,
    required this.onTapHabit,
    required this.onEditHabit,
    required this.onDeleteHabit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header "Mis habitos"
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Mis hábitos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${habits.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // cards de habitos sueltos
          ...habits.map((habit) => Padding(
            key: ValueKey(habit.id),
            padding: const EdgeInsets.only(bottom: 8),
            child: HabitCard(
              habit: habit,
              isCompletedToday: completedToday[habit.id] ?? false,
              onToggle: () => onToggleHabit(habit),
              onTap: () => onTapHabit(habit),
              onEdit: () => onEditHabit(habit),
              onDelete: () => onDeleteHabit(habit),
            ),
          )),
        ],
      ),
    );
  }
}

// ==================== PROGRESO DIARIO ====================

class _DailyProgress extends StatelessWidget {
  final int completed;
  final int total;

  const _DailyProgress({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = completed == total && total > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allDone
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    allDone ? '¡Todo completado!' : 'Progreso de hoy',
                    key: ValueKey(allDone),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed de $total hábitos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              return SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 5,
                      backgroundColor: colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                      color: allDone ? AppTheme.accent : colorScheme.primary,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '${(animatedProgress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
