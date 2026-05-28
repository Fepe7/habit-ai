import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/data/stats_repository.dart';
import 'widgets/mood_correlation_card.dart' show MoodCombinedChart;

// Pantalla expandida con todas las correlaciones ánimo-hábitos
class MoodInsightsScreen extends StatefulWidget {
  const MoodInsightsScreen({super.key});

  @override
  State<MoodInsightsScreen> createState() => _MoodInsightsScreenState();
}

class _MoodInsightsScreenState extends State<MoodInsightsScreen> {
  int _days = 7;
  String? _categoryFilter;
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
      _categoryFilter = null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLow,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          s.moodInsightsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _PeriodToggle(selected: _days, onChanged: _setDays),
          ),
        ],
      ),
      body: FutureBuilder<MoodCorrelationData?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data;
          if (data == null || !data.hasEnoughData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  s.moodCorrelationNotEnoughData,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // categorías disponibles para filtrar
          final categories = data.habitCorrelations
              .map((c) => c.habit.category)
              .toSet()
              .toList()
            ..sort();

          final filtered = _categoryFilter == null
              ? data.habitCorrelations
              : data.habitCorrelations
                  .where((c) => c.habit.category == _categoryFilter)
                  .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // gráfica combinada (más grande)
                _LargeChart(data: data).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // filtro por categoría
                if (categories.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: s.moodInsightsAllCategories,
                          selected: _categoryFilter == null,
                          onTap: () =>
                              setState(() => _categoryFilter = null),
                        ),
                        const SizedBox(width: 8),
                        ...categories.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CategoryChip(
                                label: cat,
                                selected: _categoryFilter == cat,
                                onTap: () =>
                                    setState(() => _categoryFilter = cat),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // lista completa de correlaciones
                ...filtered.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  return _CorrelationTile(correlation: c)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 60 * i), duration: 300.ms)
                      .slideX(begin: 0.05);
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LargeChart extends StatelessWidget {
  final MoodCorrelationData data;
  const _LargeChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: MoodCombinedChart(data: data, height: 200),
    );
  }
}

class _CorrelationTile extends StatelessWidget {
  final HabitMoodCorrelation correlation;
  const _CorrelationTile({required this.correlation});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = correlation;
    final positive = c.diff >= 0;
    final color = positive ? AppTheme.success : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                positive ? '🙂' : '😕',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.habit.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.moodCorrelationBoost(
                    positive ? '🙂' : '😕',
                    c.diffLabel,
                    c.habit.title,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${c.daysCompleted} ${s.moodCorrelationDaysCompleted}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            c.diffLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? null : AppTheme.ambientShadow(),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : scheme.onSurface,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

// Toggle compartido para reutilizar en ambas vistas
class _PeriodToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 30].map((d) {
          final active = selected == d;
          return GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 32,
              decoration: BoxDecoration(
                color: active ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                d == 7 ? s.moodCorrelationDays7 : s.moodCorrelationDays30,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
