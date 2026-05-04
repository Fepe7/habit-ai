import 'package:flutter/material.dart';

// Logo principal de HabitAI — Spark Check (concepto 01)
// Squircle con gradiente azul, check blanco y chispa ámbar de 4 puntas.
// viewBox original: 200×200
class SparkCheckLogo extends StatelessWidget {
  final double size;
  final bool mono;

  const SparkCheckLogo({super.key, this.size = 48, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparkCheckPainter(mono: mono),
      ),
    );
  }
}

class _SparkCheckPainter extends CustomPainter {
  final bool mono;

  const _SparkCheckPainter({this.mono = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200.0;

    canvas.save();
    canvas.scale(s);

    // squircle: aproximación con 4 bezier cúbicas
    final squirclePath = Path()
      ..moveTo(100, 8)
      ..cubicTo(152, 8, 192, 48, 192, 100)
      ..cubicTo(192, 152, 152, 192, 100, 192)
      ..cubicTo(48, 192, 8, 152, 8, 100)
      ..cubicTo(8, 48, 48, 8, 100, 8)
      ..close();

    if (mono) {
      canvas.drawPath(
        squirclePath,
        Paint()..color = const Color(0xFF0B1220),
      );
    } else {
      final gradientPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 200));
      canvas.drawPath(squirclePath, gradientPaint);
    }

    // check: M52 104 L86 138 L150 70
    final checkPath = Path()
      ..moveTo(52, 104)
      ..lineTo(86, 138)
      ..lineTo(150, 70);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // sparkle de 4 puntas en (150, 50)
    canvas.save();
    canvas.translate(150, 50);
    final sparkPath = Path()
      ..moveTo(0, -22)
      ..lineTo(5, -5)
      ..lineTo(22, 0)
      ..lineTo(5, 5)
      ..lineTo(0, 22)
      ..lineTo(-5, 5)
      ..lineTo(-22, 0)
      ..lineTo(-5, -5)
      ..close();
    canvas.drawPath(
      sparkPath,
      Paint()..color = mono ? const Color(0xFF0B1220) : const Color(0xFFF59E0B),
    );
    canvas.drawPath(
      sparkPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparkCheckPainter old) => old.mono != mono;
}
