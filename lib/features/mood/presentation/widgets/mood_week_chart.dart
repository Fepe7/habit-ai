import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ux/skeletons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';
import 'mood_entry_sheet.dart';

// Gráfica de líneas con el ánimo medio de los últimos 7 días
class MoodWeekChart extends StatefulWidget {
  final VoidCallback? onAddPressed;

  const MoodWeekChart({super.key, this.onAddPressed});

  @override
  State<MoodWeekChart> createState() => _MoodWeekChartState();
}

class _MoodWeekChartState extends State<MoodWeekChart> {
  // índice del punto tocado para tooltip (-1 = ninguno)
  int _touchedIndex = -1;
  late Future<_WeekData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_WeekData> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const _WeekData([]);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    final entries =
        await MoodRepository(uid: uid).getEntriesForRange(start, end);

    // agrupa por día (índice 0 = 6 días atrás, 6 = hoy)
    final Map<int, List<double>> byDay = {};
    for (final e in entries) {
      final diff = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day)
          .difference(start)
          .inDays;
      if (diff >= 0 && diff <= 6) {
        byDay.putIfAbsent(diff, () => []).add(e.rating.toDouble());
      }
    }

    final days = List.generate(7, (i) {
      final date = start.add(Duration(days: i));
      final ratings = byDay[i];
      final avg = ratings == null
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length;
      // labels + note del primer entry del día para tooltip
      final dayEntries = entries.where((e) {
        final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
        return d == DateTime(date.year, date.month, date.day);
      }).toList();
      return _DayPoint(date: date, avg: avg, entries: dayEntries);
    });

    return _WeekData(days);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WeekData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _ChartShell(
            onAddPressed: widget.onAddPressed,
            child: const ChartSkeleton(height: 150),
          );
        }

        final data = snap.data ?? const _WeekData([]);

        if (data.days.every((d) => d.avg == null)) {
          return _ChartShell(
            onAddPressed: widget.onAddPressed,
            child: _EmptyMood(
              onTap: widget.onAddPressed ??
                  () => MoodEntrySheet.show(context),
            ),
          );
        }

        return _ChartShell(
          onAddPressed: widget.onAddPressed,
          child: SizedBox(
            height: 150,
            child: LineChart(_buildChartData(context, data)),
          ),
        );
      },
    );
  }

  LineChartData _buildChartData(BuildContext context, _WeekData data) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final primary = AppTheme.primary;
    final success = AppTheme.success;

    // separa los spots en segmentos contiguos para mostrar gaps reales
    final segments = <List<FlSpot>>[];
    List<FlSpot>? current;

    for (int i = 0; i < data.days.length; i++) {
      final avg = data.days[i].avg;
      if (avg != null) {
        current ??= [];
        current.add(FlSpot(i.toDouble(), avg));
      } else {
        if (current != null && current.isNotEmpty) {
          segments.add(current);
          current = null;
        }
      }
    }
    if (current != null && current.isNotEmpty) segments.add(current);

    final barDataList = segments.map((spots) {
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        preventCurveOverShooting: true,
        gradient: LinearGradient(colors: [primary, success]),
        barWidth: 2.5,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final dayIndex = spot.x.toInt();
            final touched = _touchedIndex == dayIndex;
            // cada dot usa el color de MoodTheme para su rating
            final avg = data.days[dayIndex].avg;
            final dotColor = avg != null
                ? MoodTheme.ratingAccent(avg.round().clamp(1, 5), brightness)
                : primary;
            return FlDotCirclePainter(
              radius: touched ? 6 : 4,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: dotColor,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.18),
              success.withValues(alpha: 0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }).toList();

    return LineChartData(
      minY: 0.5,
      maxY: 5.5,
      lineBarsData: barDataList,
      lineTouchData: LineTouchData(
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions ||
              response == null ||
              response.lineBarSpots == null) {
            setState(() => _touchedIndex = -1);
            return;
          }
          final x = response.lineBarSpots!.first.x.toInt();
          setState(() => _touchedIndex = x);
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBorderRadius: BorderRadius.circular(12),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final dayIndex = spot.x.toInt();
              final point = data.days[dayIndex];
              final labels = point.entries
                  .expand((e) => e.labels)
                  .toSet()
                  .take(3)
                  .join(', ');
              return LineTooltipItem(
                '${point.emoji}  ${spot.y.toStringAsFixed(1)}\n'
                '${labels.isNotEmpty ? labels : ''}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              const map = {1: '😞', 2: '😕', 3: '😐', 4: '🙂', 5: '😄'};
              final emoji = map[value.round()];
              if (emoji == null || value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              return Text(emoji, style: const TextStyle(fontSize: 13));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= data.days.length) {
                return const SizedBox.shrink();
              }
              final date = data.days[i].date;
              final isToday = i == 6;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _shortDay(context, date.weekday),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? scheme.primary
                        : scheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
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
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }

  String _shortDay(BuildContext context, int weekday) {
    final s = S.of(context);
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    // usa iniciales del locale
    final full = [
      s.weekdayMonday, s.weekdayTuesday, s.weekdayWednesday,
      s.weekdayThursday, s.weekdayFriday, s.weekdaySaturday, s.weekdaySunday,
    ];
    final idx = weekday - 1;
    if (idx < 0 || idx >= full.length) return labels[0];
    return full[idx].substring(0, 1).toUpperCase();
  }
}

// Shell que envuelve el chart con el header de sección
class _ChartShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onAddPressed;

  const _ChartShell({required this.child, this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('😊', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.moodWeekChart,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              GestureDetector(
                onTap: onAddPressed ?? () => MoodEntrySheet.show(context),
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _EmptyMood extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyMood({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.moodEmptyState,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 6),
              Text(
                s.moodEmptyStateCta,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// datos de la semana procesados
class _WeekData {
  final List<_DayPoint> days;
  const _WeekData(this.days);
}

class _DayPoint {
  final DateTime date;
  final double? avg; // null = sin datos
  final List<MoodEntryModel> entries;

  const _DayPoint({
    required this.date,
    required this.avg,
    required this.entries,
  });

  String get emoji {
    if (avg == null) return '';
    final r = avg!.round().clamp(1, 5);
    const map = {1: '😞', 2: '😕', 3: '😐', 4: '🙂', 5: '😄'};
    return map[r]!;
  }
}
