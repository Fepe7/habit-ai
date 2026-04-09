import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../data/habit_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';
import 'widgets/habit_card.dart';
import 'widgets/empty_habits_view.dart';
import 'widgets/edit_habit_sheet.dart';
import 'widgets/create_habit_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/data/achievement_checker.dart';
import '../../achievements/presentation/achievement_overlay.dart';

// Pantalla principal con la lista de habitos del dia agrupados por categoria
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late HabitRepository _habitRepo;
  late AchievementChecker _achievementChecker;
  final Map<String, bool> _completedToday = {};
  bool _initialized = false;
  // ids de habitos que ya se consultaron para no repetir
  final Set<String> _logsFetched = {};
  // habitos de hoy para pasar al checker
  List<HabitModel> _currentTodayHabits = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _habitRepo = HabitRepository(uid: user.uid);
        _achievementChecker = AchievementChecker(
          achievementRepo: AchievementRepository(uid: user.uid),
          habitRepo: _habitRepo,
        );
      }
      _initialized = true;
    }
  }

  // cargar logs de hoy solo para habitos nuevos que no se hayan consultado
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

    // UI optimista
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

        // comprobar logros tras completar
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
      } else {
        // desmarcar: borra log + recalcula racha
        await _habitRepo.uncheckAndRecalculate(habit.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _completedToday[habit.id] = wasCompleted;
        });
      }
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al actualizar el hábito'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          'El hábito se desactivará y no aparecerá en tu lista, '
          'pero se conservará el historial.',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${habit.title}" eliminado'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al eliminar el hábito'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hábito creado'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // comprobar logros tras crear
        final unlocked = await _achievementChecker.checkAfterCreate();
        if (unlocked.isNotEmpty && mounted) {
          AchievementOverlay.showUnlocked(context, unlocked);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al crear el hábito'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Map<String, List<HabitModel>> _groupByCategory(List<HabitModel> habits) {
    final groups = <String, List<HabitModel>>{};
    for (final habit in habits) {
      groups.putIfAbsent(habit.category, () => []).add(habit);
    }
    return groups;
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
      body: StreamBuilder<List<HabitModel>>(
        stream: _habitRepo.watchTodayHabits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar hábitos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
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

          final habits = snapshot.data ?? [];
          _currentTodayHabits = habits;

          if (habits.isEmpty) {
            return EmptyHabitsView(
              onCreatePlan: () => context.go('/ai'),
            );
          }

          // cargar logs fuera del build propiamente dicho
          _fetchLogsIfNeeded(habits);

          final completedCount = habits.where(
            (h) => _completedToday[h.id] == true,
          ).length;

          final groups = _groupByCategory(habits);

          return Column(
            children: [
              _DailyProgress(
                completed: completedCount,
                total: habits.length,
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _countItems(groups),
                  itemBuilder: (context, index) {
                    final item = _getItem(groups, index);

                    if (item is _CategoryHeader) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: item.isFirst ? 0 : 16,
                          bottom: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.categoryBg(item.category),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                AppTheme.categoryIcon(item.category),
                                size: 16,
                                color: AppTheme.categoryFg(item.category),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppTheme.categoryLabel(item.category),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.categoryFg(item.category),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.count}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms);
                    }

                    final habitItem = item as _HabitItem;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HabitCard(
                        habit: habitItem.habit,
                        isCompletedToday: _completedToday[habitItem.habit.id] ?? false,
                        onToggle: () => _toggleHabit(habitItem.habit),
                        onTap: () => context.go('/habit/${habitItem.habit.id}'),
                        onEdit: () => _editHabit(habitItem.habit),
                        onDelete: () => _deleteHabit(habitItem.habit),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: habitItem.animIndex * 80),
                          duration: 350.ms,
                        )
                        .slideX(
                          begin: 0.05,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _countItems(Map<String, List<HabitModel>> groups) {
    int count = 0;
    for (final entry in groups.entries) {
      count += 1 + entry.value.length;
    }
    return count;
  }

  Object _getItem(Map<String, List<HabitModel>> groups, int index) {
    int current = 0;
    int animIndex = 0;
    bool isFirst = true;
    for (final entry in groups.entries) {
      if (current == index) {
        return _CategoryHeader(
          category: entry.key,
          count: entry.value.length,
          isFirst: isFirst,
        );
      }
      current++;
      for (final habit in entry.value) {
        if (current == index) {
          return _HabitItem(habit: habit, animIndex: animIndex);
        }
        current++;
        animIndex++;
      }
      isFirst = false;
    }
    return _CategoryHeader(category: '', count: 0, isFirst: true);
  }

  String _todayFormatted() {
    final now = DateTime.now();
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

class _CategoryHeader {
  final String category;
  final int count;
  final bool isFirst;
  _CategoryHeader({required this.category, required this.count, required this.isFirst});
}

class _HabitItem {
  final HabitModel habit;
  final int animIndex;
  _HabitItem({required this.habit, required this.animIndex});
}

class _DailyProgress extends StatelessWidget {
  final int completed;
  final int total;

  const _DailyProgress({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = completed == total && total > 0;

    return Container(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allDone ? '¡Todo completado!' : 'Progreso de hoy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  color: allDone ? AppTheme.accent : colorScheme.primary,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
