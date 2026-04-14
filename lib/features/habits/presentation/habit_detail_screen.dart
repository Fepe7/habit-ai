import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/habit_repository.dart';
import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import 'widgets/edit_habit_sheet.dart';

// Pantalla de detalle de un hábito con diseño Editorial Vitality
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

    // últimos 30 días de logs
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
    HapticFeedback.mediumImpact();

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
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_habit == null) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        appBar: AppBar(),
        body: const Center(child: Text('Hábito no encontrado')),
      );
    }

    final habit = _habit!;
    final catBg = AppTheme.categoryBg(habit.category);
    final catFg = AppTheme.categoryFg(habit.category);
    final catIcon = AppTheme.categoryIcon(habit.category);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          // header hero con gradiente
          _HeroHeader(
            habit: habit,
            catBg: catBg,
            catFg: catFg,
            catIcon: catIcon,
            isCompleted: _completedToday,
            onEdit: _editHabit,
            onDelete: _deleteHabit,
          ),

          // contenido principal
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // tarjeta de rachas con números display-lg
                _StreakCard(habit: habit)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 16),

                // botón check-in
                _CheckInButton(
                  isCompleted: _completedToday,
                  onToggle: _toggleToday,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 24),

                // sección actividad últimos 30 días
                _SectionLabel(label: 'Últimos 30 días')
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),
                const SizedBox(height: 12),

                _ActivityGrid(logs: _recentLogs)
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 300.ms),
                const SizedBox(height: 24),

                // info adicional
                _SectionLabel(label: 'Información')
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms),
                const SizedBox(height: 12),

                _InfoCard(habit: habit)
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 300.ms)
                    .slideY(begin: 0.05),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HEADER HERO ====================

class _HeroHeader extends StatelessWidget {
  final HabitModel habit;
  final Color catBg;
  final Color catFg;
  final IconData catIcon;
  final bool isCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeroHeader({
    required this.habit,
    required this.catBg,
    required this.catFg,
    required this.catIcon,
    required this.isCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: scheme.surfaceContainerLow,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          onPressed: onEdit,
        ),
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          onPressed: onDelete,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isCompleted
                ? AppTheme.streakGradient
                : AppTheme.heroGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // icono categoría grande
                  Hero(
                    tag: 'habit_cat_${habit.id}',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(catIcon, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // chip categoría
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppTheme.categoryLabel(habit.category),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          habit.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (habit.isAIGenerated) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Generado por IA',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
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

// ==================== STREAK CARD ====================

class _StreakCard extends StatelessWidget {
  final HabitModel habit;

  const _StreakCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Row(
        children: [
          // racha actual con glow terciario
          Expanded(
            child: _StreakColumn(
              icon: Icons.local_fire_department_rounded,
              iconColor: scheme.tertiary,
              glowColor: scheme.tertiaryContainer.withValues(alpha: 0.4),
              value: '${habit.currentStreak}',
              label: 'Racha actual',
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
          // mejor racha
          Expanded(
            child: _StreakColumn(
              icon: Icons.emoji_events_rounded,
              iconColor: scheme.tertiary,
              glowColor: scheme.tertiaryContainer.withValues(alpha: 0.3),
              value: '${habit.bestStreak}',
              label: 'Mejor racha',
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color glowColor;
  final String value;
  final String label;

  const _StreakColumn({
    required this.icon,
    required this.iconColor,
    required this.glowColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ícono con glow
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: glowColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 12),
        // número grande display-lg
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'días',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==================== CHECK-IN BUTTON ====================

class _CheckInButton extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onToggle;

  const _CheckInButton({
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isCompleted) {
      // estado completado: botón surface con check verde
      return GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.tertiary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: scheme.tertiary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Completado hoy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GradientButton(
      onPressed: onToggle,
      label: 'Marcar como completado',
      icon: Icons.radio_button_unchecked_rounded,
      gradient: AppTheme.heroGradient,
    );
  }
}

// ==================== ACTIVITY GRID ====================

class _ActivityGrid extends StatelessWidget {
  final List<HabitLogModel> logs;

  const _ActivityGrid({required this.logs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // set de fechas completadas para búsqueda rápida
    final completedDates = <String>{};
    for (final log in logs) {
      if (log.completed) {
        completedDates.add(_dateKey(log.date));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(30, (i) {
          final date = now.subtract(Duration(days: 29 - i));
          final key = _dateKey(date);
          final done = completedDates.contains(key);
          final isToday = i == 29;

          return Tooltip(
            message:
                '${date.day}/${date.month} — ${done ? "Completado" : "No completado"}',
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                // completado: gradiente hero; hoy sin completar: borde primary; resto: surface
                gradient: done ? AppTheme.heroGradient : null,
                color: done
                    ? null
                    : isToday
                        ? scheme.primaryContainer.withValues(alpha: 0.15)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: isToday && !done
                    ? Border.all(
                        color: scheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          );
        }),
      ),
    );
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

// ==================== INFO CARD ====================

class _InfoCard extends StatelessWidget {
  final HabitModel habit;

  const _InfoCard({required this.habit});

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days =
        habit.targetDays.map((d) => _dayNames[d - 1]).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.repeat_rounded,
            label: 'Frecuencia',
            value: habit.frequency == 'daily' ? 'Diario' : habit.frequency,
          ),
          Divider(
            height: 1,
            indent: 56,
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Días',
            value: days.isNotEmpty ? days : 'Todos',
          ),
          if (habit.reminderTime != null) ...[
            Divider(
              height: 1,
              indent: 56,
              color: scheme.outlineVariant.withValues(alpha: 0.12),
            ),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Recordatorio',
              value: habit.reminderTime!,
            ),
          ],
        ],
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPERS ====================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
