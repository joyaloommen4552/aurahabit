import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlowParticle {
  double x;
  double y;
  double speed;
  double radius;
  double opacity;
  final double randomOffset;

  GlowParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.opacity,
    required this.randomOffset,
  });
}

class GlowParticlesPainter extends CustomPainter {
  final List<GlowParticle> particles;
  final double animationValue;

  GlowParticlesPainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      // Calculate animated coordinate positions
      final yOffset =
          math.sin((animationValue * 2 * math.pi) + p.randomOffset) * 15;
      final xOffset =
          math.cos((animationValue * 2 * math.pi) + p.randomOffset) * 10;

      final double finalX = (p.x + xOffset) % size.width;
      // Drift upwards slowly
      final double finalY =
          (p.y - (animationValue * p.speed * 50) + yOffset) % size.height;

      // Pulse opacity
      final double opacityPulse =
          (p.opacity * 0.4) +
          (math.sin((animationValue * 4 * math.pi) + p.randomOffset).abs() *
              p.opacity *
              0.6);

      paint.color = const Color(
        0xFF8A2BE2,
      ).withValues(alpha: opacityPulse); // Purple glow

      // Draw particle blur glow halo
      final glowPaint = Paint()
        ..color = const Color(0xFF8A2BE2).withValues(alpha: opacityPulse * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(finalX, finalY), p.radius * 2.5, glowPaint);

      // Draw core particle
      canvas.drawCircle(Offset(finalX, finalY), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GlowParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
