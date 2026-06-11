import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../l10n/app_localizations.dart';

/// Paywall de HabitAI Premium (3,99 €/mes).
/// El botón de compra es un stub a la espera de la integración de billing
/// (RevenueCat / Play Billing): muestra un aviso de "muy pronto".
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final benefits = [
      (Icons.all_inclusive_rounded, s.paywallBenefitHabits),
      (Icons.chat_bubble_rounded, s.paywallBenefitChat),
      (Icons.insights_rounded, s.paywallBenefitWeekly),
      (Icons.auto_awesome_rounded, s.paywallBenefitInsights),
      (Icons.mood_rounded, s.paywallBenefitMood),
      (Icons.shield_rounded, s.paywallBenefitShields),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // cabecera con corona sobre gradiente hero
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.ambientShadow(opacity: 0.18),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    Text(
                      s.paywallTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.paywallSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // precio destacado
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          s.paywallPrice,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...benefits.indexed.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                entry.$2.$1,
                                color: scheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.$2.$2,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(delay: (80 * entry.$1).ms)
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.06, curve: Curves.easeOutCubic),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.paywallFreePlanNote,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  GradientButton(
                    label: s.paywallCta,
                    icon: Icons.workspace_premium_rounded,
                    onPressed: () {
                      // Stub: aquí se conectará el flujo de compra real
                      // (RevenueCat / in_app_purchase) antes del lanzamiento
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.paywallComingSoon)),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(s.paywallLater),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
