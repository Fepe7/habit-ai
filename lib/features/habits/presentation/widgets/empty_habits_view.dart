import 'package:flutter/material.dart';
import '../../../../core/widgets/ux/empty_state_view.dart';

// Wrapper de compatibilidad — delega en EmptyStateView genérico
class EmptyHabitsView extends StatelessWidget {
  final VoidCallback onCreatePlan;

  const EmptyHabitsView({super.key, required this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.auto_awesome,
      title: '¡Empieza tu camino!',
      subtitle: 'Cuéntale a la IA tus metas y te creará\nun plan de hábitos personalizado.',
      actionLabel: 'Crear mi plan con IA',
      onAction: onCreatePlan,
    );
  }
}
