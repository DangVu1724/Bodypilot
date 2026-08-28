import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Widget hiển thị màn hình chờ AI tạo lịch tập với các bước tiến trình (Stepper)
class WorkoutAiLoadingWidget extends StatelessWidget {
  final int currentStepIndex;
  final List<Map<String, String>> steps;

  const WorkoutAiLoadingWidget({
    super.key,
    required this.currentStepIndex,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), shape: BoxShape.circle),
              child: const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Đang Thiết Lập Lịch Tập AI',
              style: GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hệ thống AI đang tính toán và tối ưu hóa các bài tập tốt nhất cho mục tiêu của bạn',
              style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF64748B), fontSize: 13.5, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: List.generate(steps.length, (index) {
                  final step = steps[index];
                  final isDone = index < currentStepIndex;
                  final isCurrent = index == currentStepIndex;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24)
                                : isCurrent
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
                                      )
                                    : const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['title']!,
                                style: AppTheme.semiboldStyle.copyWith(
                                  fontSize: 15,
                                  color: isCurrent
                                      ? AppTheme.primary
                                      : (isDone ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step['desc']!,
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 12.5,
                                  color: isCurrent
                                      ? const Color(0xFF475569)
                                      : (isDone ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
