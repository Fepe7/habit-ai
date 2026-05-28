import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/widgets/ux/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import '../mood_theme.dart';

const _kSheetBg = Color(0xFF1C1F2A);
const _kSheetNeutralZone = Color(0xFF252A38);
const _kOnSheet = Color(0xFFE8EDF5);
const _kOnSheetDim = Color(0xFF7A86A0);
const _kSurface2 = Color(0xFF252A38);

// sheet de registro de ánimo — pantalla única, superficie dark con zona de color emocional
class MoodEntryWizard extends StatefulWidget {
  final List<HabitModel> completedHabits;
  /// si se pasa, el sheet abre en modo edición pre-cargado con estos valores
  final MoodEntryModel? initialEntry;
  /// bloque horario pre-seleccionado (solo en modo creación)
  final String? preselectedTimeBlock;

  const MoodEntryWizard({
    super.key,
    this.completedHabits = const [],
    this.initialEntry,
    this.preselectedTimeBlock,
  });

  @override
  State<MoodEntryWizard> createState() => _MoodEntryWizardState();
}

class _MoodEntryWizardState extends State<MoodEntryWizard> {
  int? _rating;
  List<String> _labels = [];
  final _noteCtrl = TextEditingController();
  bool _noteExpanded = false;
  late String _timeBlock;
  bool _saving = false;
  bool _saved = false;

  bool get _isEditing => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEntry;
    if (initial != null) {
      _rating = initial.rating;
      _labels = List.from(initial.labels);
      _noteCtrl.text = initial.note ?? '';
      _noteExpanded = initial.note?.isNotEmpty == true;
      _timeBlock = initial.timeBlock;
    } else {
      _timeBlock = widget.preselectedTimeBlock ??
          MoodEntryModel.timeBlockFromHour(DateTime.now().hour);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Color get _zoneColor =>
      _rating != null ? MoodTheme.sheetZoneBg(_rating!) : _kSheetNeutralZone;

  Color get _accent =>
      _rating != null
          ? MoodTheme.sheetZoneAccent(_rating!)
          : const Color(0xFF4A9EBF);

  Future<void> _save() async {
    if (_rating == null || _saving) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    try {
      final repo = MoodRepository(uid: uid);
      if (_isEditing) {
        final updated = widget.initialEntry!.copyWith(
          rating: _rating!,
          labels: _labels,
          note: note,
          clearNote: note == null,
          timeBlock: _timeBlock,
          timestamp: DateTime.now(),
        );
        await repo.updateEntry(updated);
      } else {
        final entry = MoodEntryModel(
          id: '',
          rating: _rating!,
          labels: _labels,
          note: note,
          timeBlock: _timeBlock,
          timestamp: DateTime.now(),
          habitsCompletedSnapshot:
              widget.completedHabits.map((h) => h.id).toList(),
        );
        await repo.createEntry(entry);
      }
      await FeedbackService.instance.habitCompleted();
      final streak = await repo.getMoodStreak();
      if (mounted) {
        setState(() => _saved = true);
        if (!_isEditing && streak > 1) {
          AppSnackBar.showSuccess(
            context,
            '🔥 ${S.of(context).moodStreakDays(streak)}',
          );
        }
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.showError(
          context,
          S.of(context).moodSaveError,
          onRetry: _save,
        );
      }
    }
  }

  String _greeting(S s) {
    if (_isEditing) return s.moodHowAreYou;
    final h = DateTime.now().hour;
    if (h >= 5 && h < 14) return s.moodBannerMorning;
    if (h >= 14 && h < 21) return s.moodBannerAfternoon;
    return s.moodBannerNight;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
        color: _kSheetBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // zona de color — anima al tono emocional seleccionado
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              color: _zoneColor,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                children: [
                  Text(
                    _greeting(s),
                    style: const TextStyle(
                      color: _kOnSheetDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _DarkRatingRow(
                    rating: _rating,
                    accent: _accent,
                    onChanged: (r) {
                      FeedbackService.instance.moodSelected();
                      setState(() => _rating = r);
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _rating != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              MoodTheme.ratingLabel(_rating!, s),
                              style: TextStyle(
                                color: _accent,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                                .animate(key: ValueKey(_rating))
                                .fadeIn(duration: 200.ms)
                                .slideY(begin: 0.3, duration: 200.ms),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // sección scrollable: labels + nota + guardar
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DarkTimeBlockRow(
                      selected: _timeBlock,
                      onChanged: (tb) => setState(() => _timeBlock = tb),
                    ),
                    const SizedBox(height: 20),
                    _DarkLabelsSection(
                      labels: _labels,
                      rating: _rating,
                      onChanged: (l) => setState(() => _labels = l),
                    ),
                    const SizedBox(height: 20),
                    _DarkNoteField(
                      controller: _noteCtrl,
                      expanded: _noteExpanded,
                      hint: s.moodAnythingOnMind,
                      onExpand: () => setState(() => _noteExpanded = true),
                    ),
                    const SizedBox(height: 28),
                    _DarkSaveButton(
                      saving: _saving,
                      saved: _saved,
                      enabled: _rating != null,
                      accent: _accent,
                      label: s.moodSave,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- círculos de rating sobre el fondo oscuro/coloreado ---

class _DarkRatingRow extends StatelessWidget {
  final int? rating;
  final Color accent;
  final ValueChanged<int> onChanged;

  const _DarkRatingRow({
    required this.rating,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final r = i + 1;
        return _DarkCircle(
          emoji: MoodTheme.emojis[i],
          selected: rating == r,
          dimmed: rating != null && rating != r,
          accent: accent,
          onTap: () => onChanged(r),
        );
      }),
    );
  }
}

class _DarkCircle extends StatelessWidget {
  final String emoji;
  final bool selected;
  final bool dimmed;
  final Color accent;
  final VoidCallback onTap;

  const _DarkCircle({
    required this.emoji,
    required this.selected,
    required this.dimmed,
    required this.accent,
    required this.onTap,
  });

  // tamaño fijo — el círculo no crece para evitar overflow horizontal
  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dimmed ? 0.28 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 24,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: selected ? _size * 0.57 : _size * 0.46,
              ),
              child: Text(emoji),
            ),
          ),
        ),
      ),
    );
  }
}

// --- labels en contexto dark ---

class _DarkLabelsSection extends StatelessWidget {
  final List<String> labels;
  final int? rating;
  final ValueChanged<List<String>> onChanged;

