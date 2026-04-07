import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../data/habit_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';
import 'widgets/habit_card.dart';
import 'widgets/empty_habits_view.dart';
import '../../../core/theme/app_theme.dart';

// Pantalla principal con la lista de habitos del dia
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late HabitRepository _habitRepo;
  // guarda que habitos se completaron hoy
  final Map<String, bool> _completedToday = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _habitRepo = HabitRepository(uid: user.uid);
      }
      _initialized = true;
    }
  }

  // marcar/desmarcar habito como completado
  Future<void> _toggleHabit(HabitModel habit) async {
    final wasCompleted = _completedToday[habit.id] ?? false;

    // actualizar UI inmediatamente
    setState(() {
      _completedToday[habit.id] = !wasCompleted;
    });

    try {
      if (!wasCompleted) {
        // completar: crear log + actualizar racha
        final log = HabitLogModel(
          id: '',
          date: DateTime.now(),
          completed: true,
        );
        await _habitRepo.addLog(habit.id, log);
        await _habitRepo.updateStreak(habit.id);
      } else {
        // descompletar: resetear racha
        await _habitRepo.resetStreak(habit.id);
      }
    } catch (e) {
      // revertir si falla
      if (mounted) {
        setState(() {
          _completedToday[habit.id] = wasCompleted;
        });
      }
    }
  }

  // cargar estado de completado para cada habito
  Future<void> _loadTodayLogs(List<HabitModel> habits) async {
    for (final habit in habits) {
      if (!_completedToday.containsKey(habit.id)) {
        final log = await _habitRepo.getTodayLog(habit.id);
        if (mounted) {
          setState(() {
            _completedToday[habit.id] = log?.completed ?? false;
          });
        }
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
      body: StreamBuilder<List<HabitModel>>(
        stream: _habitRepo.watchTodayHabits(),
        builder: (context, snapshot) {
          // cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // error
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

          // sin habitos
          if (habits.isEmpty) {
            return EmptyHabitsView(
              onCreatePlan: () => context.go('/ai'),
            );
          }

          // cargar logs de hoy
          _loadTodayLogs(habits);

          // contar completados
          final completedCount = habits.where(
            (h) => _completedToday[h.id] == true,
          ).length;

          return Column(
            children: [
              // barra de progreso del dia
              _DailyProgress(
                completed: completedCount,
                total: habits.length,
              ),

              // lista de habitos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HabitCard(
                        habit: habit,
                        isCompletedToday: _completedToday[habit.id] ?? false,
                        onToggle: () => _toggleHabit(habit),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: index * 80),
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

  String _todayFormatted() {
    final now = DateTime.now();
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

// barra de progreso del dia
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
      child: Column(
        children: [
          Row(
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
              // porcentaje circular
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
        ],
      ),
    );
  }
}
