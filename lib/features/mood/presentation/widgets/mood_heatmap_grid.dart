import 'package:flutter/material.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';
import 'mood_day_detail_sheet.dart';

// Grid mensual tipo GitHub con colores de MoodTheme según ánimo medio diario
class MoodHeatmapGrid extends StatelessWidget {
  final int year;
  final int month;
  final List<MoodEntryModel> entries;
  final VoidCallback? onEntryDeleted;

  const MoodHeatmapGrid({
    super.key,
    required this.year,
    required this.month,
    required this.entries,
    this.onEntryDeleted,
  });

  Map<int, List<MoodEntryModel>> _byDay() {
    final map = <int, List<MoodEntryModel>>{};
    for (final e in entries) {
      if (e.timestamp.year == year && e.timestamp.month == month) {
        map.putIfAbsent(e.timestamp.day, () => []).add(e);
      }
    }
    return map;
  }

  double? _avgForDay(List<MoodEntryModel>? dayEntries) {
    if (dayEntries == null || dayEntries.isEmpty) return null;
    final sum = dayEntries.fold<int>(0, (acc, e) => acc + e.rating);
    return sum / dayEntries.length;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final byDay = _byDay();
    final firstDay = DateTime(year, month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final totalCells = (startOffset + daysInMonth + 6) ~/ 7 * 7;

    // colores adaptativos para dark mode
    final emptyColor = scheme.surfaceContainerHighest;
    final outsideColor = scheme.surfaceContainerLow;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;
        final inMonth = dayNumber >= 1 && dayNumber <= daysInMonth;

        if (!inMonth) {
          return Container(
            decoration: BoxDecoration(
              color: outsideColor,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }

        final dayEntries = byDay[dayNumber];
        final avg = _avgForDay(dayEntries);
        final hasData = avg != null;
        final color = hasData
            ? MoodTheme.ratingAccent(avg.round().clamp(1, 5), brightness)
            : emptyColor;
        final date = DateTime(year, month, dayNumber);

        return GestureDetector(
          onTap: () {
            if (!hasData) return;
            MoodDayDetailSheet.show(
              context,
              date: date,
              entries: dayEntries!,
              onDeleted: onEntryDeleted,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasData
                      ? Colors.white.withValues(alpha: 0.9)
                      : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// leyenda con emojis y colores de MoodTheme
class MoodHeatmapLegend extends StatelessWidget {
  const MoodHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(
          color: scheme.surfaceContainerHighest,
          label: '—',
          labelColor: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        for (int r = 1; r <= 5; r++) ...[
          _LegendDot(
            color: MoodTheme.ratingAccent(r, brightness),
            label: MoodTheme.emojis[r - 1],
          ),
          if (r < 5) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final Color? labelColor;

  const _LegendDot({required this.color, required this.label, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: labelColor ??
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
