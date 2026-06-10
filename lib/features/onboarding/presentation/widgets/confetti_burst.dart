import 'dart:math' as math;

import 'package:flutter/material.dart';

// Explosión de confeti ligera con CustomPainter (sin paquetes externos).
// Se dispara una sola vez al montarse; al terminar se vuelve invisible.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _palette = <Color>[
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFF59E0B),
    Color(0xFFF9A8D4),
    Color(0xFFC4B5FD),
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _particles = List.generate(46, (_) => _Particle.random(random, _palette));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isCompleted) return const SizedBox.shrink();
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle; // dirección inicial del disparo
  final double velocity; // alcance relativo
  final double size;
  final double spin; // vueltas durante la caída
  final Color color;

  const _Particle({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.spin,
    required this.color,
  });

  factory _Particle.random(math.Random random, List<Color> palette) {
    return _Particle(
      // abanico hacia arriba (entre -160º y -20º)
      angle: -math.pi * (0.1 + 0.8 * random.nextDouble()),
      velocity: 0.4 + random.nextDouble() * 0.6,
      size: 5 + random.nextDouble() * 5,
      spin: (random.nextDouble() - 0.5) * 10,
      color: palette[random.nextInt(palette.length)],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.30);
    final eased = Curves.easeOutCubic.transform(progress);
    final paint = Paint();

    for (final p in particles) {
      final reach = p.velocity * size.shortestSide * 0.55;
      final dx = math.cos(p.angle) * reach * eased;
      // la gravedad va ganando a la propulsión inicial
      final dy = math.sin(p.angle) * reach * eased +
          size.height * 0.45 * progress * progress;
      final position = origin + Offset(dx, dy);

      paint.color = p.color.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(p.spin * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
