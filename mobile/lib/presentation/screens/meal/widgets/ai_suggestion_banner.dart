import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/screens/meal/allergy_survey_screen.dart';
import 'package:mobile/presentation/screens/meal/ai_meal_suggestion_screen.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';

class AiSuggestionBanner extends StatelessWidget {
  const AiSuggestionBanner({super.key});

  Future<void> _proceedToAiMealScreen(BuildContext context, int days, bool startTomorrow) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).add(Duration(days: startTomorrow ? 1 : 0));
    final endDate = startDate.add(Duration(days: days - 1));

    try {
      final rangeList = await nutritionDiaryRepository.getDailyEatingRange(startDate, endDate);
      final daysWithFood = rangeList.where((day) {
        return day.mealSlots.any((slot) => slot.items.isNotEmpty);
      }).toList();

      if (daysWithFood.isNotEmpty && context.mounted) {
        final dateStr = "${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM').format(endDate)}";
        final bool? shouldProceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Phát hiện thực đơn sẵn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn đang có thực đơn sẵn trong ${daysWithFood.length} ngày (khoảng $dateStr).\n\nNếu tiếp tục, AI sẽ lên thực đơn gợi ý mới cho bạn xem trước. Thực đơn cũ sẽ bị thay thế khi bạn bấm Áp dụng.\n\nBạn có muốn tiếp tục nhờ AI tạo thực đơn không?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Tiếp tục tạo với AI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldProceed != true) return;
      }
    } catch (e) {
      print("🚨 [AiSuggestionBanner] Error checking existing meals: $e");
    }

    if (context.mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => AiMealSuggestionScreen(days: days, startTomorrow: startTomorrow)));
    }
  }

  void _showAiOptionsBottomSheet(BuildContext context) {
    final parentContext = context;
    int selectedDays = 7;
    bool startTomorrow = false;
    bool isCompleted = TokenService.isMealSurveyCompleted();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(modalContext).viewInsets.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tạo Thực Đơn Với AI',
                      style: AppTheme.bodyStyle.copyWith(fontSize: 20, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI sẽ tự động lên thực đơn ăn uống cá nhân hóa tối ưu cho thể trạng của bạn.',
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
                                    'Khảo sát dinh dưỡng',
                                    style: AppTheme.semiboldStyle.copyWith(
                                      fontSize: 14,
                                      color: const Color(0xFF1E293B),
                                    ),
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
                                final result = await Navigator.of(parentContext, rootNavigator: true).push<bool>(
                                  MaterialPageRoute(builder: (context) => const MealPreferenceSurveyScreen()),
                                );
                                if (result == true) {
                                  setModalState(() {
                                    isCompleted = TokenService.isMealSurveyCompleted();
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
                                  border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
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
                    const SizedBox(height: 20),
                    Text(
                      'Thời điểm bắt đầu',
                      style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                startTomorrow = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !startTomorrow ? AppTheme.primary : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: !startTomorrow ? AppTheme.primary : const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'Hôm nay',
                                style: AppTheme.semiboldStyle.copyWith(
                                  fontSize: 14,
                                  color: !startTomorrow ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                startTomorrow = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: startTomorrow ? AppTheme.primary : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: startTomorrow ? AppTheme.primary : const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'Ngày mai',
                                style: AppTheme.semiboldStyle.copyWith(
                                  fontSize: 14,
                                  color: startTomorrow ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(modalContext);
                          if (!isCompleted) {
                            _startSurveyFlow(parentContext, selectedDays, startTomorrow);
                          } else {
                            _proceedToAiMealScreen(parentContext, selectedDays, startTomorrow);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _startSurveyFlow(BuildContext context, int days, bool startTomorrow) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (surveyContext) => MealPreferenceSurveyScreen(
          onCompleted: () {
            Navigator.of(surveyContext).pushReplacement(
              MaterialPageRoute(
                builder: (context) => AiMealSuggestionScreen(
                  days: days,
                  startTomorrow: startTomorrow,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gợi Ý Từ AI', style: AppTheme.semiboldStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark blue/slate color
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/images/fruit.png'), // Add an abstract or dark texture here if available
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('Smart Diet', style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 10)),
              ),
              const SizedBox(height: 16),
              Text(
                'Tạo chế độ ăn uống\ntrong tuần theo AI',
                style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 20, height: 1.3),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
