import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/workout/workout_plan_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/checkin/checkin_cubit.dart';
import 'widgets/home_header.dart';
import 'widgets/home_calendar_section.dart';
import 'widgets/checkin_card.dart';
import 'widgets/ai_coach_card.dart';

import 'widgets/metric_section.dart';
import 'widgets/food_sections.dart';
import 'widgets/section_header.dart';
import 'package:mobile/presentation/screens/workout/widgets/workout_plans_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA0AEC0), // Slate Grey
              Color(0xFFD6CCC2), // Warm Beige
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            final now = DateTime.now();
            final monday = now.subtract(Duration(days: now.weekday - 1));
            final sunday = monday.add(const Duration(days: 6));
            await Future.wait([
              context.read<UserCubit>().fetchUserProfile(),
              context.read<CheckInCubit>().fetchCheckInStatus(),
              context.read<WorkoutPlanCubit>().fetchPlansFull(forceRefresh: true),
              context.read<WorkoutDiaryCubit>().fetchWeeklyWorkouts(monday, sunday),
              context.read<MealCubit>().fetchWeeklyEating(monday, sunday),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              const HomeHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeCalendarSection(),
                      const SizedBox(height: 32),

                      SectionHeader(title: 'Chỉ Số Thể Hình', onSeeAll: () {}),
                      const SizedBox(height: 16),
                      const MetricSection(),
                      const SizedBox(height: 24),
                      const CheckInCard(),
                      const AiCoachCard(),
                      const WorkoutPlansSection(),
                      const SizedBox(height: 32),
                      SectionHeader(
                        title: 'Tra cứu món ăn',
                        onSeeAll: () => context.push(AppRoutes.foodList, extra: 'DISH'),
                      ),
                      const SizedBox(height: 16),
                      const DishSection(),
                      const SizedBox(height: 32),
                      SectionHeader(
                        title: 'Nguyên liệu',
                        onSeeAll: () => context.push(AppRoutes.foodList, extra: 'INGREDIENT'),
                      ),
                      const SizedBox(height: 16),
                      const IngredientSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
