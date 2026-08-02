import 'package:flutter/material.dart';
import 'package:core_shared/models/check_in_model.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routes/app_routes.dart';

class CheckInResultDialog extends StatelessWidget {
  final CheckInResultModel result;

  const CheckInResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isWeightLoss = result.weightChange <= 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFF1E293B), // Slate Dark
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isWeightLoss ? Colors.green : Colors.amber).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWeightLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                  color: isWeightLoss ? Colors.greenAccent : Colors.amberAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Khảo Sát Hoàn Tất! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chỉ số cơ thể & kế hoạch đã được AI cập nhật thành công.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              // Metrics Summary Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('Cân nặng', '${result.newWeight} kg', '${result.weightChange > 0 ? "+" : ""}${result.weightChange} kg'),
                    Container(height: 36, width: 1, color: Colors.white.withOpacity(0.15)),
                    _buildMetricCol('TDEE Mới', '${result.newTdee.toInt()} kcal', 'Calo tiêu thụ/ngày'),
                    Container(height: 36, width: 1, color: Colors.white.withOpacity(0.15)),
                    _buildMetricCol('Calo Mục Tiêu', '${result.newTargetCalories.toInt()} kcal', 'Khuyến nghị AI'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // AI Feedback Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.2), // Indigo
                      const Color(0xFFA855F7).withOpacity(0.2), // Purple
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology_rounded, color: Color(0xFFA5B4FC), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Đánh Giá Từ Gemini AI',
                          style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.aiFeedback,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.mealPlan);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Thực đơn AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.workoutDiary);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Lịch tập AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Đóng',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, String sub) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9),
        ),
      ],
    );
  }
}
