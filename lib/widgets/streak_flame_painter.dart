import 'dart:math' as math;
import 'package:flutter/material.dart';

class StreakFlamePainter extends CustomPainter {
  final int streak;
  final double animationValue;

  StreakFlamePainter({required this.streak, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (streak == 0) return;

    final center = Offset(size.width / 2, size.height / 2 + 10);
    // Scale flame size based on streak milestones (max scale at streak 10+)
    final streakScale = 0.8 + math.min(streak * 0.05, 0.4);
    final width = size.width * 0.5 * streakScale;
    final height = size.height * 0.7 * streakScale;

    // Draw flame backing shadow glow
    final glowPaint = Paint()
      ..color = const Color(
        0xFFFF5722,
      ).withValues(alpha: 0.2 + (0.05 * math.min(streak, 5)))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(0, -10), width * 0.7, glowPaint);

    final path = Path();
    final topOffset = math.sin(animationValue * 2 * math.pi) * 8;
    final leftOffset = math.cos(animationValue * 2 * math.pi) * 4;

    // Main Flame Path (tear/fire shape)
    path.moveTo(center.dx, center.dy - height - topOffset); // Peak
    path.cubicTo(
      center.dx + width * 0.6 + leftOffset,
      center.dy - height * 0.6,
      center.dx + width * 0.8,
      center.dy - height * 0.1,
      center.dx,
      center.dy,
    ); // Right side
    path.cubicTo(
      center.dx - width * 0.8,
      center.dy - height * 0.1,
      center.dx - width * 0.6 - leftOffset,
      center.dy - height * 0.6,
      center.dx,
      center.dy - height - topOffset,
    ); // Left side
    path.close();

    final mainPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              const Color(0xFFFF9800), // Orange
              const Color(0xFFFF3D00), // Deep Red-Orange
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(
              center.dx - width,
              center.dy - height,
              width * 2,
              height,
            ),
          )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, mainPaint);

    // Inner glowing core of the flame (yellow)
    final coreWidth = width * 0.55;
    final coreHeight = height * 0.6;
    final corePath = Path();

    corePath.moveTo(center.dx, center.dy - coreHeight - (topOffset * 0.8));
    corePath.cubicTo(
      center.dx + coreWidth * 0.6,
      center.dy - coreHeight * 0.5,
      center.dx + coreWidth * 0.8,
      center.dy - coreHeight * 0.1,
      center.dx,
      center.dy,
    );
    corePath.cubicTo(
      center.dx - coreWidth * 0.8,
      center.dy - coreHeight * 0.1,
      center.dx - coreWidth * 0.6,
      center.dy - coreHeight * 0.5,
      center.dx,
      center.dy - coreHeight - (topOffset * 0.8),
    );
    corePath.close();

    final corePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              const Color(0xFFFFEB3B), // Yellow
              const Color(0xFFFF9800), // Orange
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(
              center.dx - coreWidth,
              center.dy - coreHeight,
              coreWidth * 2,
              coreHeight,
            ),
          )
      ..style = PaintingStyle.fill;

    canvas.drawPath(corePath, corePaint);
  }

  @override
  bool shouldRepaint(covariant StreakFlamePainter oldDelegate) {
    return oldDelegate.streak != streak ||
        oldDelegate.animationValue != animationValue;
  }
}
