import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ux/skeletons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/data/stats_repository.dart';

// Card del dashboard con gráfica combinada ánimo + hábitos y top correlaciones
class MoodCorrelationCard extends StatefulWidget {
  const MoodCorrelationCard({super.key});

  @override
  State<MoodCorrelationCard> createState() => _MoodCorrelationCardState();
}

class _MoodCorrelationCardState extends State<MoodCorrelationCard> {
  int _days = 7;
  late Future<MoodCorrelationData?> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _future = Future.value(null);
      return;
    }
    _future = StatsRepository(uid: uid).getMoodHabitCorrelation(days: _days);
  }

  void _setDays(int days) {
    setState(() {
      _days = days;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return FutureBuilder<MoodCorrelationData?>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;

        return GestureDetector(
          onTap: loading || !(snap.data?.hasEnoughData ?? false)
              ? null
              : () => context.goNamed('mood-insights'),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.ambientShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header
                Row(
                  children: [
                    const Text('🔗', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.moodCorrelationTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    // toggle 7/30 días
                    _PeriodToggle(
                      selected: _days,
                      onChanged: _setDays,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (loading)
                  const ChartSkeleton(height: 140)
                else if (snap.data == null || !snap.data!.hasEnoughData)
                  _NotEnoughData()
                else ...[
                  MoodCombinedChart(data: snap.data!),
                  const SizedBox(height: 16),
                  _TopCorrelations(data: snap.data!),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
        );
      },
    );
  }
}

// Gráfica combinada pública: barras (% hábitos) + línea (ánimo)
// Usada tanto en la card del dashboard como en MoodInsightsScreen
class MoodCombinedChart extends StatelessWidget {
  final MoodCorrelationData data;
  final double height;
  const MoodCombinedChart({super.key, required this.data, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // barras de hábitos
          BarChart(_buildBarData(context)),
          // línea de ánimo superpuesta
          _MoodLineOverlay(data: data),
        ],
      ),
    );
  }

  BarChartData _buildBarData(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = data.days;

    return BarChartData(
      maxY: 1.0,
      barTouchData: BarTouchData(enabled: false),
      alignment: BarChartAlignment.spaceAround,
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 0.5,
            getTitlesWidget: (v, meta) {
              if (v == 0 || v == 0.5 || v == 1.0) {
                return Text(
                  '${(v * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 9,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
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
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= days.length) return const SizedBox.shrink();
              final isToday = i == days.length - 1;

              // 30 días: solo cada ~5 días + hoy, formato d/M
              if (days.length > 7) {
                if (!isToday && i % 5 != 0) return const SizedBox.shrink();
                final d = days[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.day}/${d.month}',
                    style: TextStyle(
                      fontSize: 8,
                      color: isToday
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _dayLabel(days[i].date),
                  style: TextStyle(
                    fontSize: 9,
                    color: isToday
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w400,
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
        horizontalInterval: 0.5,
        getDrawingHorizontalLine: (_) => FlLine(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(days.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: days[i].habitCompletionPct,
              width: days.length <= 7 ? 16 : 8,
              borderRadius: BorderRadius.circular(4),
              color: scheme.primary.withValues(alpha: 0.25),
            ),
          ],
        );
      }),
    );
  }

  String _dayLabel(DateTime d) {
    const short = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return short[d.weekday - 1];
  }
}

// Línea de ánimo superpuesta sobre el BarChart
class _MoodLineOverlay extends StatelessWidget {
  final MoodCorrelationData data;
  const _MoodLineOverlay({required this.data});

  @override
  Widget build(BuildContext context) {
    final days = data.days;

    // spots solo donde hay datos
    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      final avg = days[i].moodAvg;
      if (avg != null) {
        // normaliza 1-5 → 0-1 para coincidir con la escala del BarChart
        spots.add(FlSpot(i.toDouble(), (avg - 1) / 4));
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppTheme.success,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: AppTheme.success,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 0.5,
              getTitlesWidget: (v, meta) {
                if (v == 0) return const Text('😞', style: TextStyle(fontSize: 12));
                if (v == 0.5) return const Text('😐', style: TextStyle(fontSize: 12));
                if (v == 1.0) return const Text('😄', style: TextStyle(fontSize: 12));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class _TopCorrelations extends StatelessWidget {
  final MoodCorrelationData data;
  const _TopCorrelations({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final positive = data.positiveCorrelations.take(3).toList();
    final negative = data.negativeCorrelations.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...positive.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text('🙂', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.moodCorrelationBoost('🙂', c.diffLabel, c.habit.title),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${c.daysCompleted} ${s.moodCorrelationDaysCompleted}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )),
        if (negative.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...negative.map((c) {
            final absDiff = c.diff.abs().toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.moodCorrelationDrop(c.habit.title, absDiff),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _NotEnoughData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: Text(
        S.of(context).moodCorrelationNotEnoughData,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 30].map((d) {
          final active = selected == d;
          return GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 28,
              decoration: BoxDecoration(
                color: active ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                d == 7 ? s.moodCorrelationDays7 : s.moodCorrelationDays30,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: active ? Colors.white : scheme.onSurfaceVariant,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
