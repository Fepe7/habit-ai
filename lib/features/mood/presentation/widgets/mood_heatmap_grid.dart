import 'package:flutter/material.dart';
import '../../domain/mood_entry_model.dart';
import 'mood_day_detail_sheet.dart';

// Colores del heatmap por rating (1-5) y sin datos
const _ratingColors = {
  1: Color(0xFFEF4444),
  2: Color(0xFFF59E0B),
  3: Color(0xFFFBBF24),
  4: Color(0xFF34D399),
  5: Color(0xFF10B981),
};
const _emptyColor = Color(0xFFE2E8F0);
const _outsideColor = Color(0xFFF8FAFC);

// Grid mensual tipo GitHub con colores según ánimo medio diario
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

  // Agrupa entries por día del mes
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

  Color _colorForAvg(double? avg) {
    if (avg == null) return _emptyColor;
    final r = avg.round().clamp(1, 5);
    return _ratingColors[r]!;
  }

  @override
  Widget build(BuildContext context) {
    final byDay = _byDay();
    final firstDay = DateTime(year, month, 1);
    // weekday 1=lun … 7=dom; offset para que lunes sea col 0
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // total celdas = offset + días del mes, redondeado a múltiplo de 7
    final totalCells = (startOffset + daysInMonth + 6) ~/ 7 * 7;

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
              color: _outsideColor,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }

        final dayEntries = byDay[dayNumber];
        final avg = _avgForDay(dayEntries);
        final color = _colorForAvg(avg);
        final date = DateTime(year, month, dayNumber);

        return GestureDetector(
          onTap: () {
            if (dayEntries == null || dayEntries.isEmpty) return;
            MoodDayDetailSheet.show(
              context,
              date: date,
              entries: dayEntries,
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
                  color: inMonth && avg != null
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Leyenda de colores para el heatmap
class MoodHeatmapLegend extends StatelessWidget {
  const MoodHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: _emptyColor, label: '—'),
        const SizedBox(width: 8),
        for (int r = 1; r <= 5; r++) ...[
          _LegendDot(color: _ratingColors[r]!, label: '$r'),
          if (r < 5) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

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
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
