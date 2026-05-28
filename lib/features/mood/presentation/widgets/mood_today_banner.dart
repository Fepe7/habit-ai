import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';
import 'mood_entry_sheet.dart';

enum _CardState { loading, notLogged, logged }

// tarjeta de ánimo para el dashboard — entry point al sheet de registro
class MoodTodayBanner extends StatefulWidget {
  final List<HabitModel> completedHabits;

  const MoodTodayBanner({
    super.key,
    this.completedHabits = const [],
  });

  @override
  State<MoodTodayBanner> createState() => _MoodTodayBannerState();
}

class _MoodTodayBannerState extends State<MoodTodayBanner> {
  MoodRepository? _repo;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _repo = MoodRepository(uid: uid);
      _loadStreak(uid);
    }
  }

  Future<void> _loadStreak(String uid) async {
    final streak = await MoodRepository(uid: uid).getMoodStreak();
    if (mounted) setState(() => _streak = streak);
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null) return const SizedBox.shrink();

    return StreamBuilder<List<MoodEntryModel>>(
      stream: repo.watchTodayEntries(),
      builder: (context, snap) {
        final state = _resolveState(snap);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: switch (state) {
            _CardState.loading =>
              const SizedBox.shrink(key: ValueKey('loading')),
            _CardState.notLogged => _EntryCard(
                key: const ValueKey('not-logged'),
                completedHabits: widget.completedHabits,
              ),
            _CardState.logged => _LoggedCard(
                key: const ValueKey('logged'),
                rating: snap.data?.last.rating ?? 3,
                streak: _streak,
                completedHabits: widget.completedHabits,
              ),
          },
        );
      },
    );
  }

  _CardState _resolveState(AsyncSnapshot<List<MoodEntryModel>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return _CardState.loading;
    }
    if (snap.data?.isNotEmpty == true) return _CardState.logged;
    return _CardState.notLogged;
  }
}

// --- estado: sin registro — tarjeta cálida tipo diario ---

class _EntryCard extends StatelessWidget {
  final List<HabitModel> completedHabits;

  const _EntryCard({super.key, required this.completedHabits});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return GestureDetector(
      onTap: () => MoodEntrySheet.show(
        context,
        completedHabits: completedHabits,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          // crema cálida — contraste deliberado con la paleta azul de la app
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFF0DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFDDB0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              _timeEmoji(DateTime.now().hour),
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 2),
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
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.08, duration: 300.ms, curve: Curves.easeOutCubic);
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

// --- estado: ya registrado ---

class _LoggedCard extends StatelessWidget {
  final int rating;
  final int streak;
  final List<HabitModel> completedHabits;

  const _LoggedCard({
    super.key,
    required this.rating,
    required this.streak,
    required this.completedHabits,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final brightness = Theme.of(context).brightness;
    final bg = MoodTheme.ratingBg(rating, brightness);
    final accent = MoodTheme.ratingAccent(rating, brightness);
    final emoji = MoodTheme.emojiFor(rating);

    return GestureDetector(
      onTap: () => MoodEntrySheet.show(
        context,
        completedHabits: completedHabits,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.07, 1.07),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: accent,
                      ),
                    ],
                  ),
                  if (streak > 1) ...[
                    const SizedBox(height: 2),
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
            Icon(
              Icons.add_rounded,
              size: 18,
              color: accent.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, duration: 300.ms);
  }
}
