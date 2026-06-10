import 'package:flutter/material.dart';

// Barra de progreso segmentada: cada paso completado rellena su segmento
// con una animación de barrido, el paso actual queda medio lleno.
class OnboardingProgressBar extends StatelessWidget {
  final int step;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final double fill = i < step ? 1.0 : (i == step ? 0.45 : 0.0);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 5,
                color: Colors.white.withValues(alpha: 0.25),
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  widthFactor: fill,
                  heightFactor: 1,
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
