import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AiMealLoadingView extends StatelessWidget {
  final int loadingStepIndex;
  final List<Map<String, String>> mealSteps;

  const AiMealLoadingView({
    super.key,
    required this.loadingStepIndex,
    required this.mealSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF07025).withOpacity(0.05), shape: BoxShape.circle),
              child: const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07025)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Đang Thiết Lập Thực Đơn AI',
              style: GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chờ trong giây lát. Hệ thống đang rà soát dữ liệu thể trạng và phân bổ năng lượng tối ưu.',
              style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF64748B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: List.generate(mealSteps.length, (index) {
                  final step = mealSteps[index];
                  final isDone = index < loadingStepIndex;
                  final isCurrent = index == loadingStepIndex;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index == mealSteps.length - 1 ? 0 : 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDone)
                          const Icon(Icons.check_circle, color: Colors.green, size: 22)
                        else if (isCurrent)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07025)),
                            ),
                          )
                        else
                          const Icon(Icons.radio_button_unchecked, color: Color(0xFF94A3B8), size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['title']!,
                                style: AppTheme.semiboldStyle.copyWith(
                                  fontSize: 15,
                                  color: isCurrent
                                      ? const Color(0xFFF07025)
                                      : (isDone ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                                ),
                              ),
                              const SizedBox(height: 4),
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
