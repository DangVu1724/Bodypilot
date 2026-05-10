import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/models/workout_plan_model.dart';
import '../workout_plan_detail_screen.dart';
import '../../../bloc/workout/workout_plan_cubit.dart';
import '../../../bloc/workout/workout_plan_state.dart';
import '../../../../core/theme/app_theme.dart';
import 'section_title.dart';

class WorkoutPlansSection extends StatelessWidget {
  const WorkoutPlansSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Workout Plans', actionText: 'See All'),
        const SizedBox(height: 12),
        BlocBuilder<WorkoutPlanCubit, WorkoutPlanState>(
          builder: (context, state) {
            if (state is WorkoutPlanLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is WorkoutPlanLoaded) {
              if (state.plans.isEmpty) {
                return const Center(child: Text('No workout plans available.'));
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.plans.length,
                  itemBuilder: (context, index) {
                    return _PlanCard(plan: state.plans[index]);
                  },
                ),
              );
            } else if (state is WorkoutPlanError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final WorkoutPlanModel plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => WorkoutPlanDetailScreen(plan: plan),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(plan.thumbnailUrl ?? 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plan.difficulty,
                      style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  if (plan.isPremium)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${plan.totalDays} Days',
                        style: AppTheme.bodyStyle.copyWith(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.track_changes, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        plan.goal,
                        style: AppTheme.bodyStyle.copyWith(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
