import 'package:flutter/material.dart';
import '../../../../core/widgets/ux/empty_state_view.dart';
import '../../../../l10n/app_localizations.dart';

// Wrapper de compatibilidad — delega en EmptyStateView genérico
class EmptyHabitsView extends StatelessWidget {
  final VoidCallback onCreatePlan;

  const EmptyHabitsView({super.key, required this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EmptyStateView(
      icon: Icons.auto_awesome,
      title: s.emptyHabitsTitle,
      subtitle: s.emptyHabitsSubtitle,
      actionLabel: s.emptyHabitsAction,
      onAction: onCreatePlan,
    );
  }
}
