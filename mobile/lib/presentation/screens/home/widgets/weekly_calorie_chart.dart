import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';

class WeeklyCalorieChart extends StatelessWidget {
  const WeeklyCalorieChart({super.key});

  List<DateTime> _getCurrentWeekDates() {
    final now = DateTime.now();
    // Lấy ngày thứ 2 trong tuần
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserCubit>().state;
    final mealState = context.watch<MealCubit>().state;
    final workoutState = context.watch<WorkoutDiaryCubit>().state;

    double targetCalories = 2000.0;
    if (userState is UserLoaded) {
      targetCalories = userState.user.metrics?.targetCalories ?? 2000.0;
    }

    final weekDates = _getCurrentWeekDates();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Thu thập dữ liệu nạp và đốt cho 7 ngày trong tuần
    final List<double> intakeData = [];
    final List<double> burnedData = [];
    double maxVal = targetCalories; // Bắt đầu bằng target để làm mốc

    for (final date in weekDates) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Calo nạp vào
      double intake = 0.0;
      if (mealState.dailyEatings.containsKey(dateStr)) {
        intake = mealState.dailyEatings[dateStr]!.totalCaloriesEaten;
      }
      intakeData.add(intake);

      // Calo tiêu hao
      double burned = 0.0;
      if (workoutState.dailyWorkouts.containsKey(dateStr)) {
        burned = workoutState.dailyWorkouts[dateStr]!.totalCaloriesBurned;
      }
      burnedData.add(burned);

      maxVal = max(maxVal, max(intake, burned));
    }

    // Nhân maxVal lên 1.15 để tạo khoảng cách biên trên biểu đồ
    maxVal = maxVal * 1.15;
    if (maxVal <= 0) maxVal = 2000.0;

    const double chartHeight = 180.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cân bằng Calorie tuần này',
                style: AppTheme.semiboldStyle.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF1E293B),
                ),
              ),
              // Chú thích màu sắc
              Row(
                children: [
                  _buildLegendItem('Nạp vào', const Color(0xFFF97316)),
                  const SizedBox(width: 12),
                  _buildLegendItem('Đốt cháy', const Color(0xFFEC4899)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vùng biểu đồ vẽ cột
          SizedBox(
            height: chartHeight + 30, // Thừa 30px cho nhãn ngày ở dưới
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Đường nét đứt biểu thị Calo mục tiêu (Target Calories)
                Positioned(
                  left: 0,
                  right: 0,
                  top: chartHeight * (1 - (targetCalories / maxVal)),
                  child: CustomPaint(
                    painter: DashedLinePainter(color: Colors.grey.shade300),
                    child: Container(
                      height: 1,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Mục tiêu: ${targetCalories.toStringAsFixed(0)}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Vẽ 7 nhóm cột cho 7 ngày
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final date = weekDates[index];
                      final dateStr = DateFormat('yyyy-MM-dd').format(date);
                      final isToday = dateStr == todayStr;

                      final double intakeHeight = chartHeight * (intakeData[index] / maxVal);
                      final double burnedHeight = chartHeight * (burnedData[index] / maxVal);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Phần vẽ cột Intake & Burned sát nhau
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Cột nạp vào (Intake)
                              _buildBar(
                                height: max(intakeHeight, 4.0), // Chiều cao tối thiểu 4px để hiển thị
                                color: const Color(0xFFF97316),
                                secondaryColor: const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              // Cột tiêu hao (Burned)
                              _buildBar(
                                height: max(burnedHeight, 4.0),
                                color: const Color(0xFFEC4899),
                                secondaryColor: const Color(0xFF8B5CF6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Nhãn ngày (T2 - CN)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isToday ? const Color(0xFF1E293B) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _getDayAbbreviation(date.weekday),
                              style: AppTheme.semiboldStyle.copyWith(
                                fontSize: 11,
                                color: isToday ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBar({
    required double height,
    required Color color,
    required Color secondaryColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      width: 14,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, secondaryColor],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
    );
  }
}

// Painter vẽ đường đứt nét
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const max = 320;
    const dashWidth = 5;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
