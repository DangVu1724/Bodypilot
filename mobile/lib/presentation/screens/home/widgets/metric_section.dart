import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/step/step_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData iconData;
  final Color accentColor;
  final Widget? bottomWidget;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.iconData,
    required this.accentColor,
    this.bottomWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Left accent indicator bar
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                width: 4.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Icon badge + Title + Chevron
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconData,
                            color: accentColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTheme.semiboldStyle.copyWith(
                              color: AppTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bottom widget (progress & details)
                    ?bottomWidget,
                    const Spacer(),
                    // Value & Unit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: AppTheme.headlineStyle.copyWith(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          unit,
                          style: AppTheme.bodyStyle.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      final gender = userState.user.profile?.gender;
      if (weight != null && weight > 0) {
        context.read<StepCubit>().updateUserWeight(weight);
      }

      final isFemale = gender?.toUpperCase() == 'FEMALE' || gender == 'Nữ';
      final isMale = gender?.toUpperCase() == 'MALE' || gender == 'Nam';

      final int targetSteps;
      switch (goal) {
        case 'LOSE_1KG':
          targetSteps = isFemale ? 12000 : (isMale ? 15000 : 13500);
          break;
        case 'LOSE_0_5KG':
          targetSteps = isFemale ? 10000 : (isMale ? 12500 : 11000);
          break;
        case 'HEALTHY_LIFESTYLE':
          targetSteps = isFemale ? 8000 : (isMale ? 10000 : 9000);
          break;
        case 'MAINTAIN':
          targetSteps = isFemale ? 7000 : (isMale ? 8000 : 7500);
          break;
        case 'GAIN_MUSCLE':
          targetSteps = isFemale ? 5000 : (isMale ? 6000 : 5500);
          break;
        case 'GAIN_0_5KG':
          targetSteps = isFemale ? 4500 : (isMale ? 5000 : 4500);
          break;
        case 'GAIN_1KG':
          targetSteps = 4000;
          break;
        default:
          targetSteps = isFemale ? 7000 : (isMale ? 8000 : 8000);
      }
      context.read<StepCubit>().setTargetSteps(targetSteps);
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

    const calorieColor = Color(0xFFF97316);
    const proteinColor = Color(0xFF3B82F6);
    const activeColor = Color(0xFF10B981);
    const stepColor = Color(0xFFEC4899);

    return SizedBox(
      height: 175,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Card 1: Calorie Balance
          MetricCard(
            title: 'Cân bằng Calo',
            value: netCalorie.toStringAsFixed(0),
            unit: 'kcal',
            iconData: Icons.local_fire_department_rounded,
            accentColor: calorieColor,
            onTap: () => context.push(AppRoutes.calorieBalanceDetail),
            bottomWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: calorieProgress,
                    backgroundColor: calorieColor.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(calorieColor),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Nạp ${totalCaloriesEaten.toStringAsFixed(0)} | Đốt ${totalCaloriesBurned.toStringAsFixed(0)}',
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Card 2: Protein
          MetricCard(
            title: 'Lượng Protein',
            value: eatenProtein.toStringAsFixed(0),
            unit: 'g',
            iconData: Icons.fitness_center_rounded,
            accentColor: proteinColor,
            onTap: () => context.push(AppRoutes.proteinDetail),
            bottomWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: proteinProgress,
                    backgroundColor: proteinColor.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(proteinColor),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Mục tiêu: ${targetProtein.toStringAsFixed(0)} g',
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Card 3: Active Minutes
          MetricCard(
            title: 'Vận động',
            value: activeMinutes.toStringAsFixed(0),
            unit: 'phút',
            iconData: Icons.timer_outlined,
            accentColor: activeColor,
            onTap: () => context.push(AppRoutes.activeMinutesDetail),
            bottomWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: activeProgress,
                    backgroundColor: activeColor.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(activeColor),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Mục tiêu: 45 phút',
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Card 4: Step Counter
          Builder(
            builder: (context) {
              final stepState = context.watch<StepCubit>().state;
              return MetricCard(
                title: 'Bước chân',
                value: NumberFormat('#,###').format(stepState.steps),
                unit: 'bước',
                iconData: Icons.directions_walk_rounded,
                accentColor: stepColor,
                onTap: () => context.push(AppRoutes.stepDetail),
                bottomWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: stepState.progress,
                        backgroundColor: stepColor.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(stepColor),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Đốt: ${stepState.caloriesBurned.toStringAsFixed(0)} kcal',
                      style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
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
