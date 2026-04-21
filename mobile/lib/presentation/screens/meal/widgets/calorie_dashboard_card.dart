import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'calorie_ring_painter.dart';

class CalorieDashboardCard extends StatelessWidget {
  CalorieDashboardCard({super.key});

  final Map<String, Map<String, dynamic>> _goalMacros = {
    'MAINTAIN': {'p': 0.25, 'f': 0.25, 'c': 0.50, 'note': 'Tỉ lệ cân bằng nhất để giữ trạng thái ổn định.'},
    'LOSE_0_5KG': {'p': 0.35, 'f': 0.25, 'c': 0.40, 'note': 'Tăng Protein để bảo vệ cơ bắp khi thâm hụt calo nhẹ.'},
    'LOSE_1KG': {'p': 0.40, 'f': 0.20, 'c': 0.40, 'note': 'Protein rất cao để chống mất cơ và tạo cảm giác no lâu.'},
    'GAIN_0_5KG': {'p': 0.25, 'f': 0.20, 'c': 0.55, 'note': 'Cần nhiều Carb để cung cấp năng lượng cho việc tăng cân.'},
    'GAIN_1KG': {'p': 0.20, 'f': 0.25, 'c': 0.55, 'note': 'Cho phép tăng Fat và Carb cao để dễ dàng đạt mức dư thừa calo.'},
    'GAIN_MUSCLE': {'p': 0.40, 'f': 0.20, 'c': 0.40, 'note': 'Ưu tiên tối đa cho việc xây dựng mô cơ (Lean Bulk).'},
    'HEALTHY_LIFESTYLE': {'p': 0.25, 'f': 0.30, 'c': 0.45, 'note': 'Tăng chất béo tốt, Carb phức hợp để duy trì năng lượng bền bỉ.'},
  };

  final Color darkBrown = const Color(0xFF3F2B1A);
  final Color greenAccent = const Color(0xFF7CB342);
  final Color proteinColor = const Color(0xFF2196F3);
  final Color carbsColor = const Color(0xFFFFA726);
  final Color fatColor = const Color(0xFFFF5722);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        double targetCalories = 0.0;
        double eatenCalories = 0.0; // Hiện tại không mock data
        String goal = 'MAINTAIN';

        if (state is UserLoaded) {
          targetCalories = state.user.metrics?.targetCalories ?? 0.0;
          goal = state.user.metrics?.goal ?? 'MAINTAIN';
        }

        double remainingCalories = targetCalories - eatenCalories;
        if (remainingCalories < 0) remainingCalories = 0;

        double progress = targetCalories > 0 ? (remainingCalories / targetCalories) : 1.0;

        final macros = _goalMacros[goal] ?? _goalMacros['MAINTAIN']!;
        final note = macros['note'] as String;

        final double targetProtein = (targetCalories * macros['p']) / 4;
        final double targetFat = (targetCalories * macros['f']) / 9;
        final double targetCarbs = (targetCalories * macros['c']) / 4;

        final double eatenProtein = 0.0;
        final double eatenFat = 0.0;
        final double eatenCarbs = 0.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calories Today',
                style: AppTheme.headlineStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Goal', style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade500, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '${targetCalories.toStringAsFixed(1)} calories',
                          style: AppTheme.semiboldStyle.copyWith(color: darkBrown, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 35, color: Colors.grey.shade200),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eaten', style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade500, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            '${eatenCalories.toStringAsFixed(1)} calories',
                            style: AppTheme.semiboldStyle.copyWith(color: darkBrown, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: CalorieRingPainter(
                            progress: progress,
                            progressColor: greenAccent,
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop_outlined, color: greenAccent, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            remainingCalories.toStringAsFixed(1),
                            style: AppTheme.headlineStyle.copyWith(
                              fontSize: 38,
                              color: darkBrown,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'kcal left',
                            style: AppTheme.bodyStyle.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMacroItem('Protein', eatenProtein, targetProtein, proteinColor),
                  Container(width: 1, height: 45, color: Colors.grey.shade200),
                  _buildMacroItem('Carbs', eatenCarbs, targetCarbs, carbsColor),
                  Container(width: 1, height: 45, color: Colors.grey.shade200),
                  _buildMacroItem('Fat', eatenFat, targetFat, fatColor),
                ],
              ),
              
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Strategy Note', style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: darkBrown)),
                        const SizedBox(height: 4),
                        Text(
                          note,
                          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacroItem(String label, double eaten, double target, Color color) {
    double remaining = target - eaten;
    if (remaining < 0) remaining = 0;
    double progress = target > 0 ? (remaining / target) : 1.0;
    
    return Column(
      children: [
        SizedBox(
          width: 45,
          height: 45,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: Colors.grey.shade100,
            color: color,
            strokeCap: StrokeCap.round,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: AppTheme.semiboldStyle.copyWith(
            fontSize: 14, 
            color: darkBrown, 
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${eaten.toStringAsFixed(1)}/${target.toStringAsFixed(1)}g',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 12, 
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
