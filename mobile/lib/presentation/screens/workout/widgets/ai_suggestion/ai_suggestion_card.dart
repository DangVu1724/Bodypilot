import 'dart:math';

import 'package:core_shared/models/exercise_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/bloc/workout/exercise_cubit.dart';
import 'package:mobile/presentation/bloc/workout/exercise_state.dart';
import 'package:mobile/presentation/screens/workout/widgets/sections/section_title.dart';

class AiSuggestionCard extends StatefulWidget {
  const AiSuggestionCard({super.key});

  @override
  State<AiSuggestionCard> createState() => _AiSuggestionCardState();
}

class _AiSuggestionCardState extends State<AiSuggestionCard> {
  ExerciseModel? _selectedExercise;

  // Chọn ngẫu nhiên 1 Bài tập từ CSDL thật (ExerciseCubit) dựa trên Goal của User
  ExerciseModel? _pickExerciseForGoal(List<ExerciseModel> exercises, String? rawGoal) {
    if (exercises.isEmpty) return null;

    if (_selectedExercise != null && exercises.contains(_selectedExercise)) {
      return _selectedExercise;
    }

    List<ExerciseModel> filtered = [];
    if (rawGoal != null && rawGoal.isNotEmpty) {
      final g = rawGoal.toUpperCase();
      if (g.contains('LOSE') ||
          g.contains('CUT') ||
          g.contains('FAT') ||
          g.contains('GIAM') ||
          g.contains('WEIGHT_LOSS')) {
        // Giảm cân -> Ưu tiên các bài Cardio / HIIT / Đốt Calo cao (metValue >= 6.0)
        filtered = exercises
            .where((e) => (e.metValue ?? 5.0) >= 6.0 || (e.category?.name.toUpperCase().contains('CARDIO') ?? false))
            .toList();
      } else if (g.contains('GAIN') || g.contains('BUILD') || g.contains('MUSCLE') || g.contains('TANG')) {
        // Tăng cơ -> Ưu tiên bài Tạ Sức mạnh (Chest, Back, Legs, Dumbbell, Barbell)
        filtered = exercises
            .where(
              (e) =>
                  (e.category?.name.toUpperCase().contains('STRENGTH') ?? true) ||
                  (e.bodyPart?.name.isNotEmpty ?? false),
            )
            .toList();
      } else if (g.contains('MAINTAIN') || g.contains('YOGA') || g.contains('HEALTH') || g.contains('DUY_TRI')) {
        // Duy trì -> Ưu tiên bài Yoga / Stretching / Core
        filtered = exercises
            .where(
              (e) =>
                  (e.category?.name.toUpperCase().contains('YOGA') ?? false) ||
                  (e.category?.name.toUpperCase().contains('STRETCH') ?? false) ||
                  (e.metValue ?? 5.0) <= 6.0,
            )
            .toList();
      }
    }

    if (filtered.isEmpty) {
      filtered = exercises;
    }

    final random = Random();
    _selectedExercise = filtered[random.nextInt(filtered.length)];
    return _selectedExercise;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        String? goalStr;
        if (userState is UserLoaded) {
          goalStr = userState.user.goal?.type ?? userState.user.metrics?.goal;
        }

        return BlocBuilder<ExerciseCubit, ExerciseState>(
          builder: (context, exerciseState) {
            if (exerciseState is! ExerciseLoaded || exerciseState.exercises.isEmpty) {
              return const SizedBox.shrink(); // Đang tải CSDL bài tập
            }

            final exercise = _pickExerciseForGoal(exerciseState.exercises, goalStr);
            if (exercise == null) return const SizedBox.shrink();

            // Tính toán calo ước tính dựa trên metValue của bài tập thật
            final double met = exercise.metValue ?? 6.0;
            final int durationMin = exercise.defaultDuration ?? 30;
            final int caloriesBurned = ((met * 3.5 * 70 / 200) * durationMin).round();

            final String tag = exercise.category?.name ?? 'Fitness';
            final String bodyPartName = exercise.bodyPart?.name ?? 'Toàn thân';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Đề xuất bài tập'),
                const SizedBox(height: 12),
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    image: DecorationImage(
                      image: NetworkImage(exercise.displayImageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.45), BlendMode.darken),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tag, style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.thumb_up_alt_rounded, color: Colors.amberAccent, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Đề xuất cho bạn',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 20, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tác động: $bodyPartName • Độ khó: ${exercise.difficulty ?? 'Vừa phải'}',
                            style: AppTheme.bodyStyle.copyWith(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$durationMin min',
                                style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.local_fire_department, color: Colors.amberAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$caloriesBurned kcal',
                                style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
