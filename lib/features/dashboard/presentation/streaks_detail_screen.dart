import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../data/stats_repository.dart';
import '../../habits/domain/habit_model.dart';

// Todos los habitos con sus rachas actuales y mejores
class StreaksDetailScreen extends StatefulWidget {
  const StreaksDetailScreen({super.key});

  @override
  State<StreaksDetailScreen> createState() => _StreaksDetailScreenState();
}

class _StreaksDetailScreenState extends State<StreaksDetailScreen> {
  late StatsRepository _statsRepo;
  bool _initialized = false;
  bool _loading = true;
  List<HabitModel> _habits = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _statsRepo = StatsRepository(uid: user.uid);
        _loadData();
      }
      _initialized = true;
    }
  }

  Future<void> _loadData() async {
    try {
      final data = await _statsRepo.getAllHabitsWithStreaks();
      if (mounted) setState(() { _habits = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _bestOverall {
    if (_habits.isEmpty) return 0;
    int best = 0;
    for (final h in _habits) {
      if (h.bestStreak > best) best = h.bestStreak;
      if (h.currentStreak > best) best = h.currentStreak;
    }
    return best;
  }

  int get _activeStreaks =>
      _habits.where((h) => h.currentStreak > 0).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rachas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // stats resumen
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Mejor racha global',
                          value: '${_bestOverall}d',
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.whatshot_rounded,
                          label: 'Rachas activas',
                          value: '$_activeStreaks',
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

                  const SizedBox(height: 24),

                  // separador: con racha activa
                  if (_habits.any((h) => h.currentStreak > 0)) ...[
                    _SectionHeader(
                      icon: Icons.local_fire_department_rounded,
                      title: 'En racha',
                      color: AppTheme.accent,
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _habits.where((h) => h.currentStreak > 0).length,
                      (i) {
                        final habit = _habits
                            .where((h) => h.currentStreak > 0)
                            .toList()[i];
                        return _StreakTile(habit: habit)
                            .animate()
                            .fadeIn(delay: (150 + i * 50).ms, duration: 300.ms);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // sin racha activa
                  if (_habits.any((h) => h.currentStreak == 0)) ...[
                    _SectionHeader(
                      icon: Icons.pause_circle_outline_rounded,
                      title: 'Sin racha',
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _habits.where((h) => h.currentStreak == 0).length,
                      (i) {
                        final habit = _habits
                            .where((h) => h.currentStreak == 0)
                            .toList()[i];
                        return _StreakTile(habit: habit, inactive: true)
                            .animate()
                            .fadeIn(delay: (250 + i * 50).ms, duration: 300.ms);
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _StreakTile extends StatelessWidget {
  final HabitModel habit;
  final bool inactive;

  const _StreakTile({required this.habit, this.inactive = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: inactive
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : AppTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: !inactive && habit.currentStreak >= 7
            ? Border.all(color: AppTheme.accent.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // icono de categoria
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.categoryBg(habit.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              AppTheme.categoryIcon(habit.category),
              size: 20,
              color: AppTheme.categoryFg(habit.category),
            ),
          ),
          const SizedBox(width: 12),

          // titulo y categoria
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  AppTheme.categoryLabel(habit.category),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),

          // rachas actual y mejor
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // racha actual
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: inactive
                        ? colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3)
                        : AppTheme.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${habit.currentStreak}d',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: inactive
                              ? colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4)
                              : AppTheme.accent,
                        ),
                  ),
                ],
              ),
              // mejor racha
              if (habit.bestStreak > 0)
                Text(
                  'mejor: ${habit.bestStreak}d',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
