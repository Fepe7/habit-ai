import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';
import 'mood_entry_sheet.dart';

enum _BannerState { loading, notLogged, logged }

// banner de ánimo diario con 3 estados: loading / no registrado / registrado
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
  bool _saving = false;
  int? _savedRating; // rating guardado localmente para transición inmediata
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

  Future<void> _quickSave(int rating) async {
    final repo = _repo;
    if (repo == null || _saving) return;
    setState(() {
      _saving = true;
      _savedRating = rating;
    });
    try {
      final entry = MoodEntryModel(
        id: '',
        rating: rating,
        labels: const [],
        timeBlock: MoodEntryModel.timeBlockFromHour(DateTime.now().hour),
        timestamp: DateTime.now(),
        habitsCompletedSnapshot:
            widget.completedHabits.map((h) => h.id).toList(),
      );
      await repo.createEntry(entry);
      await FeedbackService.instance.habitCompleted();
      if (mounted) {
        setState(() => _saving = false);
        // recalcular racha tras guardar
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) _loadStreak(uid);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _savedRating = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null) return const SizedBox.shrink();

    return StreamBuilder<List<MoodEntryModel>>(
      stream: repo.watchTodayEntries(),
      builder: (context, snap) {
        final state = _resolveState(snap);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position:
                    Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                        .animate(anim),
                child: child,
              ),
            ),
            child: switch (state) {
              _BannerState.loading => const SizedBox.shrink(key: ValueKey('loading')),
              _BannerState.notLogged => _NotLoggedBanner(
                  key: const ValueKey('not-logged'),
                  saving: _saving,
                  completedHabits: widget.completedHabits,
                  onRatingTap: _quickSave,
                ),
              _BannerState.logged => _LoggedBanner(
                  key: const ValueKey('logged'),
                  rating: _savedRating ?? (snap.data?.last.rating ?? 3),
                  streak: _streak,
                  completedHabits: widget.completedHabits,
                ),
            },
          ),
        );
      },
    );
  }

  _BannerState _resolveState(AsyncSnapshot<List<MoodEntryModel>> snap) {
    if (snap.connectionState == ConnectionState.waiting && _savedRating == null) {
      return _BannerState.loading;
    }
    if (_savedRating != null || (snap.data?.isNotEmpty == true)) {
      return _BannerState.logged;
    }
    return _BannerState.notLogged;
  }
}

// ---------- estado: no registrado ----------

class _NotLoggedBanner extends StatelessWidget {
  final bool saving;
  final List<HabitModel> completedHabits;
  final void Function(int) onRatingTap;

  const _NotLoggedBanner({
    super.key,
    required this.saving,
    required this.completedHabits,
    required this.onRatingTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.45),
            scheme.primaryContainer.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite_rounded,
                    color: scheme.primary, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _greeting(s),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (saving)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final rating = i + 1;
                final bg = MoodTheme.ratingBg(rating, brightness);
                final accent = MoodTheme.ratingAccent(rating, brightness);
                return _EmojiButton(
                  emoji: MoodTheme.emojis[i],
                  bg: bg,
                  accent: accent,
                  onTap: () => onRatingTap(rating),
                );
              }),
            ),

          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => MoodEntrySheet.show(
              context,
              completedHabits: completedHabits,
            ),
            child: Text(
              s.moodTellMore,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: scheme.primary,
                  ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.1, duration: 300.ms, curve: Curves.easeOutCubic)
        .shimmer(duration: 800.ms, delay: 100.ms, color: Colors.white10);
  }

  String _greeting(S s) {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 14) return s.moodBannerMorning;
    if (h >= 14 && h < 21) return s.moodBannerAfternoon;
    return s.moodBannerNight;
  }
}

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final Color bg;
  final Color accent;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.bg,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    FeedbackService.instance.moodSelected();
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: widget.bg.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}

// ---------- estado: registrado ----------

class _LoggedBanner extends StatelessWidget {
  final int rating;
  final int streak;
  final List<HabitModel> completedHabits;

  const _LoggedBanner({
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
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.07, 1.07),
                  duration: 1800.ms,
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
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: accent),
                    ],
                  ),
                  if (streak > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      '🔥 ${s.moodStreakDays(streak)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.add_rounded, size: 20, color: accent.withValues(alpha: 0.6)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms);
  }
}
