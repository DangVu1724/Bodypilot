import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/presentation/bloc/step/step_cubit.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Widget icon;
  final List<Color> gradientColors;
  final Widget? bottomWidget;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.gradientColors,
    this.bottomWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.semiboldStyle.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                icon,
              ],
            ),
            const Spacer(),
            ?bottomWidget,
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTheme.headlineStyle.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MetricSection extends StatefulWidget {
  const MetricSection({super.key});

  @override
  State<MetricSection> createState() => _MetricSectionState();
}

class _MetricSectionState extends State<MetricSection> {
  late String _todayStr;

  final Map<String, Map<String, double>> _goalMacros = const {
    'MAINTAIN': {'p': 0.25, 'f': 0.25, 'c': 0.50},
    'LOSE_0_5KG': {'p': 0.35, 'f': 0.25, 'c': 0.40},
    'LOSE_1KG': {'p': 0.40, 'f': 0.20, 'c': 0.40},
    'GAIN_0_5KG': {'p': 0.25, 'f': 0.20, 'c': 0.55},
    'GAIN_1KG': {'p': 0.20, 'f': 0.25, 'c': 0.55},
    'GAIN_MUSCLE': {'p': 0.40, 'f': 0.20, 'c': 0.40},
    'HEALTHY_LIFESTYLE': {'p': 0.25, 'f': 0.30, 'c': 0.45},
  };

  @override
  void initState() {
    super.initState();
    _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserCubit>().state;
    final mealState = context.watch<MealCubit>().state;
    final workoutState = context.watch<WorkoutDiaryCubit>().state;

    // 1. Calorie Balance
    double totalCaloriesEaten = 0.0;
    double targetCalories = 2000.0;
    String goal = 'MAINTAIN';

    if (mealState.dailyEatings.containsKey(_todayStr)) {
      totalCaloriesEaten = mealState.dailyEatings[_todayStr]!.totalCaloriesEaten;
    }
    if (userState is UserLoaded) {
      targetCalories = userState.user.metrics?.targetCalories ?? 2000.0;
      goal = userState.user.metrics?.goal ?? 'MAINTAIN';
      final weight = userState.user.metrics?.weight;
      if (weight != null && weight > 0) {
        context.read<StepCubit>().updateUserWeight(weight);
      }
    }

    double totalCaloriesBurned = 0.0;
    if (workoutState.dailyWorkouts.containsKey(_todayStr)) {
      totalCaloriesBurned = workoutState.dailyWorkouts[_todayStr]!.totalCaloriesBurned;
    }

    final double netCalorie = totalCaloriesEaten - totalCaloriesBurned;
    final calorieProgress = (targetCalories > 0) ? (totalCaloriesEaten / targetCalories).clamp(0.0, 1.0) : 0.0;

    // 2. Protein
    double eatenProtein = 0.0;
    if (mealState.dailyEatings.containsKey(_todayStr)) {
      for (final slot in mealState.dailyEatings[_todayStr]!.mealSlots) {
        for (final item in slot.items) {
          if (item.isEaten) {
            eatenProtein += item.proteinSnapshot;
          }
        }
      }
    }
    final macros = _goalMacros[goal] ?? _goalMacros['MAINTAIN']!;
    final double targetProtein = (targetCalories * macros['p']!) / 4;
    final proteinProgress = (targetProtein > 0) ? (eatenProtein / targetProtein).clamp(0.0, 1.0) : 0.0;

    // 3. Active Minutes
    double activeMinutes = 0.0;
    if (workoutState.dailyWorkouts.containsKey(_todayStr)) {
      for (final item in workoutState.dailyWorkouts[_todayStr]!.workoutItems) {
        if (item.isCompleted) {
          activeMinutes += item.durationMinutesSnapshot ?? 3;
        }
      }
    }
    const double targetActiveMinutes = 45.0;
    final activeProgress = (activeMinutes / targetActiveMinutes).clamp(0.0, 1.0);

    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Card 1: Calorie Balance
          MetricCard(
            title: 'Cân bằng Calo',
            value: netCalorie.toStringAsFixed(0),
            unit: 'kcal',
            icon: const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
            gradientColors: const [Color(0xFFF97316), Color(0xFFEF4444)],
            onTap: () => context.push(AppRoutes.calorieBalanceDetail),
            bottomWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: calorieProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nạp: ${totalCaloriesEaten.toStringAsFixed(0)} | Đốt: ${totalCaloriesBurned.toStringAsFixed(0)}',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Card 2: Protein
          MetricCard(
            title: 'Lượng Protein',
            value: eatenProtein.toStringAsFixed(0),
            unit: 'g',
            icon: const Icon(Icons.fitness_center_outlined, color: Colors.white, size: 20),
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            onTap: () => context.push(AppRoutes.proteinDetail),
            bottomWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: proteinProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mục tiêu: ${targetProtein.toStringAsFixed(0)} g',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          const SizedBox(width: 16),

          // Card 3: Active Minutes
          MetricCard(
            title: 'Vận động',
            value: activeMinutes.toStringAsFixed(0),
            unit: 'phút',
            icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            onTap: () => context.push(AppRoutes.activeMinutesDetail),
            bottomWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: activeProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mục tiêu: 45 phút',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Card 4: Step Counter
          Builder(
            builder: (context) {
              final stepState = context.watch<StepCubit>().state;
              return MetricCard(
                title: 'Bước chân',
                value: NumberFormat('#,###').format(stepState.steps),
                unit: 'bước',
                icon: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 20),
                gradientColors: const [Color(0xFFEC4899), Color(0xFFD946EF)],
                bottomWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: stepState.progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đốt: ${stepState.caloriesBurned.toStringAsFixed(0)} kcal',
                      style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
