import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/habit_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/edit_habit_sheet.dart';

// Pantalla de detalle de un habito: info, rachas, historial de check-ins
class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late final HabitRepository _habitRepo;
  HabitModel? _habit;
  List<HabitLogModel> _recentLogs = [];
  bool _completedToday = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _habitRepo = HabitRepository(uid: uid);
    _loadData();
  }

  Future<void> _loadData() async {
    final habit = await _habitRepo.getHabit(widget.habitId);
    if (habit == null || !mounted) return;

    final todayLog = await _habitRepo.getTodayLog(widget.habitId);

    // ultimos 30 dias de logs
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final logs = await _habitRepo.getLogsByDateRange(
      habitId: widget.habitId,
      startDate: thirtyDaysAgo,
      endDate: now,
    );

    if (mounted) {
      setState(() {
        _habit = habit;
        _completedToday = todayLog?.completed ?? false;
        _recentLogs = logs;
        _loading = false;
      });
    }
  }

  Future<void> _toggleToday() async {
    if (_habit == null) return;
    final wasCompleted = _completedToday;

    setState(() => _completedToday = !wasCompleted);

    try {
      if (!wasCompleted) {
        final log = HabitLogModel(
          id: '',
          date: DateTime.now(),
          completed: true,
        );
        await _habitRepo.addLog(widget.habitId, log);
        await _habitRepo.updateStreak(widget.habitId);
      } else {
        await _habitRepo.uncheckAndRecalculate(widget.habitId);
      }
      await _loadData();
    } catch (e) {
      if (mounted) setState(() => _completedToday = wasCompleted);
    }
  }

  Future<void> _editHabit() async {
    if (_habit == null) return;
    final updated = await EditHabitSheet.show(context, _habit!);
    if (updated == null) return;

    await _habitRepo.updateHabit(_habit!.id, {
      'title': updated.title,
      'description': updated.description,
      'category': updated.category,
      'frequency': updated.frequency,
      'targetDays': updated.targetDays,
      'reminderTime': updated.reminderTime,
    });
    await _loadData();
  }

  Future<void> _deleteHabit() async {
    if (_habit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text(
          '¿Seguro que quieres eliminar "${_habit!.title}"?\n\n'
          'Se desactivará y no aparecerá en tu lista, '
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

    if (confirmed != true || !mounted) return;

    await _habitRepo.deactivateHabit(_habit!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_habit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Hábito no encontrado')),
      );
    }

    final habit = _habit!;
    final catBg = AppTheme.categoryBg(habit.category);
    final catFg = AppTheme.categoryFg(habit.category);
    final catIcon = AppTheme.categoryIcon(habit.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: _editHabit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.error),
            tooltip: 'Eliminar',
            onPressed: _deleteHabit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // cabecera con titulo, categoria e icono
          _HeaderCard(
            habit: habit,
            catBg: catBg,
            catFg: catFg,
            catIcon: catIcon,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
          const SizedBox(height: 16),

          // rachas
          _StreakCard(habit: habit)
              .animate()
              .fadeIn(delay: 100.ms, duration: 300.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: 16),

          // boton de check-in
          _CheckInButton(
            isCompleted: _completedToday,
            onToggle: _toggleToday,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 24),

          // historial ultimos 30 dias
          Text(
            'Últimos 30 días',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          const SizedBox(height: 12),

          _ActivityGrid(
            logs: _recentLogs,
            catFg: catFg,
          ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
          const SizedBox(height: 24),

          // info extra
          _InfoSection(habit: habit, colorScheme: colorScheme)
              .animate()
              .fadeIn(delay: 400.ms, duration: 300.ms),
        ],
      ),
    );
  }
}

// cabecera con nombre, descripcion y categoria
class _HeaderCard extends StatelessWidget {
  final HabitModel habit;
  final Color catBg;
  final Color catFg;
  final IconData catIcon;

  const _HeaderCard({
    required this.habit,
    required this.catBg,
    required this.catFg,
    required this.catIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catFg, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Hero(
                        tag: 'habit_cat_${habit.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: catBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(catIcon, size: 12, color: catFg),
                                const SizedBox(width: 4),
                                Text(
                                  AppTheme.categoryLabel(habit.category),
                                  style: TextStyle(
                                    color: catFg,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                habit.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (habit.isAIGenerated) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Generado por IA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// tarjeta de rachas
class _StreakCard extends StatelessWidget {
  final HabitModel habit;

  const _StreakCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _StreakStat(
                icon: Icons.local_fire_department,
                iconColor: AppTheme.accent,
                label: 'Racha actual',
                value: '${habit.currentStreak}',
                unit: 'días',
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _StreakStat(
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.accent,
                label: 'Mejor racha',
                value: '${habit.bestStreak}',
                unit: 'días',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _StreakStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// boton grande de marcar hoy con transicion animada
class _CheckInButton extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onToggle;

  const _CheckInButton({
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: FilledButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onToggle();
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            key: ValueKey(isCompleted),
          ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isCompleted ? 'Completado hoy' : 'Marcar como completado',
            key: ValueKey(isCompleted),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: isCompleted ? AppTheme.success : null,
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
    );
  }
}

// grid de actividad de los ultimos 30 dias (cuadraditos tipo GitHub)
class _ActivityGrid extends StatelessWidget {
  final List<HabitLogModel> logs;
  final Color catFg;

  const _ActivityGrid({required this.logs, required this.catFg});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // set de fechas completadas para busqueda rapida
    final completedDates = <String>{};
    for (final log in logs) {
      if (log.completed) {
        completedDates.add(_dateKey(log.date));
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(30, (i) {
        final date = now.subtract(Duration(days: 29 - i));
        final key = _dateKey(date);
        final done = completedDates.contains(key);
        final isToday = i == 29;

        return Tooltip(
          message: '${date.day}/${date.month} — ${done ? "Completado" : "No completado"}',
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? catFg.withValues(alpha: 0.8)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: isToday
                  ? Border.all(color: catFg, width: 2)
                  : null,
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

// info adicional: frecuencia, dias, recordatorio
class _InfoSection extends StatelessWidget {
  final HabitModel habit;
  final ColorScheme colorScheme;

  const _InfoSection({required this.habit, required this.colorScheme});

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final days = habit.targetDays.map((d) => _dayNames[d - 1]).join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.repeat,
              label: 'Frecuencia',
              value: habit.frequency == 'daily' ? 'Diario' : habit.frequency,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Días',
              value: days.isNotEmpty ? days : 'Todos',
            ),
            if (habit.reminderTime != null) ...[
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.schedule,
                label: 'Recordatorio',
                value: habit.reminderTime!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
