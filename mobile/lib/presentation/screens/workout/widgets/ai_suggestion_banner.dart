import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/screens/workout/workout_preference_survey_screen.dart';
import 'package:mobile/presentation/screens/workout/ai_workout_suggestion_screen.dart';

class AiSuggestionBanner extends StatelessWidget {
  const AiSuggestionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Suggestion',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 16, color: const Color(0xFF1E293B)),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (context) => const AiWorkoutSuggestionScreen(),
                  ),
                );
              },
              child: Text(
                'See All',
                style: AppTheme.semiboldStyle.copyWith(fontSize: 13, color: const Color(0xFFFF7A30)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Smart Workout',
                  style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tạo lịch tập luyện\ntrong tuần theo AI',
                style: AppTheme.headlineStyle.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context, rootNavigator: true).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => const WorkoutPreferenceSurveyScreen(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (context) => const AiWorkoutSuggestionScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Tạo ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
