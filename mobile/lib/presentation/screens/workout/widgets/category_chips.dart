import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../bloc/workout/workout_category_cubit.dart';
import '../../../bloc/workout/workout_category_state.dart';
import '../category_exercises_screen.dart';
import 'workout_skeleton.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutCategoryCubit, WorkoutCategoryState>(
      builder: (context, state) {
        if (state is WorkoutCategoryLoading) {
          return const CategoryChipSkeleton();
        }

        if (state is WorkoutCategoryLoaded) {
          final categories = state.categories;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => CategoryExercisesScreen(category: cat),
                        ),
                      );
                    },
                    child: Chip(
                      avatar: Icon(_getIconForCategory(cat.code), size: 16, color: Colors.grey[700]),
                      label: Text(cat.name, style: AppTheme.semiboldStyle),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  IconData _getIconForCategory(String code) {
    switch (code.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'yoga':
        return Icons.self_improvement;
      case 'endurance':
        return Icons.favorite;
      default:
        return Icons.fitness_center;
    }
  }
}
