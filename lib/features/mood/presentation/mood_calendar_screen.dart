import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mood_repository.dart';
import '../domain/mood_entry_model.dart';
import 'widgets/mood_heatmap_grid.dart';

// Pantalla con heatmap mensual de ánimo tipo GitHub
class MoodCalendarScreen extends StatefulWidget {
  const MoodCalendarScreen({super.key});

  @override
  State<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends State<MoodCalendarScreen> {
  late int _year;
  late int _month;
  List<MoodEntryModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final entries = await MoodRepository(uid: uid)
          .getEntriesForRange(
            DateTime(_year, _month, 1),
            DateTime(_year, _month + 1, 1),
          );
      if (mounted) setState(() { _entries = entries; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; }
      else { _month--; }
    });
    _loadMonth();
  }

  void _nextMonth() {
    final now = DateTime.now();
    // no navegar al futuro
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month == 12) { _month = 1; _year++; }
      else { _month++; }
    });
    _loadMonth();
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return !(_year == now.year && _month >= now.month);
  }

  String _monthLabel(BuildContext context) {
    final s = S.of(context);
    final months = [
      s.monthJan, s.monthFeb, s.monthMar, s.monthApr, s.monthMay, s.monthJun,
      s.monthJul, s.monthAug, s.monthSep, s.monthOct, s.monthNov, s.monthDec,
    ];
    return '${months[_month - 1]} $_year';
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
          s.moodCalendarTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // navegación de mes
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    _monthLabel(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _canGoNext
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.25),
                    ),
                    onPressed: _canGoNext ? _nextMonth : null,
                  ),
                ],
              ),
            ),

            // cabecera con días de la semana
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _WeekdayHeader(),
            ),

            // grid
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: MoodHeatmapGrid(
                        year: _year,
                        month: _month,
                        entries: _entries,
                        onEntryDeleted: _loadMonth,
                      ).animate().fadeIn(duration: 300.ms),
                    ),
            ),

            // leyenda
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Text(
                    s.moodCalendarLegend,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const MoodHeatmapLegend(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = [
      s.weekdayMonday, s.weekdayTuesday, s.weekdayWednesday,
      s.weekdayThursday, s.weekdayFriday, s.weekdaySaturday, s.weekdaySunday,
    ];
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: labels.map((l) {
        return Expanded(
          child: Center(
            child: Text(
              l.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
