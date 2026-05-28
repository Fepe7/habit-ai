import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

// Chips de selección múltiple para etiquetas de estado de ánimo
class MoodLabelChips extends StatelessWidget {
  final List<String> selectedLabels;
  final ValueChanged<List<String>> onLabelsChanged;

  const MoodLabelChips({
    super.key,
    required this.selectedLabels,
    required this.onLabelsChanged,
  });

  static List<_LabelDef> _labels(S s) => [
        _LabelDef('anxiety', s.moodLabelAnxiety),
        _LabelDef('tiredness', s.moodLabelTiredness),
        _LabelDef('motivation', s.moodLabelMotivation),
        _LabelDef('calm', s.moodLabelCalm),
        _LabelDef('stress', s.moodLabelStress),
        _LabelDef('sadness', s.moodLabelSadness),
        _LabelDef('energy', s.moodLabelEnergy),
        _LabelDef('anger', s.moodLabelAnger),
        _LabelDef('gratitude', s.moodLabelGratitude),
        _LabelDef('focus', s.moodLabelFocus),
      ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = _labels(s);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((def) {
        final selected = selectedLabels.contains(def.key);
        return FilterChip(
          label: Text(def.display),
          selected: selected,
          onSelected: (_) {
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

class _LabelDef {
  final String key;
  final String display;
  const _LabelDef(this.key, this.display);
}
