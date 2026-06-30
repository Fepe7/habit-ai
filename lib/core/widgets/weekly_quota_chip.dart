import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../services/premium_service.dart';

/// Chip que muestra cuántos usos free quedan ESTA SEMANA de una función de IA.
/// Lee [PremiumService.weeklyRemaining] (reactivo): cuando el backend consume
/// la cuota, el contador baja solo. Se oculta si la función no tiene límite
/// para el usuario (premium, o estado aún desconocido). Tap → paywall.
class WeeklyQuotaChip extends StatelessWidget {
  const WeeklyQuotaChip({super.key, required this.featureKey});

  /// Clave de la función, igual que en FREE_WEEKLY_LIMITS del backend:
  /// 'routineChat', 'weeklyReview', 'butterfly', 'patterns', 'renegotiation'.
  final String featureKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, int?>>(
      valueListenable: PremiumService.instance.weeklyRemaining,
      builder: (context, remaining, _) {
        final left = remaining[featureKey];
        if (left == null) return const SizedBox.shrink(); // premium / desconocido
        final scheme = Theme.of(context).colorScheme;
        final exhausted = left <= 0;
        final color = exhausted ? scheme.error : scheme.primary;
        return GestureDetector(
          onTap: () => context.push('/paywall'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  exhausted ? Icons.lock_clock_rounded : Icons.bolt_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  S.of(context).freeWeeklyLeft(left),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
