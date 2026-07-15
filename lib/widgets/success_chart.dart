import 'package:flutter/material.dart';
import '../models/habit_data.dart';

class SuccessChart extends StatelessWidget {
  final List<DailyLogModel> logs;

  const SuccessChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2833).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(logs: logs),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<DailyLogModel> logs;

  _ChartPainter({required this.logs});

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) {
      _drawNoData(canvas, size);
      return;
    }

    final double paddingLeft = 30;
    final double paddingRight = 10;
    final double paddingTop = 15;
    final double paddingBottom = 20;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // Draw background grid lines (horizontal representing 0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 2; i++) {
      final double y = paddingTop + (chartHeight * (i / 2));
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final label = i == 0 ? "100%" : (i == 1 ? "50%" : "0%");
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 9,
          fontWeight: FontWeight.w400,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Process data coordinates
    final int totalPoints = logs.length;
    final double xInterval = totalPoints > 1
        ? chartWidth / (totalPoints - 1)
        : chartWidth;

    final List<Offset> points = [];

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];

      // Calculate composite score (out of 5 points)
      int score = 0;
      if (log.waterMl >= 2000) score++;
      if (log.isShaved) score++;
      if (log.isHairCared) score++;
      if (log.isFaceCared) score++;
      if (log.exerciseSeconds + log.readingSeconds >= 3600) score++;

      final double scorePct = score / 5.0; // 0.0 to 1.0

      final double x = paddingLeft + (i * xInterval);
      final double y = paddingTop + (chartHeight * (1.0 - scorePct));
      points.add(Offset(x, y));

      // Draw day label below the chart
      final dateParts = log.date.split('-');
      final shortDate = dateParts.length > 2
          ? "${dateParts[1]}/${dateParts[2]}"
          : log.date;

      textPainter.text = TextSpan(
        text: shortDate,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - paddingBottom + 5),
      );
    }

    if (points.isEmpty) return;

    // Draw area fill under the line path
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height - paddingBottom);
    for (var point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height - paddingBottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              const Color(0xFF00FA9A).withValues(alpha: 0.2), // Neon green glow
              const Color(0xFF00FA9A).withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight),
          )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw the chart connection line
    final linePaint = Paint()
      ..color = const Color(0xFF00FA9A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Draw standard line
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw indicator glowing coordinate circles
    final pointPaint = Paint()
      ..color = const Color(0xFF00FA9A)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFF00FA9A).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 5, shadowPaint);
      canvas.drawCircle(point, 3.5, pointPaint);
    }
  }

  void _drawNoData(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: "No success logs tracked yet.",
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.logs != logs;
  }
}