  const _DarkLabelsSection({
    required this.labels,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final all = MoodTheme.labels(s);
    final negatives = all.where((l) => !l.isPositive).toList();
    final positives = all.where((l) => l.isPositive).toList();
    final showPositivesFirst = (rating ?? 0) >= 4;

    final first = showPositivesFirst ? positives : negatives;
    final second = showPositivesFirst ? negatives : positives;
    final firstTitle =
        showPositivesFirst ? s.moodLabelsPositive : s.moodLabelsNegative;
    final secondTitle =
        showPositivesFirst ? s.moodLabelsNegative : s.moodLabelsPositive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DarkGroup(
          title: firstTitle,
          defs: first,
          selected: labels,
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        _DarkGroup(
          title: secondTitle,
          defs: second,
          selected: labels,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DarkGroup extends StatelessWidget {
  final String title;
  final List<MoodLabelDef> defs;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _DarkGroup({
    required this.title,
    required this.defs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: _kOnSheetDim,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: defs.map((def) {
            final isSelected = selected.contains(def.key);
            return _DarkPill(
              def: def,
              selected: isSelected,
              onTap: () {
                FeedbackService.instance.moodSelected();
                final updated = List<String>.from(selected);
                isSelected ? updated.remove(def.key) : updated.add(def.key);
                onChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DarkPill extends StatelessWidget {
  final MoodLabelDef def;
  final bool selected;
  final VoidCallback onTap;

  const _DarkPill({
    required this.def,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = def.darkBg;
    final fg = def.darkFg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? bg : bg.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? fg.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(def.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              def.display,
              style: TextStyle(
                color: selected ? fg : fg.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_rounded, size: 12, color: fg)
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 200.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- selector de franja horaria (dark) ---

class _DarkTimeBlockRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _DarkTimeBlockRow({
    required this.selected,
    required this.onChanged,
  });

  static const _blocks = [
    ('morning', '🌅'),
    ('midday', '☀️'),
    ('afternoon', '🌇'),
    ('night', '🌙'),
  ];

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
        final (key, emoji) = _blocks[i];
        final isSelected = selected == key;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onChanged(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.14)
                      : _kSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      labels[i].substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? _kOnSheet : _kOnSheetDim,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// --- campo de nota expandible ---

class _DarkNoteField extends StatelessWidget {
  final TextEditingController controller;
  final bool expanded;
  final String hint;
  final VoidCallback onExpand;

  const _DarkNoteField({
    required this.controller,
    required this.expanded,
    required this.hint,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return GestureDetector(
        onTap: onExpand,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _kSurface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            hint,
            style: const TextStyle(color: _kOnSheetDim, fontSize: 14),
          ),
        ),
      );
    }

    return TextField(
      controller: controller,
      autofocus: true,
      maxLength: 200,
      maxLines: 3,
      style: const TextStyle(color: _kOnSheet, fontSize: 14),
      cursorColor: Color(0xFF4A9EBF),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kOnSheetDim, fontSize: 14),
        counterStyle: const TextStyle(color: _kOnSheetDim, fontSize: 11),
        filled: true,
        fillColor: _kSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
    );
  }
}

// --- botón guardar con estado de confirmación ---

class _DarkSaveButton extends StatelessWidget {
  final bool saving;
  final bool saved;
  final bool enabled;
  final Color accent;
  final String label;
  final VoidCallback onPressed;

  const _DarkSaveButton({
    required this.saving,
    required this.saved,
    required this.enabled,
    required this.accent,
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
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 350.ms,
              curve: Curves.elasticOut,
            ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: enabled ? accent : const Color(0xFF2A2E3D),
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && !saving
                ? () {
                    HapticFeedback.heavyImpact();
                    onPressed();
                  }
                : null,
            borderRadius: BorderRadius.circular(28),
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: enabled ? Colors.white : _kOnSheetDim,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
