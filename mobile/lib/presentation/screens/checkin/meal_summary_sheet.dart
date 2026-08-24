import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/routes/app_routes.dart';

class MealSummarySheet extends StatelessWidget {
  final Map<String, dynamic>? summaryData;

  const MealSummarySheet({super.key, this.summaryData});

  @override
  Widget build(BuildContext context) {
    final weight = (summaryData?['weight'] as num?)?.toDouble() ?? 68.5;
    final weightChange = (summaryData?['weightChange'] as num?)?.toDouble() ?? -0.5;
    final avgCalories = (summaryData?['avgCalories'] as num?)?.toInt() ?? 1850;
    final targetCalories = (summaryData?['targetCalories'] as num?)?.toInt() ?? 2000;
    final avgProtein = (summaryData?['avgProtein'] as num?)?.toInt() ?? 112;
    final targetProtein = (summaryData?['targetProtein'] as num?)?.toInt() ?? 125;
    final aiFeedback = summaryData?['aiFeedback'] as String? ?? 
        'Bạn đã tuân thủ chế độ dinh dưỡng rất tốt trong tuần qua! Lượng protein nạp vào duy trì ổn định giúp cơ bắp phục hồi nhanh chóng. Khuyến nghị duy trì mức calo hiện tại cho tuần tiếp theo.';

    final isWeightLoss = weightChange <= 0;
    final caloPercent = (avgCalories / (targetCalories > 0 ? targetCalories : 1) * 100).clamp(0, 100).toInt();
    final proteinPercent = (avgProtein / (targetProtein > 0 ? targetProtein : 1) * 100).clamp(0, 100).toInt();

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
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
            const SizedBox(height: 20),

            // Header Banner
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFD97706), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tổng Kết Dinh Dưỡng Tuần',
                              style: GoogleFonts.beVietnamPro(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Đã Check-in', style: TextStyle(color: Color(0xFF059669), fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chỉ số calo, macronutrients & tiến độ tuần vừa qua',
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weight Progress Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isWeightLoss ? Colors.green : Colors.amber).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWeightLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                      color: isWeightLoss ? Colors.green.shade700 : Colors.amber.shade800,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cân nặng ghi nhận:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        Text('$weight kg', style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isWeightLoss ? Colors.green : Colors.amber).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${weightChange > 0 ? "+" : ""}$weightChange kg',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isWeightLoss ? Colors.green.shade700 : Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nutrients Metric Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Calo nạp TB', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC2410C), fontWeight: FontWeight.w600)),
                            const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('$avgCalories kcal', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF9A3412))),
                        Text('Mục tiêu $targetCalories kcal ($caloPercent%)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFC2410C))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Protein TB', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                            const Icon(Icons.egg_alt_rounded, color: Color(0xFF2563EB), size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${avgProtein}g / ngày', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
                        Text('Mục tiêu ${targetProtein}g ($proteinPercent%)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1D4ED8))),
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4F46E5), // Indigo 600
                    Color(0xFF7C3AED), // Purple 600
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant_menu_rounded, color: Color(0xFFA5B4FC), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Đánh Giá Dinh Dưỡng',
                        style: TextStyle(
                          color: Color(0xFFE0E7FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aiFeedback,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Đóng', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.mealPlan);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Xem Thực Đơn', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
