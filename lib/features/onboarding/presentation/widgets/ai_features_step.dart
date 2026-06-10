import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../l10n/app_localizations.dart';

// Paso 4: tour de las funciones de IA — qué hace cada una y dónde
// encontrarla, para que el usuario no las descubra por casualidad.
class AIFeaturesStep extends StatelessWidget {
  final VoidCallback onContinue;

  const AIFeaturesStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final features = [
      _Feature(
        icon: Icons.chat_bubble_rounded,
        gradient: const [Color(0xFF38BDF8), Color(0xFF00668A)],
        title: s.onbFeatChatTitle,
        description: s.onbFeatChatDesc,
        whereIcon: Icons.auto_awesome,
        whereLabel: s.onbWhereAssistantTab,
      ),
      _Feature(
        icon: Icons.insights_rounded,
        gradient: const [Color(0xFF34D399), Color(0xFF059669)],
        title: s.onbFeatReviewTitle,
        description: s.onbFeatReviewDesc,
        whereIcon: Icons.bar_chart_rounded,
        whereLabel: s.onbWhereProgressTab,
      ),
      _Feature(
        icon: Icons.flutter_dash,
        gradient: const [Color(0xFFF59E0B), Color(0xFF855300)],
        title: s.onbFeatButterflyTitle,
        description: s.onbFeatButterflyDesc,
        whereIcon: Icons.bar_chart_rounded,
        whereLabel: s.onbWhereProgressTab,
      ),
      _Feature(
        icon: Icons.handshake_rounded,
        gradient: const [Color(0xFFC4B5FD), Color(0xFF5B21B6)],
        title: s.onbFeatRenegotiationTitle,
        description: s.onbFeatRenegotiationDesc,
        whereIcon: Icons.check_circle_outline_rounded,
        whereLabel: s.onbWhereHabitDetail,
      ),
      _Feature(
        icon: Icons.radar_rounded,
        gradient: const [Color(0xFFF9A8D4), Color(0xFF9D174D)],
        title: s.onbFeatPatternsTitle,
        description: s.onbFeatPatternsDesc,
        whereIcon: Icons.bar_chart_rounded,
        whereLabel: s.onbWhereProgressTab,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            s.onbAiFeaturesTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            s.onbAiFeaturesSubtitle,
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
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F2A4D),
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(s.confirm),
          ),
          const SizedBox(height: 32),
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
                // Chip "dónde encontrarlo"
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
