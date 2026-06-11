import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/habits/data/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../services/premium_service.dart';

/// Helpers de gating premium para la capa de presentación.
/// El backend es la fuente de verdad (las functions rechazan a free);
/// esto evita llegar a ese error y convierte el límite en upsell.
class PremiumGate {
  PremiumGate._();

  /// True si el usuario puede crear otro hábito (premium o por debajo del
  /// límite free). Si no puede, muestra el diálogo de upsell y devuelve false.
  static Future<bool> checkHabitLimit(
    BuildContext context,
    HabitRepository repo,
  ) async {
    if (PremiumService.instance.isPremium.value) return true;
    final habits = await repo.getActiveHabits();
    if (habits.length < PremiumLimits.maxFreeHabits) return true;
    if (context.mounted) await showHabitLimitDialog(context);
    return false;
  }

  /// Diálogo de límite de hábitos free con CTA al paywall
  static Future<void> showHabitLimitDialog(BuildContext context) {
    final s = S.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.workspace_premium_rounded,
          color: Theme.of(ctx).colorScheme.primary,
          size: 32,
        ),
        title: Text(s.freeHabitLimitTitle),
        content: Text(s.freeHabitLimitBody(PremiumLimits.maxFreeHabits)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.paywallLater),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/paywall');
            },
            child: Text(s.paywallCta),
          ),
        ],
      ),
    );
  }
}
