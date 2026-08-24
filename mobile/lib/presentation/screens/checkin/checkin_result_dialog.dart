import 'package:flutter/material.dart';
import 'package:core_shared/models/check_in_model.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';

class CheckInResultDialog extends StatelessWidget {
  final CheckInResultModel result;

  const CheckInResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isWeightLoss = result.weightChange <= 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isWeightLoss ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isWeightLoss ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isWeightLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                  color: isWeightLoss ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Khảo Sát Hoàn Tất',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chỉ số cơ thể & lộ trình đã được cập nhật chuẩn xác',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Metrics Cards Row (Beautiful 2-Column Card Grid)
              Row(
                children: [
                  // Cân nặng Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.monitor_weight_rounded, color: Color(0xFF6366F1), size: 18),
                              const SizedBox(width: 6),
                              Text('Cân nặng', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${result.newWeight} kg',
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isWeightLoss ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${result.weightChange > 0 ? "+" : ""}${result.weightChange} kg',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isWeightLoss ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // TDEE & Target Calories Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A30), size: 18),
                              const SizedBox(width: 6),
                              Text('TDEE Mới', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${result.newTdee.toInt()} kcal',
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Calo nạp: ${result.newTargetCalories.toInt()} kcal',
                            style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Evaluation Box (NO "Gemini AI")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      const Color(0xFF7C3AED).withValues(alpha: 0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights_rounded, color: Color(0xFFA5B4FC), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Đánh Giá Tổng Quan',
                          style: GoogleFonts.beVietnamPro(
                            color: const Color(0xFFE0E7FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.aiFeedback.isNotEmpty ? result.aiFeedback : result.advice,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons ("Xem Thực Đơn" & "Xem Lịch Tập")
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
                        side: const BorderSide(color: Color(0xFF475569)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Xem Thực Đơn', style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold)),
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
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('Xem Lịch Tập', style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Đóng',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
