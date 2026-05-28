import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../mood_theme.dart';
import 'mood_label_pill.dart';

// etiquetas emocionales en dos grupos: primero el grupo más relevante según el rating
class MoodLabelChips extends StatelessWidget {
  final List<String> selectedLabels;
  final ValueChanged<List<String>> onLabelsChanged;
  // rating seleccionado — reordena qué grupo aparece primero
  final int? rating;

  const MoodLabelChips({
    super.key,
    required this.selectedLabels,
    required this.onLabelsChanged,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = MoodTheme.labels(s);

    final negatives = all.where((l) => !l.isPositive).toList();
    final positives = all.where((l) => l.isPositive).toList();

    // rating <= 2 → negativos primero (más relevantes para ese estado)
    // rating >= 4 → positivos primero
    // rating == 3 o null → negativos primero por defecto
    final showPositivesFirst = (rating ?? 0) >= 4;

    final firstGroup = showPositivesFirst ? positives : negatives;
    final secondGroup = showPositivesFirst ? negatives : positives;
    final firstLabel = showPositivesFirst
        ? s.moodLabelsPositive
        : s.moodLabelsNegative;
    final secondLabel = showPositivesFirst
        ? s.moodLabelsNegative
        : s.moodLabelsPositive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupSection(
          label: firstLabel,
          defs: firstGroup,
          selectedLabels: selectedLabels,
          onLabelsChanged: onLabelsChanged,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
        _GroupSection(
          label: secondLabel,
          defs: secondGroup,
          selectedLabels: selectedLabels,
          onLabelsChanged: onLabelsChanged,
          scheme: scheme,
        ),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String label;
  final List<MoodLabelDef> defs;
  final List<String> selectedLabels;
  final ValueChanged<List<String>> onLabelsChanged;
  final ColorScheme scheme;

  const _GroupSection({
    required this.label,
    required this.defs,
    required this.selectedLabels,
    required this.onLabelsChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: defs.map((def) {
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
        ),
      ],
    );
  }
}
