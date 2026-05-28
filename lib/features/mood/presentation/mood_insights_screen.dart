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

          final allCorrelations = _categoryFilter == null
              ? data.habitCorrelations
              : data.habitCorrelations
                  .where((c) => c.habit.category == _categoryFilter)
                  .toList();
          final positive = allCorrelations.where((c) => c.diff > 0).toList();
          final negative = allCorrelations.where((c) => c.diff < 0).toList();
          final delayed = (_categoryFilter == null
                  ? data.positiveDelayedCorrelations
                  : data.positiveDelayedCorrelations
                      .where((c) => c.habit.category == _categoryFilter))
              .take(3)
              .toList();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, 32 + MediaQuery.paddingOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LargeChart(data: data).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

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

                if (positive.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.trending_up_rounded,
                    label: s.moodInsightsPositiveHeader,
                    color: AppTheme.success,
                  ),
                  const SizedBox(height: 8),
                  ...positive.asMap().entries.map((e) {
                    return _CorrelationTile(
                      correlation: e.value,
                      isPositive: true,
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 60 * e.key), duration: 300.ms)
                        .slideX(begin: 0.05);
                  }),
                ],

                if (negative.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                    icon: Icons.info_outline_rounded,
                    label: s.moodInsightsNegativeHeader,
                    color: AppTheme.tertiaryContainer,
                  ),
                  const SizedBox(height: 8),
                  ...negative.asMap().entries.map((e) {
                    return _CorrelationTile(
                      correlation: e.value,
                      isPositive: false,
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 60 * e.key), duration: 300.ms)
                        .slideX(begin: 0.05);
                  }),
                ],

                if (delayed.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                    icon: Icons.schedule_rounded,
                    label: s.moodInsightsDelayedHeader,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  ...delayed.asMap().entries.map((e) {
                    return _DelayedTile(correlation: e.value)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 60 * e.key), duration: 300.ms)
                        .slideX(begin: 0.05);
                  }),
                ],
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _CorrelationTile extends StatelessWidget {
  final HabitMoodCorrelation correlation;
  final bool isPositive;
  const _CorrelationTile({required this.correlation, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = correlation;
    final color = isPositive ? AppTheme.success : AppTheme.tertiaryContainer;
    final emoji = isPositive ? '🙂' : '⚠️';
    final absDiff = c.diff.abs().toStringAsFixed(1);
    final description = isPositive
        ? s.moodCorrelationBoost(emoji, c.diffLabel, c.habit.title)
        : s.moodCorrelationDrop(c.habit.title, absDiff);

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
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${c.daysCompleted} ${s.moodCorrelationDaysCompleted}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    _ConfidenceBadge(level: c.confidence),
                  ],
                ),
                // efecto racha: la constancia mejora aún más el ánimo
                if (isPositive && c.hasStreakBoost) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🔥 ${s.moodStreakBoost(c.streakDiffLabel!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.tertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPositive ? c.diffLabel : '-$absDiff',
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

// Tile de correlación con retardo: efecto del hábito de hoy sobre el ánimo de mañana
class _DelayedTile extends StatelessWidget {
  final HabitMoodCorrelation correlation;
  const _DelayedTile({required this.correlation});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = correlation;

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
              color: AppTheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌙', style: TextStyle(fontSize: 22)),
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
                  s.moodDelayedBoost(c.habit.title, c.diffLabel),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            c.diffLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// Chip que indica la fiabilidad de la correlación según el volumen de datos
class _ConfidenceBadge extends StatelessWidget {
  final MoodConfidence level;
  const _ConfidenceBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (color, label) = switch (level) {
      MoodConfidence.high => (AppTheme.success, s.moodConfidenceHigh),
      MoodConfidence.medium =>
        (AppTheme.tertiaryContainer, s.moodConfidenceMedium),
      MoodConfidence.low => (
          Theme.of(context).colorScheme.onSurfaceVariant,
          s.moodConfidenceLow,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
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
