import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double progress;
  final double animationValue;

  WavePainter({required this.progress, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF66FCF1).withValues(alpha: 0.6), // Cyan Aqua
          const Color(0xFF45A29E).withValues(alpha: 0.9), // Dark Cyan
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.06; // Height of waves
    final currentWaterLevel = size.height * (1.0 - progress);

    path.moveTo(0, currentWaterLevel);

    for (double i = 0.0; i <= size.width; i++) {
      // Wavy sine wave math
      final relativeX = i / size.width;
      final waveOffset =
          math.sin((animationValue * 2 * math.pi) + (relativeX * 2 * math.pi)) *
          waveHeight;
      path.lineTo(i, currentWaterLevel + waveOffset);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Clip to rounded container bounds (draw circle shape for water glass)
    final clipPath = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.clipPath(clipPath);

    canvas.drawPath(path, paint);

    // Draw secondary, lighter wave for depth
    final secondaryPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF66FCF1).withValues(alpha: 0.3),
          const Color(0xFF45A29E).withValues(alpha: 0.5),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final secondaryPath = Path();
    secondaryPath.moveTo(0, currentWaterLevel);

    for (double i = 0.0; i <= size.width; i++) {
      final relativeX = i / size.width;
      // Offset wave angle for visual difference
      final waveOffset =
          math.cos(
            (animationValue * 2 * math.pi) +
                (relativeX * 2 * math.pi) +
                math.pi / 4,
          ) *
          waveHeight;
      secondaryPath.lineTo(i, currentWaterLevel + waveOffset);
    }

    secondaryPath.lineTo(size.width, size.height);
    secondaryPath.lineTo(0, size.height);
    secondaryPath.close();

    canvas.drawPath(secondaryPath, secondaryPaint);

    // Draw floaty bubble dots inside the water
    final rand = math.Random(42); // fixed seed for stable bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final waterTop = currentWaterLevel;
    if (progress > 0.05) {
      for (int i = 0; i < 15; i++) {
        final x = rand.nextDouble() * size.width;
        // animate bubbles floating upwards dynamically
        final rawY = rand.nextDouble() * (size.height - waterTop) + waterTop;
        final animatedY =
            rawY - ((animationValue * 15) % (size.height - waterTop));

        if (animatedY > waterTop && animatedY < size.height) {
          final radius = rand.nextDouble() * 3 + 1;
          canvas.drawCircle(Offset(x, animatedY), radius, bubblePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue;
  }
}
