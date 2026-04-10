import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../data/stats_repository.dart';
import '../../habits/domain/habit_model.dart';
import '../../achievements/data/archivement_repository.dart';
import '../../achievements/domain/achivement_model.dart';
import '../../ai/data/ai_repository.dart';
import '../../ai/domain/weekly_review_model.dart';

// Dashboard con graficas de progreso y estadisticas
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StatsRepository _statsRepo;
  late AchievementRepository _achievementRepo;
  late AIRepository _aiRepo;
  bool _initialized = false;
  bool _generatingReview = false;

  // datos cargados
  Map<String, dynamic> _generalStats = {};
  List<DailyProgress> _weeklyProgress = [];
  List<CategoryStat> _categoryStats = [];
  List<HabitModel> _topStreaks = [];
  List<AchievementModel> _achievements = [];
  bool _loading = true;

  // dias de la semana donde se completo el 100%
  int get _perfectDays => _weeklyProgress
      .where((d) => d.total > 0 && d.completed == d.total)
      .length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = AuthProvider.of(context);
      final user = auth.currentUser;
      if (user != null) {
        _statsRepo = StatsRepository(uid: user.uid);
        _achievementRepo = AchievementRepository(uid: user.uid);
        _aiRepo = AIRepository(uid: user.uid);
        _loadStats();
      }
      _initialized = true;
    }
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _statsRepo.getGeneralStats(),
        _statsRepo.getWeeklyProgress(),
        _statsRepo.getCategoryDistribution(),
        _statsRepo.getTopStreaks(),
        _achievementRepo.watchAchievements().first,
      ]);

      if (mounted) {
        setState(() {
          _generalStats = results[0] as Map<String, dynamic>;
          _weeklyProgress = results[1] as List<DailyProgress>;
          _categoryStats = results[2] as List<CategoryStat>;
          _topStreaks = results[3] as List<HabitModel>;
          _achievements = results[4] as List<AchievementModel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _generalStats['totalActive'] == 0
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // resumen de hoy
                        _buildTodaySummary(context)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.05),

                        const SizedBox(height: 16),

                        // tarjetas de stats
                        _buildStatCards(context)
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.05),

                        const SizedBox(height: 16),

                        // revision semanal con IA
                        _buildWeeklyReviewCard(context)
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 400.ms)
                            .slideY(begin: 0.05),

                        const SizedBox(height: 20),

                        // grafica semanal (tappable)
                        GestureDetector(
                          onTap: () => context.goNamed('dashboard-weekly'),
                          child: _buildWeeklyChart(context),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(begin: 0.05),

                        const SizedBox(height: 20),

                        // distribucion por categorias (tappable)
                        if (_categoryStats.isNotEmpty)
                          GestureDetector(
                            onTap: () =>
                                context.goNamed('dashboard-categories'),
                            child: _buildCategoryChart(context),
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 400.ms)
                              .slideY(begin: 0.05),

                        if (_topStreaks.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          // rachas (tappable)
                          GestureDetector(
                            onTap: () =>
                                context.goNamed('dashboard-streaks'),
                            child: _buildTopStreaks(context),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .slideY(begin: 0.05),
                        ],

                        const SizedBox(height: 20),

                        // logros (tappable)
                        GestureDetector(
                          onTap: () => context.goNamed('achievements'),
                          child: _buildAchievements(context),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 400.ms)
                            .slideY(begin: 0.05),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Dispara la generacion manual desde el boton del card
  Future<void> _generateReviewManually() async {
    setState(() => _generatingReview = true);
    try {
      final weekId = await _aiRepo.generateWeeklyReview();
      if (!mounted) return;
      if (weekId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Necesitas al menos 3 check-ins esta semana para generar la revisión',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingReview = false);
    }
  }

  // Card de revision semanal: muestra la ultima o invita a generar
  Widget _buildWeeklyReviewCard(BuildContext context) {
    return StreamBuilder<WeeklyReviewModel?>(
      stream: _aiRepo.watchLatestWeeklyReview(),
      builder: (context, snapshot) {
        final review = snapshot.data;
        final colorScheme = Theme.of(context).colorScheme;

        if (review == null) {
          // estado vacio: invitar a generar manualmente
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.12),
                  AppTheme.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: AppTheme.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisión semanal',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'La IA analiza tu semana cada lunes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed:
                            _generatingReview ? null : _generateReviewManually,
                        icon: _generatingReview
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text(
                          _generatingReview
                              ? 'Generando…'
                              : 'Generar ahora',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ya existe una revision: mostrarla con tap para detalle
        return GestureDetector(
          onTap: () => context.goNamed(
            'weekly-review',
            pathParameters: {'weekId': review.weekId},
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded,
                        color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Revisión semanal',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Text(
                      review.weekId,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5)),
                  ],
                ),
                if (review.focus.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    review.focus,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos todavia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea habitos y completa check-ins para ver tus estadisticas aqui',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // tarjeta grande con progreso de hoy
  Widget _buildTodaySummary(BuildContext context) {
    final completed = _generalStats['completedToday'] ?? 0;
    final total = _generalStats['todayTotal'] ?? 0;
    final percentage = total == 0 ? 0.0 : completed / total;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // circulo de progreso
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 6,
                  backgroundColor:
                      colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    percentage == 1.0 ? AppTheme.success : AppTheme.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${(percentage * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: percentage == 1.0
                            ? AppTheme.success
                            : AppTheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'No tienes habitos programados hoy'
                      : '$completed de $total completados',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (percentage == 1.0 && total > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dia perfecto!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // fila de stats: racha, completados, activos
  Widget _buildStatCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Mejor racha',
            value: '${_generalStats['bestStreak'] ?? 0}',
            suffix: 'd',
            color: AppTheme.accent,
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Completados',
            value: '${_generalStats['totalCompletedAllTime'] ?? 0}',
            color: AppTheme.success,
            bgColor: const Color(0xFFCCFBF1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.stars_rounded,
            label: 'Dias perfectos',
            value: '$_perfectDays',
            color: AppTheme.secondary,
            bgColor: const Color(0xFFE0F2FE),
          ),
        ),
      ],
    );
  }

  // grafica de barras con el progreso semanal
  Widget _buildWeeklyChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ultima semana',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final progress = _weeklyProgress[group.x.toInt()];
                      return BarTooltipItem(
                        '${progress.completed}/${progress.total}',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 50 || value == 100) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _weeklyProgress.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _dayLabel(_weeklyProgress[index].date),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: _isToday(
                                        _weeklyProgress[index].date)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_weeklyProgress.length, (i) {
                  final progress = _weeklyProgress[i];
                  final pct = (progress.percentage * 100);
                  final isToday = _isToday(progress.date);

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: pct == 0 && progress.total > 0 ? 2 : pct,
                        color: progress.total == 0
                            ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                            : pct >= 100
                                ? AppTheme.success
                                : isToday
                                    ? AppTheme.primary
                                    : AppTheme.primary.withValues(alpha: 0.6),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // distribucion por categorias con barras horizontales
  Widget _buildCategoryChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalHabits = _categoryStats.fold<int>(0, (sum, c) => sum + c.count);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Por categoria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          ..._categoryStats.map((stat) {
            final fraction = stat.count / totalHabits;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.categoryBg(stat.category),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      AppTheme.categoryIcon(stat.category),
                      size: 16,
                      color: AppTheme.categoryFg(stat.category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppTheme.categoryLabel(stat.category),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${stat.count}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: colorScheme.outlineVariant
                                .withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.categoryFg(stat.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // top rachas activas
  Widget _buildTopStreaks(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 20, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rachas activas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          ..._topStreaks.map((habit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      habit.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.currentStreak}d',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // seccion de logros con los ultimos desbloqueados
  Widget _buildAchievements(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unlockedTypes = _achievements.map((a) => a.type).toSet();
    final total = AchievementCatalog.all.length;
    final count = unlockedTypes.length;

    // mostrar hasta 4 logros recientes
    final recent = _achievements.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 20, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Logros',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '$count/$total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Text(
              'Completa habitos para desbloquear logros',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: recent.map((achievement) {
                final info = AchievementCatalog.getInfo(achievement.type);
                return Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: info.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(info.icon, color: info.color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 60,
                      child: Text(
                        info.title,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // helpers de fecha
  String _dayLabel(DateTime date) {
    if (_isToday(date)) return 'Hoy';
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return days[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.7),
                        ),
                  ),
              ],
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
