import 'package:flutter/material.dart';

class AquaLogo extends StatelessWidget {
  final double size;

  const AquaLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AquaLogoPainter()),
    );
  }
}

class _AquaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 100;

    final RRect background = RRect.fromRectAndRadius(
      Rect.fromLTWH(8 * s, 8 * s, 84 * s, 84 * s),
      Radius.circular(26 * s),
    );

    final Paint shadowPaint = Paint()
      ..color = const Color(0xFF0099E5).withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * s);
    canvas.drawRRect(background.shift(Offset(0, 8 * s)), shadowPaint);

    final Paint backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0284C7),
          Color(0xFF0099E5),
          Color(0xFF00B4D8),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(background.outerRect);
    canvas.drawRRect(background, backgroundPaint);

    final Path droplet = Path()
      ..moveTo(50 * s, 24 * s)
      ..cubicTo(50 * s, 24 * s, 33 * s, 46 * s, 33 * s, 58 * s)
      ..cubicTo(33 * s, 67.39 * s, 40.61 * s, 75 * s, 50 * s, 75 * s)
      ..cubicTo(59.39 * s, 75 * s, 67 * s, 67.39 * s, 67 * s, 58 * s)
      ..cubicTo(67 * s, 46 * s, 50 * s, 24 * s, 50 * s, 24 * s)
      ..close();
    canvas.drawPath(droplet, Paint()..color = Colors.white);

    final Path highlight = Path()
      ..moveTo(43.5 * s, 58 * s)
      ..cubicTo(41 * s, 62 * s, 43 * s, 67 * s, 47 * s, 69 * s);
    final Paint highlightPaint = Paint()
      ..color = const Color(0xFF0099E5).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlight, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}