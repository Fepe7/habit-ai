import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/widgets/ux/app_snackbar.dart';
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

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _repo = MoodRepository(uid: uid);
  }

  // Registro rápido de un toque: ánimo de la franja actual, sin abrir el sheet
  Future<void> _quickLog(int rating) async {
    final repo = _repo;
    if (repo == null) return;

    final now = DateTime.now();
    final entry = MoodEntryModel(
      id: '',
      rating: rating,
      labels: const [],
      timeBlock: MoodEntryModel.timeBlockFromHour(now.hour),
      timestamp: now,
      habitsCompletedSnapshot:
          widget.completedHabits.map((h) => h.id).toList(),
    );

    await FeedbackService.instance.moodSelected();
    await repo.createEntry(entry);
    if (!mounted) return;
    AppSnackBar.showSuccess(context, S.of(context).moodLoggedToday);
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null) return const SizedBox.shrink();

    return StreamBuilder<List<MoodEntryModel>>(
      stream: repo.watchTodayEntries(),
      builder: (context, snap) {
        // solo cuenta el registro de la franja horaria actual: si ya registró
        // por la mañana, por la tarde vuelve a invitar (nueva franja)
        final block = MoodEntryModel.timeBlockFromHour(DateTime.now().hour);
        MoodEntryModel? blockEntry;
        for (final e in (snap.data ?? const <MoodEntryModel>[])) {
          if (e.timeBlock == block) blockEntry = e;
        }

        final _CardState state;
        if (snap.connectionState == ConnectionState.waiting) {
          state = _CardState.loading;
        } else if (blockEntry != null) {
          state = _CardState.logged;
        } else {
          state = _CardState.notLogged;
        }

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
                onQuickLog: _quickLog,
              ),
            // registrada la franja, la tarjeta se quita: el estado queda
            // visible en el botón de ánimo del header, sin ocupar la lista
            _CardState.logged => const SizedBox.shrink(key: ValueKey('logged')),
          },
        );
      },
    );
  }
}

// --- estado: sin registro — tarjeta cálida tipo diario ---

class _EntryCard extends StatelessWidget {
  final List<HabitModel> completedHabits;
  final ValueChanged<int> onQuickLog;

  const _EntryCard({
    super.key,
    required this.completedHabits,
    required this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return GestureDetector(
      // tocar la tarjeta abre el sheet completo (nota + etiquetas)
      onTap: () => MoodEntrySheet.show(
        context,
        completedHabits: completedHabits,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // registro rápido: un toque = ánimo de esta franja, sin abrir nada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final rating = i + 1;
                return _QuickEmoji(
                  emoji: MoodTheme.emojiFor(rating),
                  onTap: () => onQuickLog(rating),
                );
              }),
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

// Emoji tappable para el registro rápido de un toque
class _QuickEmoji extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _QuickEmoji({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFFFFDDB0),
        highlightColor: const Color(0xFFFFEACB),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
