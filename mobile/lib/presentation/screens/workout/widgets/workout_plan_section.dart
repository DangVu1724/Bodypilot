import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_state.dart';

class WorkoutPlanSection extends StatefulWidget {
  const WorkoutPlanSection({super.key});

  @override
  State<WorkoutPlanSection> createState() => _WorkoutPlanSectionState();
}

class _WorkoutPlanSectionState extends State<WorkoutPlanSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutDiaryCubit>().fetchDailyWorkout(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Schedule',
              style: AppTheme.headlineStyle.copyWith(fontSize: 20, color: const Color(0xFF1E293B)),
            ),
            TextButton(
              onPressed: () {
                context.push(AppRoutes.workoutDiary);
              },
              child: Text(
                'See All',
                style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<WorkoutDiaryCubit, WorkoutDiaryState>(
          builder: (context, state) {
            final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final dailyWorkout = state.dailyWorkouts[todayStr];

            if (dailyWorkout == null || dailyWorkout.workoutItems.isEmpty) {
              return _buildEmptyWorkoutCard();
            }

            final totalItems = dailyWorkout.workoutItems.length;
            final completedItems = dailyWorkout.workoutItems.where((i) => i.isCompleted).length;
            final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
            final plannedCal = dailyWorkout.totalCaloriesPlanned;
            final burnedCal = dailyWorkout.totalCaloriesBurned;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dailyWorkout.isAiGenerated ? 'AI Generated Schedule' : 'My Workout Plan',
                            style: AppTheme.semiboldStyle.copyWith(fontSize: 16, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Today • $completedItems/$totalItems exercises done',
                            style: AppTheme.bodyStyle.copyWith(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fitness_center, color: AppTheme.primary, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Planned Cal', '${plannedCal.toStringAsFixed(0)} kcal', Colors.blue),
                      _buildMetricItem('Burned Cal', '${burnedCal.toStringAsFixed(0)} kcal', Colors.green),
                      _buildMetricItem('Progress', '${(progress * 100).toStringAsFixed(0)}%', Colors.orange),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyWorkoutCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.fitness_center, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No exercises scheduled for today.',
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.push(AppRoutes.workoutDiary);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Plan Workouts',
              style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 35,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.bodyStyle.copyWith(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: const Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }
}
