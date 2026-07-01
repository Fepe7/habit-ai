import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_emoji.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';
import 'mood_entry_sheet.dart';

// Botón circular de ánimo para headers — refleja la franja actual y abre el sheet
class MoodHeaderButton extends StatefulWidget {
  final List<HabitModel> completedHabits;

  const MoodHeaderButton({
    super.key,
    this.completedHabits = const [],
  });

  @override
  State<MoodHeaderButton> createState() => _MoodHeaderButtonState();
}

class _MoodHeaderButtonState extends State<MoodHeaderButton> {
  MoodRepository? _repo;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _repo = MoodRepository(uid: uid);
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<MoodEntryModel>>(
      stream: repo.watchTodayEntries(),
      builder: (context, snap) {
        // solo refleja la franja horaria actual: emoji si ya registró, carita neutra si no
        final block = MoodEntryModel.timeBlockFromHour(DateTime.now().hour);
        MoodEntryModel? blockEntry;
        for (final e in (snap.data ?? const <MoodEntryModel>[])) {
          if (e.timeBlock == block) blockEntry = e;
        }

        return GestureDetector(
          onTap: () => MoodEntrySheet.show(
            context,
            completedHabits: widget.completedHabits,
            initialEntry: blockEntry,
          ),
          child: Tooltip(
            message: S.of(context).moodHowAreYou,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // relleno tonal, como el resto de botones del header
                color: scheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: blockEntry != null
                  ? AppEmoji.mood(blockEntry.rating, size: 22)
                  : Icon(
                      Icons.add_reaction_outlined,
                      color: scheme.onSurfaceVariant,
                      size: 22,
                    ),
            ),
          ),
        );
      },
    );
  }
}
