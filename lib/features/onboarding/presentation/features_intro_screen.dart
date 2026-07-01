import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import 'widgets/onboarding_background.dart';

/// Intro de funciones de la app con el mismo lenguaje visual del onboarding
/// (fondo de gradiente animado + tarjetas translúcidas): explica qué vive en
/// cada pestaña y dónde encontrarlo. Se muestra UNA vez por instalación, así
/// los usuarios existentes también la ven tras actualizar.
class FeaturesIntroScreen extends StatelessWidget {
  const FeaturesIntroScreen({super.key});

  static const _prefsKey = 'features_intro_seen_v1';

  /// Abre la intro solo si no se ha visto nunca en este dispositivo.
  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) ?? false) return;
    if (!context.mounted) return;
    // marcar como vista al abrirse: si la cierra a medias no se le vuelve a
    // interrumpir en cada arranque
    await prefs.setBool(_prefsKey, true);
    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FeaturesIntroScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Una tarjeta por pestaña de la bottom nav, con su icono como chip de
    // ubicación para que el usuario sepa dónde tocar después.
    final features = [
      _Feature(
        icon: Icons.check_circle_rounded,
        gradient: const [Color(0xFF38BDF8), Color(0xFF00668A)],
        title: s.tourHabitsTitle,
        description: s.tourHabitsBody,
        whereIcon: Icons.check_circle_outline_rounded,
        whereLabel: s.navHabits,
      ),
      _Feature(
        icon: Icons.bar_chart_rounded,
        gradient: const [Color(0xFF34D399), Color(0xFF059669)],
        title: s.tourDashboardTitle,
        description: s.tourDashboardBody,
        whereIcon: Icons.bar_chart_outlined,
        whereLabel: s.navProgress,
      ),
      _Feature(
        icon: Icons.auto_awesome_rounded,
        gradient: const [Color(0xFFC4B5FD), Color(0xFF5B21B6)],
        title: s.tourAITitle,
        description: s.tourAIBody,
        whereIcon: Icons.auto_awesome_outlined,
        whereLabel: s.navAssistant,
      ),
      _Feature(
        icon: Icons.search_rounded,
        gradient: const [Color(0xFFF9A8D4), Color(0xFF9D174D)],
        title: s.tourExploreTitle,
        description: s.tourExploreBody,
        whereIcon: Icons.search_rounded,
        whereLabel: s.navExplore,
      ),
      _Feature(
        icon: Icons.person_rounded,
        gradient: const [Color(0xFFF59E0B), Color(0xFF855300)],
        title: s.tourProfileTitle,
        description: s.tourProfileBody,
        whereIcon: Icons.person_outline_rounded,
        whereLabel: s.navProfile,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // paso 6 = tinte violeta (el mismo del tour de funciones IA)
          const Positioned.fill(child: OnboardingBackground(step: 6)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    s.tourIntroTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    s.tourIntroSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: features.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FeatureCard(feature: features[i]),
                      )
                          .animate()
                          .fadeIn(delay: (250 + i * 130).ms, duration: 400.ms)
                          .slideX(
                            begin: 0.12,
                            delay: (250 + i * 130).ms,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F2A4D),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(s.tourDone),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String description;
  final IconData whereIcon;
  final String whereLabel;

  const _Feature({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.description,
    required this.whereIcon,
    required this.whereLabel,
  });
}

// Card de función: icono con gradiente + descripción + chip de ubicación
// (mismo diseño que el tour de funciones IA del onboarding)
class _FeatureCard extends StatelessWidget {
  final _Feature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: feature.gradient),
            ),
            child: Icon(feature.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  feature.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                // Chip "dónde encontrarlo": la pestaña de la bottom nav
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        feature.whereIcon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        feature.whereLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
