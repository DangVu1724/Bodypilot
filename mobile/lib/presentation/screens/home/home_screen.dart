import 'package:flutter/material.dart';
import 'widgets/home_header.dart';
import 'widgets/metric_section.dart';
import 'widgets/workout_section.dart';
import 'widgets/diet_section.dart';
import 'widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const HomeHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Fitness Metrics', onSeeAll: () {}),
                  const SizedBox(height: 16),
                  const MetricSection(),
                  const SizedBox(height: 32),
                  SectionHeader(title: 'Workouts', onSeeAll: () {}),
                  const SizedBox(height: 16),
                  const WorkoutSection(),
                  const SizedBox(height: 32),
                  SectionHeader(title: 'Diet & Nutrition', onSeeAll: () {}),
                  const SizedBox(height: 16),
                  const DietSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
