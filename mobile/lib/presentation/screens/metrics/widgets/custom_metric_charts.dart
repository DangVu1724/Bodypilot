import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    const double dashWidth = 5;
    const double dashSpace = 4;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SingleBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double target;
  final String unit;
  final Color barColor;
  final Color barSecondaryColor;

  const SingleBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.target,
    required this.unit,
    required this.barColor,
    required this.barSecondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    double maxVal = target;
    for (final v in values) {
      maxVal = max(maxVal, v);
    }
    maxVal = maxVal * 1.15; // padding top
    if (maxVal <= 0) maxVal = 100.0;

    const double chartHeight = 200.0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight + 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Target Line
              if (target > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: chartHeight * (1 - (target / maxVal)),
                  child: CustomPaint(
                    painter: DashedLinePainter(color: Colors.grey.shade400),
                    child: Container(
                      height: 1,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Mục tiêu: ${target.toStringAsFixed(0)} $unit',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              // Bars
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double parentWidth = constraints.maxWidth;
                    final bool isScrollable = values.length > 7;
                    final double contentWidth = isScrollable ? (values.length * 36.0) : parentWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        width: contentWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(values.length, (index) {
                            final val = values[index];
                            final double barHeight = chartHeight * (val / maxVal);
                            final label = labels[index];

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Tooltip when value > 0
                                if (val > 0)
                                  Text(
                                    val.toStringAsFixed(0),
                                    style: AppTheme.semiboldStyle.copyWith(
                                      fontSize: 9,
                                      color: barColor,
                                    ),
                                  )
                                else
                                  const Text('', style: TextStyle(fontSize: 9)),
                                const SizedBox(height: 4),
                                // Animated Bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutQuad,
                                  width: 16,
                                  height: max(barHeight, 4.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [barColor, barSecondaryColor],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: AppTheme.semiboldStyle.copyWith(
                                    fontSize: 10,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DoubleBarChart extends StatelessWidget {
  final List<double> values1; // e.g. Intake
  final List<double> values2; // e.g. Burned
  final List<String> labels;
  final double target; // Intake Target
  final String unit;

  const DoubleBarChart({
    super.key,
    required this.values1,
    required this.values2,
    required this.labels,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    double maxVal = target;
    for (int i = 0; i < values1.length; i++) {
      maxVal = max(maxVal, max(values1[i], values2[i]));
    }
    maxVal = maxVal * 1.15;
    if (maxVal <= 0) maxVal = 2000.0;

    const double chartHeight = 200.0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight + 45,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Target Line
              if (target > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: chartHeight * (1 - (target / maxVal)),
                  child: CustomPaint(
                    painter: DashedLinePainter(color: Colors.grey.shade300),
                    child: Container(
                      height: 1,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Mục tiêu nạp: ${target.toStringAsFixed(0)} $unit',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              // Double Bars
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double parentWidth = constraints.maxWidth;
                    final bool isScrollable = values1.length > 7;
                    final double contentWidth = isScrollable ? (values1.length * 44.0) : parentWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        width: contentWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(values1.length, (index) {
                            final val1 = values1[index];
                            final val2 = values2[index];
                            final double height1 = chartHeight * (val1 / maxVal);
                            final double height2 = chartHeight * (val2 / maxVal);
                            final label = labels[index];

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Small net balance text
                                Text(
                                  (val1 - val2).toStringAsFixed(0),
                                  style: AppTheme.semiboldStyle.copyWith(
                                    fontSize: 8,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Bar 1 (Intake - Orange/Red)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOutQuad,
                                      width: 10,
                                      height: max(height1, 4.0),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    // Bar 2 (Burned - Pink/Purple)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOutQuad,
                                      width: 10,
                                      height: max(height2, 4.0),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: AppTheme.semiboldStyle.copyWith(
                                    fontSize: 10,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
