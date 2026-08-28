import 'dart:math';
import 'package:flutter/material.dart';

class CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  CalorieRingPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    // Vẽ Background Ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Vẽ Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Bắt đầu từ đỉnh trên cùng (12h)
      sweepAngle,
      false,
      progressPaint,
    );

    // Vẽ Knob (Nút tròn nhỏ ở đầu)
    if (progress > 0 && progress < 1) {
      final thumbAngle = -pi / 2 + sweepAngle;
      final thumbCenter = Offset(
        center.dx + radius * cos(thumbAngle),
        center.dy + radius * sin(thumbAngle),
      );

      final thumbPaintBg = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(thumbCenter, strokeWidth / 2, thumbPaintBg);

      final thumbPaintFg = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(thumbCenter, (strokeWidth / 2) - 4, thumbPaintFg);
    }
  }

  @override
  bool shouldRepaint(covariant CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
