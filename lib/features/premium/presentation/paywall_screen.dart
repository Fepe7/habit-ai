import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/billing_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../l10n/app_localizations.dart';

/// Paywall de HabitAI Premium (3,99 €/mes).
///
/// Diseño tipo "momento premium": fondo oscuro dramático con glow de marca,
/// inspirado en paywalls de apps de seguimiento (Bevel). Siempre oscuro, al
/// margen del tema de la app, para que la compra se sienta como un escaparate.
/// El botón lanza el flujo de RevenueCat; el estado premium real lo escribe el
/// webhook en Firestore y `PremiumService` lo refleja por stream.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // Paleta local del escaparate (oscuro fijo, no depende del ColorScheme).
  // Un solo tono de fondo para toda la pantalla (sin gradiente = sin costuras).
  static const Color _bg = Color(0xFF0E1722);
  static const Color _accent = AppTheme.primaryContainer; // sky #38BDF8
  static const Color _ink = Color(0xFFF4F8FC);
  static const Color _inkSoft = Color(0xFFAEBdCB);

  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    final s = S.of(context);
    setState(() => _busy = true);
    try {
      // purchaseMonthly devuelve si el entitlement quedó activo en el cliente.
      // Puede ser false aunque la compra/reactivación SÍ se procese (el premium
      // real lo escribe el webhook y llega por el stream de Firestore unos
      // segundos después), así que si da false esperamos a confirmarlo.
      final ok = await BillingService.instance.purchaseMonthly() ||
          await _waitForPremium(const Duration(seconds: 8));
      if (!mounted) return;
      if (ok) {
        _snack(s.paywallPurchaseSuccess);
        context.pop();
      }
    } on BillingNotConfiguredException {
      if (mounted) _snack(s.paywallComingSoon);
    } on PlatformException catch (e) {
      // Cancelar no es un error que merezca aviso.
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError && mounted) {
        _snack(s.paywallPurchaseError);
      }
    } catch (_) {
      if (mounted) _snack(s.paywallPurchaseError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final s = S.of(context);
    setState(() => _busy = true);
    try {
      // restore() puede dar false aunque la compra se esté transfiriendo a esta
      // cuenta (mismo Apple ID, otra cuenta de Firebase): RevenueCat dispara el
      // TRANSFER por detrás y el premium llega por el webhook→Firestore. Si da
      // false, esperamos al stream antes de decir "no hay compras".
      final ok = await BillingService.instance.restore() ||
          await _waitForPremium(const Duration(seconds: 8));
      if (!mounted) return;
      _snack(ok ? s.paywallRestoreSuccess : s.paywallRestoreNone);
      if (ok) context.pop();
    } on BillingNotConfiguredException {
      if (mounted) _snack(s.paywallComingSoon);
    } catch (_) {
      if (mounted) _snack(s.paywallRestoreNone);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Espera a que `PremiumService.isPremium` se confirme (lo escribe el webhook
  /// en Firestore tras la compra/transferencia y llega por stream). Evita el
  /// falso "no hay compras" cuando el premium llega con unos segundos de retardo.
  Future<bool> _waitForPremium(Duration timeout) async {
    final premium = PremiumService.instance.isPremium;
    if (premium.value) return true;
    final completer = Completer<bool>();
    void listener() {
      if (premium.value && !completer.isCompleted) completer.complete(true);
    }

    premium.addListener(listener);
    try {
      return await completer.future
          .timeout(timeout, onTimeout: () => premium.value);
    } finally {
      premium.removeListener(listener);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Durante la fase de lanzamiento gratis no se vende nada: todo está
    // desbloqueado para todos. Mostramos el escaparate sin precio ni CTA de
    // compra/restaurar (App Review rechaza productos de pago no expuestos), solo
    // un mensaje informativo. Reversible con el mismo flag `freeLaunchPhase`.
    final freeLaunch = PremiumLimits.freeLaunchPhase;

    final benefits = [
      s.paywallBenefitHabits,
      s.paywallBenefitChat,
      s.paywallBenefitWeekly,
      s.paywallBenefitInsights,
      s.paywallBenefitMood,
      s.paywallBenefitShields,
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status bar transparente (el fondo pasa por debajo sin la franja del
      // sistema). La barra de navegación NO puede ser transparente: la app no
      // corre en edge-to-edge, así que no hay nada detrás y Android la pinta
      // de blanco. Se pinta del mismo tono sólido del fondo.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        // Un ÚNICO color sólido en toda la pantalla. Sin gradientes ni capas de
        // distinto tono: así no puede quedar ninguna costura/junta (era eso lo
        // que se veía como "corte", el borde entre dos tonos casi iguales).
        backgroundColor: _bg,
        body: SafeArea(
              child: Column(
                children: [
                  // Cerrar
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, right: 8),
                      child: IconButton(
                        onPressed: _busy ? null : () => context.pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: _inkSoft.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _hero(s, freeLaunch),
                          const SizedBox(height: 26),
                          _benefitsCard(benefits),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  freeLaunch ? _freeLaunchFooter(s) : _footer(s),
                ],
              ),
            ),
      ),
    );
  }

  // ---- Secciones -----------------------------------------------------------

  Widget _hero(S s, bool freeLaunch) {
    return Column(
      children: [
        // Insignia con corona sobre gradiente hero + glow.
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        // Pill PREMIUM
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: Text(
            s.paywallBadge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: _accent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          freeLaunch ? s.freeLaunchPaywallTitle : s.paywallTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.1,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          freeLaunch ? s.freeLaunchPaywallBody : s.paywallSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: _inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _benefitsCard(List<String> benefits) {
    // Sin recuadro: la lista va directa sobre el fondo plano. El borde sutil de
    // la tarjeta se leía como una línea/corte a media pantalla, así que fuera.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        children: [
          for (final text in benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _priceCard(S s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.16),
            AppTheme.primary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.paywallPrice,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.paywallCancelAnytime,
                  style: const TextStyle(fontSize: 12, color: _inkSoft),
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 17, color: Color(0xFF06222E)),
          ),
        ],
      ),
    );
  }

  /// Footer de la fase de lanzamiento gratis: sin precio ni botones de compra,
  /// solo un cierre. El estado premium real lo siguen gestionando el webhook y
  /// `PremiumService`; aquí no se ofrece ninguna transacción.
  Widget _freeLaunchFooter(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
      child: GradientButton(
        label: s.freeLaunchPaywallCta,
        icon: Icons.check_rounded,
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _footer(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
      child: Column(
        children: [
          _priceCard(s),
          const SizedBox(height: 14),
          GradientButton(
            label: s.paywallCta,
            icon: Icons.workspace_premium_rounded,
            loading: _busy,
            onPressed: _busy ? null : _buy,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _link(s.paywallRestore, _busy ? null : _restore),
              Text('·', style: TextStyle(color: _inkSoft.withValues(alpha: 0.5))),
              _link(s.paywallLater, _busy ? null : () => context.pop()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _link(String label, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _inkSoft,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
