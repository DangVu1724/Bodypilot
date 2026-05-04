import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'widgets/home_header.dart';
import 'widgets/metric_section.dart';
import 'widgets/workout_section.dart';
import 'widgets/food_sections.dart';
import 'widgets/section_header.dart';

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
        child: CustomScrollView(
          slivers: [
            const HomeHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader.buildDateSelector(),
                    const SizedBox(height: 32),
                    SectionHeader(title: 'Fitness Metrics', onSeeAll: () {}),
                    const SizedBox(height: 16),
                    const MetricSection(),
                    const SizedBox(height: 32),
                    SectionHeader(title: 'Workouts', onSeeAll: () {}),
                    const SizedBox(height: 16),
                    const WorkoutSection(),
                    const SizedBox(height: 32),
                    SectionHeader(
                      title: 'Tra cứu món ăn',
                      onSeeAll: () => Navigator.of(context, rootNavigator: true)
                          .pushNamed(AppRoutes.foodList, arguments: 'DISH'),
                    ),
                    const SizedBox(height: 16),
                    const DishSection(),
                    const SizedBox(height: 32),
                    SectionHeader(
                      title: 'Nguyên liệu',
                      onSeeAll: () => Navigator.of(context, rootNavigator: true)
                          .pushNamed(AppRoutes.foodList, arguments: 'INGREDIENT'),
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
    );
  }
}
