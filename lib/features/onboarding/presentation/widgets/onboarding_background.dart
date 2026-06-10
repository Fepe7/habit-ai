import 'dart:math' as math;

import 'package:flutter/material.dart';

// Fondo vivo del onboarding: gradiente de marca que cambia de tinte según
// el paso actual + blobs orgánicos que se desplazan lentamente en bucle.
class OnboardingBackground extends StatefulWidget {
  final int step;

  const OnboardingBackground({super.key, required this.step});

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  // Pareja de colores del gradiente por paso (arriba → abajo)
  static const _gradients = <List<Color>>[
    [Color(0xFF003A52), Color(0xFF00668A)], // bienvenida: teal profundo
    [Color(0xFF004A66), Color(0xFF0E7FA8)], // nombre: teal medio
    [Color(0xFF00516E), Color(0xFF0E7FA8)], // categorías
    [Color(0xFF073B5C), Color(0xFF006591)], // estilo de vida
    [Color(0xFF1F2A4D), Color(0xFF00668A)], // IA generando: tinte índigo
    [Color(0xFF064E3B), Color(0xFF0E7490)], // primer check-in: teal-emerald
    [Color(0xFF2E1065), Color(0xFF1F2A4D)], // tour funciones IA: violeta
    [Color(0xFF064E3B), Color(0xFF059669)], // notificaciones: emerald éxito
  ];

  // Color de acento de cada blob por paso
  static const _accents = <Color>[
    Color(0xFF38BDF8),
    Color(0xFF7BD0FF),
    Color(0xFF34D399),
    Color(0xFF39B8FD),
    Color(0xFFF59E0B),
    Color(0xFF34D399),
    Color(0xFFC4B5FD),
    Color(0xFF34D399),
  ];

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step.clamp(0, _gradients.length - 1);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[step],
        ),
      ),
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          final t = _drift.value * 2 * math.pi;
          return Stack(
            children: [
              _blob(
                context,
                color: _accents[step],
                size: 320,
                dx: 0.18 + 0.08 * math.sin(t),
                dy: 0.12 + 0.06 * math.cos(t * 0.8),
                opacity: 0.30,
              ),
              _blob(
                context,
                color: Colors.white,
                size: 240,
                dx: 0.85 + 0.06 * math.cos(t * 1.2),
                dy: 0.35 + 0.07 * math.sin(t * 0.9),
                opacity: 0.10,
              ),
              _blob(
                context,
                color: _accents[step],
                size: 380,
                dx: 0.55 + 0.10 * math.sin(t * 0.6 + 2),
                dy: 0.92 + 0.05 * math.cos(t * 0.7),
                opacity: 0.22,
              ),
            ],
          );
        },
      ),
    );
  }

  // Blob radial difuminado posicionado en fracciones de pantalla
  Widget _blob(
    BuildContext context, {
    required Color color,
    required double size,
    required double dx,
    required double dy,
    required double opacity,
  }) {
    final screen = MediaQuery.sizeOf(context);
    return Positioned(
      left: screen.width * dx - size / 2,
      top: screen.height * dy - size / 2,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
