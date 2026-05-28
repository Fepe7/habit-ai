import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';

// Banner de registro rápido de ánimo — aparece si no hay entradas hoy, desaparece al registrar
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
  bool _savedLocally = false; // ocultar inmediatamente sin esperar al stream

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _repo = MoodRepository(uid: uid);
  }

  Future<void> _quickSave(int rating) async {
    final repo = _repo;
    if (repo == null || _saving) return;
    setState(() => _saving = true);
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
      if (mounted) setState(() => _savedLocally = true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null || _savedLocally) return const SizedBox.shrink();

    return StreamBuilder<List<MoodEntryModel>>(
      stream: repo.watchTodayEntries(),
      builder: (context, snap) {
        if (snap.data?.isNotEmpty == true) return const SizedBox.shrink();

        return _BannerContent(
          saving: _saving,
          onRatingTap: _quickSave,
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: -0.15, duration: 300.ms, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  final bool saving;
  final void Function(int rating) onRatingTap;

  const _BannerContent({required this.saving, required this.onRatingTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    const emojis = ['😞', '😕', '😐', '🙂', '😄'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.18),
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
                  child: Icon(
                    Icons.favorite_rounded,
                    color: scheme.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  s.moodHowAreYou,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
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
                  return _EmojiButton(
                    emoji: emojis[i],
                    onTap: () => onRatingTap(i + 1),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

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
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
      ),
    );
  }
}
