import 'package:flutter/material.dart';

// 3 puntos indicadores de paso para el wizard de ánimo
class MoodStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;

  const MoodStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final active = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? activeColor
                : scheme.outlineVariant.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
