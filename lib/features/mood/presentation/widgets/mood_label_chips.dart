import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../mood_theme.dart';
import 'mood_label_pill.dart';

// grid de etiquetas emocionales con pills de color
class MoodLabelChips extends StatelessWidget {
  final List<String> selectedLabels;
  final ValueChanged<List<String>> onLabelsChanged;

  const MoodLabelChips({
    super.key,
    required this.selectedLabels,
    required this.onLabelsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = MoodTheme.labels(S.of(context));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((def) {
        final selected = selectedLabels.contains(def.key);
        return MoodLabelPill(
          label: def,
          selected: selected,
          onTap: () {
            final updated = List<String>.from(selectedLabels);
            if (selected) {
              updated.remove(def.key);
            } else {
              updated.add(def.key);
            }
            onLabelsChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
