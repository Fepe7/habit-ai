import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Vista cuando no hay habitos creados
class EmptyHabitsView extends StatelessWidget {
  final VoidCallback onCreatePlan;

  const EmptyHabitsView({super.key, required this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // icono grande
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 64,
                color: colorScheme.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
            const SizedBox(height: 32),

            Text(
              '¡Empieza tu camino!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 12),

            Text(
              'Cuéntale a la IA tus metas y te creará\nun plan de hábitos personalizado.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 400.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 40),

            FilledButton.icon(
              onPressed: onCreatePlan,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Crear mi plan con IA'),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}
