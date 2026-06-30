import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../l10n/app_localizations.dart';

/// Funciones premium que pueden mostrarse bloqueadas. Cada una resuelve su
/// propio icono + textos contextuales en [PremiumLockedScreen].
enum PremiumFeature { routineChat, weeklyReview, butterfly, patterns, mood }

extension PremiumFeatureLaunch on PremiumFeature {
  /// Durante la fase de lanzamiento gratis estas funciones de IA se abren a
  /// todos bajo cuota semanal (el backend la aplica). `mood` se queda premium.
  bool get openDuringFreeLaunch => switch (this) {
    PremiumFeature.routineChat ||
    PremiumFeature.weeklyReview ||
    PremiumFeature.butterfly ||
    PremiumFeature.patterns => true,
    PremiumFeature.mood => false,
  };
}

/// Pantalla que se muestra (en vez del contenido real) cuando un usuario free
/// abre una función premium. En lugar de esconderla, la enseña "bloqueada":
/// un teaser difuminado de fondo + candado con glow + copy específico de la
/// función + CTA al paywall. Mismo lenguaje visual que [PaywallScreen].
class PremiumLockedScreen extends StatelessWidget {
  const PremiumLockedScreen({super.key, required this.feature});

  final PremiumFeature feature;

  // Paleta del escaparate (oscuro fijo, igual que el paywall).
  static const Color _bgTop = Color(0xFF101A26);
  static const Color _bgBottom = Color(0xFF080D14);
  static const Color _accent = AppTheme.primaryContainer; // sky #38BDF8
  static const Color _ink = Color(0xFFF4F8FC);
  static const Color _inkSoft = Color(0xFFAEBDCB);

  IconData get _icon => switch (feature) {
        PremiumFeature.routineChat => Icons.auto_awesome_rounded,
        PremiumFeature.weeklyReview => Icons.calendar_month_rounded,
        PremiumFeature.butterfly => Icons.auto_awesome_rounded,
        PremiumFeature.patterns => Icons.insights_rounded,
        PremiumFeature.mood => Icons.mood_rounded,
      };

  String _title(S s) => switch (feature) {
        PremiumFeature.routineChat => s.lockedChatTitle,
        PremiumFeature.weeklyReview => s.lockedWeeklyTitle,
        PremiumFeature.butterfly => s.lockedButterflyTitle,
        PremiumFeature.patterns => s.lockedPatternsTitle,
        PremiumFeature.mood => s.lockedMoodTitle,
      };

  String _desc(S s) => switch (feature) {
        PremiumFeature.routineChat => s.lockedChatDesc,
        PremiumFeature.weeklyReview => s.lockedWeeklyDesc,
        PremiumFeature.butterfly => s.lockedButterflyDesc,
        PremiumFeature.patterns => s.lockedPatternsDesc,
        PremiumFeature.mood => s.lockedMoodDesc,
      };

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bgBottom,
        body: Stack(
          children: [
            // Fondo: degradado + glow de marca.
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
            Positioned(
              top: -150,
              left: -40,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _accent.withValues(alpha: 0.30),
                        _accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 700.ms),
            ),
            // Teaser difuminado: maqueta de contenido que "se intuye" detrás.
            const Positioned.fill(child: IgnorePointer(child: _BlurredTeaser())),
            // Velo para fundir el teaser con el fondo y dar foco al panel.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _bgBottom.withValues(alpha: 0.55),
                        _bgBottom.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Botón cerrar
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: IconButton(
                    onPressed: () => _close(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _inkSoft.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
            // Panel de bloqueo
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Candado con glow sobre el gradiente hero.
                      _LockBadge(icon: _icon)
                          .animate()
                          .scale(duration: 450.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 20),
                      _PremiumPill(label: s.paywallBadge)
                          .animate(delay: 120.ms)
                          .fadeIn()
                          .slideY(begin: 0.3),
                      const SizedBox(height: 14),
                      Text(
                        _title(s),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.15,
                          color: _ink,
                        ),
                      ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.2),
                      const SizedBox(height: 10),
                      Text(
                        _desc(s),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: _inkSoft,
                        ),
                      ).animate(delay: 220.ms).fadeIn(),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: s.paywallCta,
                        icon: Icons.workspace_premium_rounded,
                        onPressed: () => context.push('/paywall'),
                      ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.2),
                      TextButton(
                        onPressed: () => _close(context),
                        style: TextButton.styleFrom(foregroundColor: _inkSoft),
                        child: Text(s.paywallLater),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Insignia circular con el icono de la función y un resplandor cian.
class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PremiumLockedScreen._accent.withValues(alpha: 0.45),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 36),
          ),
          // Candadito superpuesto en la esquina inferior.
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF06222E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: PremiumLockedScreen._accent,
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.lock_rounded, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPill extends StatelessWidget {
  const _PremiumPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: PremiumLockedScreen._accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PremiumLockedScreen._accent.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: PremiumLockedScreen._accent,
        ),
      ),
    );
  }
}

/// Maqueta decorativa difuminada que insinúa el contenido bloqueado detrás.
class _BlurredTeaser extends StatelessWidget {
  const _BlurredTeaser();

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );

    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 120, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(0.5, 22),
            bar(1.0, 96),
            bar(0.85, 22),
            bar(1.0, 70),
            bar(0.7, 22),
            bar(1.0, 70),
          ],
        ),
      ),
    );
  }
}
