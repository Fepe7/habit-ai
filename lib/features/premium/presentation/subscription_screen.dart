import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/billing_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ux/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/widgets/settings_widgets.dart';

/// Pantalla de gestión de la suscripción Premium.
///
/// Apple y Google NO permiten cancelar desde dentro de la app: la cancelación
/// se hace en la pantalla de suscripciones de la tienda. Esta pantalla muestra
/// el estado actual (reactivo a `PremiumService`) y abre esa gestión nativa,
/// además de permitir restaurar compras. La fuente de verdad del estado premium
/// es Firestore (lo escribe el webhook de RevenueCat).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _busy = false;

  /// Abre la página de gestión/cancelación de la tienda. Prefiere la URL que
  /// da RevenueCat (lleva directo a la suscripción concreta) y, si no hay,
  /// cae a la pantalla de suscripciones genérica de la plataforma.
  Future<void> _openManagement() async {
    if (_busy) return;
    final s = S.of(context);
    setState(() => _busy = true);
    try {
      final url = await BillingService.instance.managementUrl() ??
          BillingService.storeSubscriptionsUrl;
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) AppSnackBar.showError(context, s.subscriptionOpenError);
    } catch (_) {
      if (mounted) AppSnackBar.showError(context, s.subscriptionOpenError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final s = S.of(context);
    setState(() => _busy = true);
    try {
      final ok = await BillingService.instance.restore();
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          ok ? s.paywallRestoreSuccess : s.paywallRestoreNone,
        );
      }
    } on BillingNotConfiguredException {
      if (mounted) AppSnackBar.showInfo(context, s.paywallComingSoon);
    } catch (_) {
      if (mounted) AppSnackBar.showInfo(context, s.paywallRestoreNone);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(s.subscriptionTitle),
        backgroundColor: scheme.surface,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: PremiumService.instance.isPremium,
        builder: (context, isPremium, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _StatusCard(isPremium: isPremium)
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 20),

              if (isPremium) ...[
                SettingsSectionCard(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppTheme.tertiaryContainer,
                  title: s.subscriptionManageSection,
                  children: [
                    SettingsRow(
                      title: s.subscriptionManage,
                      subtitle: s.subscriptionManageSubtitle,
                      onTap: _busy ? null : _openManagement,
                      trailing: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    SettingsRow(
                      title: s.paywallRestore,
                      subtitle: s.subscriptionRestoreSubtitle,
                      onTap: _busy ? null : _restore,
                      divider: false,
                    ),
                  ],
                ).animate().fadeIn(delay: 60.ms, duration: 260.ms),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Text(
                    s.subscriptionCancelHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FilledButton.icon(
                    onPressed: () => context.pushNamed('paywall'),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(s.subscriptionGoPremium),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _restore,
                    child: Text(s.paywallRestore),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta de estado de la suscripción (activa / plan gratuito).
class _StatusCard extends StatelessWidget {
  final bool isPremium;
  const _StatusCard({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (isPremium) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.ambientShadow(opacity: 0.18),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.subscriptionStatusActive,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.subscriptionStatusActiveDesc,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.ambientShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: scheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.subscriptionStatusFree,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.subscriptionStatusFreeDesc,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
