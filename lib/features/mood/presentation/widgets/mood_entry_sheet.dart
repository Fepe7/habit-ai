import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../habits/domain/habit_model.dart';
import 'mood_entry_wizard.dart';

// bottom sheet de registro de ánimo — delega toda la UI al wizard
class MoodEntrySheet extends StatelessWidget {
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => MoodEntrySheet(completedHabits: completedHabits),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MoodEntryWizard(completedHabits: completedHabits);
  }
}
