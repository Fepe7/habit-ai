import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/stats_repository.dart';

// Detalle de categorias: grafico circular + lista con habitos y % por categoria
class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late StatsRepository _statsRepo;
  bool _initialized = false;
  bool _loading = true;
  List<CategoryDetailStat> _categories = [];
  int _touchedIndex = -1;

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
      final data = await _statsRepo.getCategoryDetailStats();
      if (mounted) setState(() { _categories = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).categoryDetailTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // grafico circular
                  _buildPieChart(context)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05),

                  const SizedBox(height: 24),

                  // tarjetas por categoria
                  ...List.generate(_categories.length, (i) {
                    return _CategoryCard(stat: _categories[i])
                        .animate()
                        .fadeIn(
                          delay: (150 + i * 80).ms,
                          duration: 400.ms,
                        )
                        .slideY(begin: 0.05);
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalHabits =
        _categories.fold<int>(0, (sum, c) => sum + c.habits.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 24,
            color: colorScheme.onSurface.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            S.of(context).categoryDetailDistribution,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: List.generate(_categories.length, (i) {
                  final cat = _categories[i];
                  final isTouched = i == _touchedIndex;
                  return PieChartSectionData(
                    color: AppTheme.categoryFg(cat.category),
                    value: cat.habits.length.toDouble(),
                    title: isTouched
                        ? '${cat.habits.length}'
                        : '${(cat.habits.length / totalHabits * 100).round()}%',
                    radius: isTouched ? 55 : 45,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 14 : 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // leyenda
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _categories.map((cat) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.categoryFg(cat.category),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppTheme.categoryLabel(cat.category),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// tarjeta expandible por categoria con habitos y % de completado
class _CategoryCard extends StatelessWidget {
  final CategoryDetailStat stat;

  const _CategoryCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final pct = (stat.completionRate * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.categoryBg(stat.category, colorScheme.brightness).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.categoryBg(stat.category, colorScheme.brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              AppTheme.categoryIcon(stat.category),
              color: AppTheme.categoryFg(stat.category, colorScheme.brightness),
              size: 20,
            ),
          ),
          title: Text(
            AppTheme.categoryLabel(stat.category),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Row(
            children: [
              Text(
                s.exploreHabitCount(stat.habits.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _completionColor(pct).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.categoryDetailWeeklyPct(pct),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _completionColor(pct),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
          children: [
            // lista de habitos de esta categoria
            ...stat.habits.map((habit) {
              return ListTile(
                dense: true,
                leading: Icon(
                  habit.currentStreak > 0
                      ? Icons.local_fire_department_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: habit.currentStreak > 0
                      ? AppTheme.accent
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                title: Text(
                  habit.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: habit.currentStreak > 0
                    ? Text(
                        s.streakDaysShort(habit.currentStreak),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                    : null,
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _completionColor(int pct) {
    if (pct >= 80) return AppTheme.success;
    if (pct >= 50) return AppTheme.accent;
    return AppTheme.error;
  }
}
