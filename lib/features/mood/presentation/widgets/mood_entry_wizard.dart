import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/ux/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';
import 'mood_emoji_selector.dart';
import 'mood_label_chips.dart';
import 'mood_step_indicator.dart';

// wizard de 3 pasos: emoji → labels → nota+guardar
class MoodEntryWizard extends StatefulWidget {
  final List<HabitModel> completedHabits;

  const MoodEntryWizard({
    super.key,
    this.completedHabits = const [],
  });

  @override
  State<MoodEntryWizard> createState() => _MoodEntryWizardState();
}

class _MoodEntryWizardState extends State<MoodEntryWizard> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  int? _rating;
  List<String> _labels = [];
  final _noteCtrl = TextEditingController();
  late String _timeBlock;
  bool _saving = false;
  bool _saved = false;
  // timer cancelable para el auto-avance al paso 2
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _timeBlock = MoodEntryModel.timeBlockFromHour(DateTime.now().hour);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _onEmojiSelected(int rating) {
    setState(() => _rating = rating);
    // cancela cualquier timer previo antes de arrancar uno nuevo
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _currentPage == 0) _goToPage(1);
    });
  }

  Future<void> _quickSave() async {
    _autoAdvanceTimer?.cancel(); // evita race: cancelar antes de guardar
    if (_rating == null) return;
    await _save();
  }

  Future<void> _save() async {
    if (_rating == null || _saving) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final entry = MoodEntryModel(
        id: '',
        rating: _rating!,
        labels: _labels,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        timeBlock: _timeBlock,
        timestamp: DateTime.now(),
        habitsCompletedSnapshot:
            widget.completedHabits.map((h) => h.id).toList(),
      );
      final repo = MoodRepository(uid: uid);
      await repo.createEntry(entry);
      await FeedbackService.instance.habitCompleted();
      final streak = await repo.getMoodStreak();
      if (mounted) {
        setState(() => _saved = true);
        if (streak > 1) {
          final s = S.of(context);
          AppSnackBar.showSuccess(
            context,
            '🔥 ${s.moodStreakDays(streak)}',
          );
        }
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        // mensaje localizado con opción de reintentar — sin texto de excepción raw
        AppSnackBar.showError(
          context,
          S.of(context).moodSaveError,
          onRetry: _save,
        );
      }
    }
  }

  Brightness get _brightness => Theme.of(context).brightness;

  Color get _accentColor => _rating != null
      ? MoodTheme.ratingAccent(_rating!, _brightness)
      : Theme.of(context).colorScheme.primary;

  Color get _bgTint => _rating != null
      ? MoodTheme.ratingBg(_rating!, _brightness)
      : Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    // altura máxima: 52% del alto de pantalla, mínimo 180 — evita overflow en pantallas pequeñas
    final maxHeight = MediaQuery.of(context).size.height * 0.52;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Color.lerp(
          scheme.surface,
          _bgTint,
          _rating != null ? 0.3 : 0.0,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            MoodStepIndicator(
              currentStep: _currentPage,
              activeColor: _accentColor,
            ),
            const SizedBox(height: 20),

            // contenido paginado con altura dinámica
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 180,
                maxHeight: maxHeight,
              ),
              child: PageView(
                controller: _pageCtrl,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildStep1Emoji(s),
                  _buildStep2Labels(s),
                  _buildStep3Note(s, scheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // paso 1: selección de emoji
  Widget _buildStep1Emoji(S s) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            _contextualGreeting(s),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          MoodEmojiSelector(
            selectedRating: _rating,
            onRatingChanged: _onEmojiSelected,
            emojiSize: 58,
          ),
          const SizedBox(height: 20),

          if (_rating != null)
            TextButton(
              onPressed: _quickSave,
              child: Text(
                s.moodQuickSave,
                style: TextStyle(color: _accentColor),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.3, duration: 300.ms),
        ],
      ),
    );
  }

  // paso 2: labels emocionales
  Widget _buildStep2Labels(S s) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // time block en Wrap para evitar overflow en pantallas estrechas
          _TimeBlockRow(
            selected: _timeBlock,
            onChanged: (tb) => setState(() => _timeBlock = tb),
          ),
          const SizedBox(height: 16),

          MoodLabelChips(
            selectedLabels: _labels,
            onLabelsChanged: (l) => setState(() => _labels = l),
            rating: _rating,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _goToPage(2),
                  child: Text(s.moodSkip),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _goToPage(2),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                  ),
                  child: Text(s.moodNext),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // paso 3: nota + guardar
  Widget _buildStep3Note(S s, ColorScheme scheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _noteCtrl,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.moodAnythingOnMind,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              counterStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          if (widget.completedHabits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              s.moodHabitsToday,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.completedHabits
                  .map(
                    (h) => Chip(
                      label: Text(
                        h.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),

          _SaveButton(
            saving: _saving,
            saved: _saved,
            enabled: _rating != null,
            accentColor: _accentColor,
            label: s.moodSave,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  String _contextualGreeting(S s) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 14) return s.moodBannerMorning;
    if (hour >= 14 && hour < 21) return s.moodBannerAfternoon;
    return s.moodBannerNight;
  }
}

// botón de guardar con morph a check al completar
class _SaveButton extends StatelessWidget {
  final bool saving;
  final bool saved;
  final bool enabled;
  final Color accentColor;
  final String label;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.saving,
    required this.saved,
    required this.enabled,
    required this.accentColor,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (saved) {
      return Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.elasticOut,
            ),
      );
    }

    return GradientButton(
      onPressed: enabled && !saving ? onPressed : null,
      label: label,
      loading: saving,
      gradient: LinearGradient(
        colors: [accentColor, accentColor.withValues(alpha: 0.7)],
      ),
    );
  }
}

// fila de time block en Wrap para evitar overflow en pantallas estrechas
class _TimeBlockRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TimeBlockRow({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final blocks = [
      ('morning', s.moodTimeBlockMorning, '🌅'),
      ('midday', s.moodTimeBlockMidday, '☀️'),
      ('afternoon', s.moodTimeBlockAfternoon, '🌇'),
      ('night', s.moodTimeBlockNight, '🌙'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: blocks.map((b) {
        final isSelected = selected == b.$1;
        return GestureDetector(
          onTap: () => onChanged(b.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(b.$3, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  b.$2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
