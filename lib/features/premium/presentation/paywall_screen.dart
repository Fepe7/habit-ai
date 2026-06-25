import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/billing_service.dart';
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
  static const Color _bgTop = Color(0xFF101A26);
  static const Color _bgBottom = Color(0xFF080D14);
  static const Color _accent = AppTheme.primaryContainer; // sky #38BDF8
  static const Color _ink = Color(0xFFF4F8FC);
  static const Color _inkSoft = Color(0xFFAEBdCB);
  static const Color _card = Color(0xFF18242F);

  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    final s = S.of(context);
    setState(() => _busy = true);
    try {
      final ok = await BillingService.instance.purchaseMonthly();
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
      final ok = await BillingService.instance.restore();
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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final benefits = [
      s.paywallBenefitHabits,
      s.paywallBenefitChat,
      s.paywallBenefitWeekly,
      s.paywallBenefitInsights,
      s.paywallBenefitMood,
      s.paywallBenefitShields,
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bgBottom,
        body: Stack(
          children: [
            // Fondo: degradado vertical + glow de marca difuso arriba.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_bgTop, _bgBottom],
                  ),
                ),
              ),
            ),
            // Glow de marca anclado al borde superior: el punto más brillante
            // vive en el borde y se difumina hacia abajo, así no queda un corte
            // duro arriba (un círculo desplazado sí lo dejaba al recortar el Stack).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.1,
                      colors: [
                        _accent.withValues(alpha: 0.32),
                        _accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 700.ms),
            ),
            SafeArea(
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
                          _hero(s),
                          const SizedBox(height: 26),
                          _benefitsCard(benefits),
                          const SizedBox(height: 16),
                          _priceCard(s),
                          const SizedBox(height: 14),
                          Text(
                            s.paywallFreePlanNote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: _inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  _footer(s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Secciones -----------------------------------------------------------

  Widget _hero(S s) {
    return Column(
      children: [
        // Insignia con corona sobre gradiente hero + glow.
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 38,
          ),
        ).animate().scale(
              duration: 450.ms,
              curve: Curves.easeOutBack,
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
        ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.3),
        const SizedBox(height: 16),
        Text(
          s.paywallTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.1,
            color: _ink,
          ),
        ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 10),
        Text(
          s.paywallSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: _inkSoft,
          ),
        ).animate(delay: 220.ms).fadeIn(),
      ],
    );
  }

  Widget _benefitsCard(List<String> benefits) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (final (i, text) in benefits.indexed)
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
            )
                .animate(delay: (260 + 70 * i).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.08, curve: Curves.easeOutCubic),
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
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.15);
  }

  Widget _footer(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
      child: Column(
        children: [
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
