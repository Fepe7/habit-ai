import 'package:flutter/material.dart';

/// Conector visual entre dos hábitos consecutivos de una cadena.
/// Muestra una línea vertical con un punto central, alineada con el check circle.
class HabitStackConnector extends StatelessWidget {
  const HabitStackConnector({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // el check circle del HabitCard tiene: padding left 16 + radio 15 = centro en 31px
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          const SizedBox(width: 30), // alinear con el centro del check circle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 2,
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 1),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 1),
              Container(
                width: 2,
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
