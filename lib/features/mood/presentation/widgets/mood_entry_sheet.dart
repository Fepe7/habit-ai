import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import 'mood_emoji_selector.dart';
import 'mood_label_chips.dart';

// Bottom sheet para registrar estado de ánimo en ~5 segundos
class MoodEntrySheet extends StatefulWidget {
  // hábitos completados hoy — el caller los pasa para evitar N+1 Firestore
  final List<HabitModel> completedHabits;

  const MoodEntrySheet({
    super.key,
    this.completedHabits = const [],
  });

  static Future<void> show(
    BuildContext context, {
    List<HabitModel> completedHabits = const [],
  }) {
    return showAppBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => MoodEntrySheet(completedHabits: completedHabits),
    );
  }

  @override
  State<MoodEntrySheet> createState() => _MoodEntrySheetState();
}

class _MoodEntrySheetState extends State<MoodEntrySheet> {
  int? _rating;
  List<String> _labels = [];
  final _noteCtrl = TextEditingController();
  bool _noteExpanded = false;
  late String _timeBlock;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _timeBlock = MoodEntryModel.timeBlockFromHour(DateTime.now().hour);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == null) return;
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
      await MoodRepository(uid: uid).createEntry(entry);
      await FeedbackService.instance.habitCompleted();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 20),

            Text(
              s.moodHowAreYou,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),

            MoodEmojiSelector(
              selectedRating: _rating,
              onRatingChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 24),

            MoodLabelChips(
              selectedLabels: _labels,
              onLabelsChanged: (l) => setState(() => _labels = l),
            ),
            const SizedBox(height: 20),

            // nota opcional — expandible
            if (_noteExpanded)
              TextField(
                controller: _noteCtrl,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.moodNotePlaceholder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  counterStyle: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              GestureDetector(
                onTap: () => setState(() => _noteExpanded = true),
                child: Text(
                  s.moodNotePlaceholder,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            const SizedBox(height: 20),

            Text(
              s.moodTimeBlockLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            _TimeBlockChips(
              selected: _timeBlock,
              onChanged: (tb) => setState(() => _timeBlock = tb),
            ),

            if (widget.completedHabits.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                s.moodHabitsToday,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
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

            const SizedBox(height: 28),

            GradientButton(
              onPressed: _rating != null && !_saving ? _save : null,
              label: s.moodSave,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBlockChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TimeBlockChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final blocks = [
      ('morning', s.moodTimeBlockMorning),
      ('midday', s.moodTimeBlockMidday),
      ('afternoon', s.moodTimeBlockAfternoon),
      ('night', s.moodTimeBlockNight),
    ];

    return Wrap(
      spacing: 8,
      children: blocks.map((b) {
        return ChoiceChip(
          label: Text(b.$2),
          selected: selected == b.$1,
          onSelected: (_) => onChanged(b.$1),
        );
      }).toList(),
    );
  }
}
