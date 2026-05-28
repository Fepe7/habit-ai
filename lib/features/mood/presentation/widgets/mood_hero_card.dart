import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';
import 'mood_day_detail_sheet.dart';
import 'mood_entry_sheet.dart';

// hero card de ánimo — 4 slots del día + strip semanal tappable
class MoodHeroCard extends StatefulWidget {
  const MoodHeroCard({super.key});

  @override
  State<MoodHeroCard> createState() => _MoodHeroCardState();
}

class _MoodHeroCardState extends State<MoodHeroCard> {
  MoodRepository? _repo;
  late Future<List<_DayPoint>> _weekFuture;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _repo = MoodRepository(uid: uid);
      _weekFuture = _loadWeek(uid);
      _loadStreak(uid);
    } else {
      _weekFuture = Future.value(const []);
    }
  }

  Future<List<_DayPoint>> _loadWeek(String uid) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final end = monday.add(const Duration(days: 7));
    final entries =
        await MoodRepository(uid: uid).getEntriesForRange(monday, end);

    return List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      final dayEntries = entries.where((e) {
        final d = DateTime(
            e.timestamp.year, e.timestamp.month, e.timestamp.day);
        return d == date;
      }).toList();
      final avg = dayEntries.isEmpty
          ? null
          : dayEntries.map((e) => e.rating).reduce((a, b) => a + b) /
              dayEntries.length;
      return _DayPoint(date: date, avg: avg, entries: dayEntries);
    });
  }

  Future<void> _loadStreak(String uid) async {
    final streak = await MoodRepository(uid: uid).getMoodStreak();
    if (mounted) setState(() => _streak = streak);
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 0),
            child: Row(
              children: [
                const Text('💭', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.moodTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_streak > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🔥 $_streak',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => context.goNamed('mood-insights'),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.exploreSeeAll,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 11, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4 slots del día
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<MoodEntryModel>>(
              stream: repo.watchTodayEntries(),
              builder: (context, snap) {
                final entries = snap.data ?? const [];
                return _TodaySlotsRow(
                  todayEntries: entries,
                  brightness: brightness,
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // separador semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  s.moodWeekChart.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Divider(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // strip semanal tappable
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: FutureBuilder<List<_DayPoint>>(
              future: _weekFuture,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox(height: 72);
                return _WeekStrip(
                  days: snap.data!,
                  brightness: brightness,
                  onReload: () {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      setState(() => _weekFuture = _loadWeek(uid));
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04);
  }
}

// --- 4 slots del día ---

class _TodaySlotsRow extends StatelessWidget {
  final List<MoodEntryModel> todayEntries;
  final Brightness brightness;

  static const _blocks = [
    ('morning', '🌅'),
    ('midday', '☀️'),
    ('afternoon', '🌇'),
    ('night', '🌙'),
  ];

  const _TodaySlotsRow({
    required this.todayEntries,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = [
      s.moodTimeBlockMorning,
      s.moodTimeBlockMidday,
      s.moodTimeBlockAfternoon,
      s.moodTimeBlockNight,
    ];

    return Row(
      children: List.generate(_blocks.length, (i) {
        final (blockKey, blockEmoji) = _blocks[i];
        // última entrada de este bloque si hay varias
        final entry = todayEntries
            .where((e) => e.timeBlock == blockKey)
            .fold<MoodEntryModel?>(null, (_, e) => e);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
            child: _SlotPill(
              blockKey: blockKey,
              blockEmoji: blockEmoji,
              label: labels[i],
              entry: entry,
              brightness: brightness,
            ),
          ),
        );
      }),
    );
  }
}

class _SlotPill extends StatelessWidget {
  final String blockKey;
  final String blockEmoji;
  final String label;
  final MoodEntryModel? entry;
  final Brightness brightness;

  const _SlotPill({
    required this.blockKey,
    required this.blockEmoji,
    required this.label,
    required this.entry,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logged = entry != null;
    final bg = logged
        ? MoodTheme.ratingBg(entry!.rating, brightness).withValues(alpha: 0.45)
        : scheme.surfaceContainerLow;
    final accent = logged
        ? MoodTheme.ratingAccent(entry!.rating, brightness)
        : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => MoodEntrySheet.show(
        context,
        initialEntry: logged ? entry : null,
        preselectedTimeBlock: logged ? null : blockKey,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 82,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: logged
              ? Border.all(
                  color: accent.withValues(alpha: 0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // emoji principal
            Text(
              logged ? MoodTheme.emojiFor(entry!.rating) : blockEmoji,
              style: TextStyle(fontSize: logged ? 22 : 18),
            ),
            const SizedBox(height: 4),
            // indicador
            if (logged)
              Icon(Icons.check_rounded, size: 12, color: accent)
            else
              Icon(Icons.add_rounded,
                  size: 14, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 4),
            // etiqueta
            Text(
              label.substring(0, label.length > 3 ? 3 : label.length).toUpperCase(),
              style: TextStyle(
                color: logged
                    ? accent
                    : scheme.onSurfaceVariant.withValues(alpha: 0.55),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- strip semanal tappable ---

class _WeekStrip extends StatelessWidget {
  final List<_DayPoint> days;
  final Brightness brightness;
  final VoidCallback onReload;

  const _WeekStrip({
    required this.days,
    required this.brightness,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(days.length, (i) {
        final day = days[i];
        final now = DateTime.now();
        final isToday = day.date.year == now.year &&
            day.date.month == now.month &&
            day.date.day == now.day;
        final isFuture = day.date.isAfter(DateTime(now.year, now.month, now.day));
        final rating = day.avg?.round().clamp(1, 5);

        final bg = rating != null
            ? MoodTheme.ratingBg(rating, brightness)
            : scheme.surfaceContainerLow;
        final accent = rating != null
            ? MoodTheme.ratingAccent(rating, brightness)
            : scheme.outlineVariant;

        return GestureDetector(
          onTap: isFuture
              ? null
              : () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;
                  // si ya tenemos las entries en el punto, usarlas directamente
                  final entries = day.entries.isNotEmpty
                      ? day.entries
                      : await MoodRepository(uid: uid).getEntriesForRange(
                          day.date,
                          day.date.add(const Duration(days: 1)),
                        );
                  if (context.mounted) {
                    await MoodDayDetailSheet.show(
                      context,
                      date: day.date,
                      entries: entries,
                      onDeleted: onReload,
                    );
                  }
                },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isToday ? 42 : 36,
                height: isToday ? 42 : 36,
                decoration: BoxDecoration(
                  color: isFuture
                      ? Colors.transparent
                      : bg.withValues(alpha: isToday ? 0.6 : 0.4),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(
                          color: accent.withValues(alpha: 0.6), width: 1.5)
                      : isFuture
                          ? Border.all(
                              color: scheme.outlineVariant
                                  .withValues(alpha: 0.25),
                              width: 1,
                            )
                          : null,
                ),
                child: Center(
                  child: isFuture
                      ? null
                      : rating != null
                          ? Text(
                              MoodTheme.emojiFor(rating),
                              style: TextStyle(fontSize: isToday ? 20 : 17),
                            )
                          : Container(
                              width: isToday ? 8 : 6,
                              height: isToday ? 8 : 6,
                              decoration: BoxDecoration(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _dayLabel(context, day.date.weekday),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _dayLabel(BuildContext context, int weekday) {
    final s = S.of(context);
    final full = [
      s.weekdayMonday, s.weekdayTuesday, s.weekdayWednesday,
      s.weekdayThursday, s.weekdayFriday, s.weekdaySaturday, s.weekdaySunday,
    ];
    return full[(weekday - 1).clamp(0, 6)].substring(0, 1).toUpperCase();
  }
}

class _DayPoint {
  final DateTime date;
  final double? avg;
  final List<MoodEntryModel> entries;

  const _DayPoint({
    required this.date,
    required this.avg,
    required this.entries,
  });
}
