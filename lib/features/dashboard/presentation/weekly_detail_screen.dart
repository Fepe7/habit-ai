import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../data/stats_repository.dart';

// Vista detallada del progreso: ultimos 30 dias con grafica y desglose diario
class WeeklyDetailScreen extends StatefulWidget {
  const WeeklyDetailScreen({super.key});

  @override
  State<WeeklyDetailScreen> createState() => _WeeklyDetailScreenState();
}

class _WeeklyDetailScreenState extends State<WeeklyDetailScreen> {
  late StatsRepository _statsRepo;
  bool _initialized = false;
  bool _loading = true;
  List<DailyProgress> _progress = [];

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
      final data = await _statsRepo.getExtendedProgress(days: 30);
      if (mounted) setState(() { _progress = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // stats resumen del periodo
  int get _perfectDays =>
      _progress.where((d) => d.total > 0 && d.completed == d.total).length;

  double get _avgCompletion {
    final withData = _progress.where((d) => d.total > 0);
    if (withData.isEmpty) return 0;
    return withData.map((d) => d.percentage).reduce((a, b) => a + b) /
        withData.length;
  }

  int get _totalCompleted =>
      _progress.fold(0, (sum, d) => sum + d.completed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso mensual')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // resumen arriba
                  _buildSummaryRow(context)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05),

                  const SizedBox(height: 20),

                  // grafica de 30 dias
                  _buildChart(context)
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.05),

                  const SizedBox(height: 20),

                  // desglose diario
                  Text(
                    'Desglose diario',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 12),

                  // lista de dias (mas recientes primero)
                  ...List.generate(_progress.length, (i) {
                    final day = _progress[_progress.length - 1 - i];
                    if (day.total == 0) return const SizedBox.shrink();
                    return _DayTile(progress: day)
                        .animate()
                        .fadeIn(
                          delay: (250 + i * 30).ms,
                          duration: 300.ms,
                        );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.stars_rounded,
            label: 'Dias perfectos',
            value: '$_perfectDays',
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.trending_up_rounded,
            label: 'Media',
            value: '${(_avgCompletion * 100).round()}%',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.check_circle_rounded,
            label: 'Check-ins',
            value: '$_totalCompleted',
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Ultimos 30 dias',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final p = _progress[group.x.toInt()];
                      final date = p.date;
                      return BarTooltipItem(
                        '${date.day}/${date.month} — ${p.completed}/${p.total}',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 50,
                      getTitlesWidget: (value, _) {
                        if (value == 0 || value == 50 || value == 100) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
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
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        // solo mostrar cada 7 dias para no saturar
                        if (i % 7 != 0 && i != _progress.length - 1) {
                          return const SizedBox.shrink();
                        }
                        if (i < 0 || i >= _progress.length) {
                          return const SizedBox.shrink();
                        }
                        final date = _progress[i].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontSize: 9,
                            ),
                          ),
                        );
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
                barGroups: List.generate(_progress.length, (i) {
                  final p = _progress[i];
                  final pct = p.percentage * 100;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: pct == 0 && p.total > 0 ? 1.5 : pct,
                        color: p.total == 0
                            ? colorScheme.outlineVariant
                                .withValues(alpha: 0.15)
                            : pct >= 100
                                ? AppTheme.success
                                : AppTheme.primary.withValues(alpha: 0.7),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
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
}

// tarjeta de stat mini para el resumen
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// fila de un dia en el desglose
class _DayTile extends StatelessWidget {
  final DailyProgress progress;

  const _DayTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPerfect = progress.completed == progress.total;
    final pct = progress.percentage;
    final date = progress.date;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    const dayNames = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final dayName = isToday ? 'Hoy' : dayNames[date.weekday - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isPerfect
            ? AppTheme.success.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: isToday
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 1)
            : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        children: [
          // fecha
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday
                            ? AppTheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  '${date.day}/${date.month}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),

          // barra de progreso
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor:
                    colorScheme.outlineVariant.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(
                  isPerfect ? AppTheme.success : AppTheme.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // contador
          SizedBox(
            width: 50,
            child: Text(
              '${progress.completed}/${progress.total}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPerfect
                        ? AppTheme.success
                        : colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.right,
            ),
          ),

          if (isPerfect) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded,
                size: 16, color: AppTheme.success),
          ],
        ],
      ),
    );
  }
}
