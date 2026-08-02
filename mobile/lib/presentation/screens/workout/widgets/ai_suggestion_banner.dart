import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/screens/workout/workout_preference_survey_screen.dart';
import 'package:mobile/presentation/screens/workout/ai_workout_suggestion_screen.dart';
import 'package:mobile/data/services/token_service.dart';

class AiSuggestionBanner extends StatelessWidget {
  const AiSuggestionBanner({super.key});

  void _showAiOptionsBottomSheet(BuildContext context) {
    int selectedDays = 7;
    bool isCompleted = TokenService.isAssessmentCompleted();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tạo Lịch Tập Với AI',
                      style: AppTheme.bodyStyle.copyWith(fontSize: 20, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI sẽ tự động thiết kế lộ trình tập luyện cá nhân hóa tối ưu cho thể trạng của bạn.',
                      style: AppTheme.bodyStyle.copyWith(fontSize: 14, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    if (isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Khảo sát thể trạng',
                                    style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: const Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Đã hoàn thành khảo sát trước đó.',
                                    style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.of(context, rootNavigator: true).push<bool>(
                                  MaterialPageRoute(
                                    builder: (context) => const WorkoutPreferenceSurveyScreen(),
                                  ),
                                );
                                if (result == true) {
                                  setModalState(() {
                                    isCompleted = TokenService.isAssessmentCompleted();
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Khảo sát lại'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Thời gian lập lịch',
                      style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [4, 5, 6, 7].map((days) {
                        final isSelected = selectedDays == days;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedDays = days;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primary : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  '$days Ngày',
                                  style: AppTheme.semiboldStyle.copyWith(
                                    fontSize: 14,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (!isCompleted) {
                            _startSurveyFlow(context, selectedDays);
                          } else {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => AiWorkoutSuggestionScreen(days: selectedDays),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          !isCompleted ? 'Tiến hành khảo sát' : 'Bắt đầu tạo lịch',
                          style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startSurveyFlow(BuildContext context, int days) async {
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (context) => const WorkoutPreferenceSurveyScreen(),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => AiWorkoutSuggestionScreen(days: days),
        ),
      );
    }
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
              'AI Suggestion',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 16, color: const Color(0xFF1E293B)),
            ),
            GestureDetector(
              onTap: () {
                _showAiOptionsBottomSheet(context);
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
                onPressed: () {
                  _showAiOptionsBottomSheet(context);
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
