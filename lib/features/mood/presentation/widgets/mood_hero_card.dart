import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';
import 'mood_entry_sheet.dart';

// hero card de ánimo para el dashboard — entry point + vista semanal en un bloque
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
    final start =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final end =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final entries =
        await MoodRepository(uid: uid).getEntriesForRange(start, end);

    return List.generate(7, (i) {
      final date = start.add(Duration(days: i));
      final dayEntries = entries.where((e) {
        final d = DateTime(
            e.timestamp.year, e.timestamp.month, e.timestamp.day);
        return d == DateTime(date.year, date.month, date.day);
      }).toList();
      final avg = dayEntries.isEmpty
          ? null
          : dayEntries.map((e) => e.rating).reduce((a, b) => a + b) /
              dayEntries.length;
      return _DayPoint(date: date, avg: avg);
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
              crossAxisAlignment: CrossAxisAlignment.center,
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

          const SizedBox(height: 12),

          // zona de hoy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<MoodEntryModel>>(
              stream: repo.watchTodayEntries(),
              builder: (context, snap) {
                final logged = snap.data?.isNotEmpty == true;
                final rating = snap.data?.last.rating;

                if (logged && rating != null) {
                  return _LoggedZone(
                    rating: rating,
                    streak: _streak,
                    brightness: brightness,
                  );
                }
                return _EntryZone(repo: repo);
              },
            ),
          ),

          const SizedBox(height: 18),

          // separador + etiqueta semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _weekLabel(s),
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

          // strip semanal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: FutureBuilder<List<_DayPoint>>(
              future: _weekFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(height: 72);
                }
                return _WeekStrip(
                  days: snap.data!,
                  brightness: brightness,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04);
  }

  String _weekLabel(S s) {
    // reutiliza la cadena existente de "Ánimo esta semana"
    return s.moodWeekChart.toUpperCase();
  }
}

// --- zona de hoy: sin registrar ---

class _EntryZone extends StatelessWidget {
  final MoodRepository repo;

  const _EntryZone({required this.repo});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return GestureDetector(
      onTap: () => MoodEntrySheet.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFF0DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFDDB0), width: 1),
        ),
        child: Row(
          children: [
            Text(
              _timeEmoji(DateTime.now().hour),
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(s),
                    style: const TextStyle(
                      color: Color(0xFF78350F),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.moodHowAreYou,
                    style: const TextStyle(
                      color: Color(0xFFA16207),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDDB0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting(S s) {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 14) return s.moodBannerMorning;
    if (h >= 14 && h < 21) return s.moodBannerAfternoon;
    return s.moodBannerNight;
  }

  String _timeEmoji(int hour) {
    if (hour >= 5 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 15) return '☀️';
    if (hour >= 15 && hour < 21) return '🌇';
    return '🌙';
  }
}

// --- zona de hoy: ya registrado ---

class _LoggedZone extends StatelessWidget {
  final int rating;
  final int streak;
  final Brightness brightness;

  const _LoggedZone({
    required this.rating,
    required this.streak,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bg = MoodTheme.ratingBg(rating, brightness);
    final accent = MoodTheme.ratingAccent(rating, brightness);
    final emoji = MoodTheme.emojiFor(rating);

    return GestureDetector(
      onTap: () => MoodEntrySheet.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.moodLoggedToday,
                        style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: accent),
                    ],
                  ),
                  if (streak > 1) ...[
                    const SizedBox(height: 3),
                    Text(
                      '🔥 ${s.moodStreakDays(streak)}',
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.add_rounded,
                size: 18, color: accent.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}

// --- strip de 7 días ---

class _WeekStrip extends StatelessWidget {
  final List<_DayPoint> days;
  final Brightness brightness;

  const _WeekStrip({required this.days, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(days.length, (i) {
        final day = days[i];
        final isToday = i == days.length - 1;
        final rating = day.avg?.round().clamp(1, 5);

        final bg = rating != null
            ? MoodTheme.ratingBg(rating, brightness)
            : scheme.surfaceContainerLow;
        final accent = rating != null
            ? MoodTheme.ratingAccent(rating, brightness)
            : scheme.outlineVariant;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // círculo del día
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isToday ? 42 : 36,
              height: isToday ? 42 : 36,
              decoration: BoxDecoration(
                color: bg.withValues(alpha: isToday ? 0.6 : 0.4),
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: accent.withValues(alpha: 0.6), width: 1.5)
                    : null,
              ),
              child: Center(
                child: rating != null
                    ? Text(
                        MoodTheme.emojiFor(rating),
                        style: TextStyle(fontSize: isToday ? 20 : 17),
                      )
                    : Container(
                        width: isToday ? 8 : 7,
                        height: isToday ? 8 : 7,
                        decoration: BoxDecoration(
                          color: scheme.outlineVariant
                              .withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            // etiqueta del día
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
        );
      }),
    );
  }

  String _dayLabel(BuildContext context, int weekday) {
    final s = S.of(context);
    final full = [
      s.weekdayMonday,
      s.weekdayTuesday,
      s.weekdayWednesday,
      s.weekdayThursday,
      s.weekdayFriday,
      s.weekdaySaturday,
      s.weekdaySunday,
    ];
    final idx = (weekday - 1).clamp(0, 6);
    return full[idx].substring(0, 1).toUpperCase();
  }
}

class _DayPoint {
  final DateTime date;
  final double? avg;
  const _DayPoint({required this.date, required this.avg});
}
