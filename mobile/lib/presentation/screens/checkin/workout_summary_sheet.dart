import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/routes/app_routes.dart';

class WorkoutSummarySheet extends StatelessWidget {
  final Map<String, dynamic>? summaryData;

  const WorkoutSummarySheet({super.key, this.summaryData});

  @override
  Widget build(BuildContext context) {
    final weight = (summaryData?['weight'] as num?)?.toDouble() ?? 68.5;
    final weightChange = (summaryData?['weightChange'] as num?)?.toDouble() ?? -0.5;
    final activeMinutes = (summaryData?['activeMinutes'] as num?)?.toInt() ?? 0;
    final targetActiveMinutes = (summaryData?['targetActiveMinutes'] as num?)?.toInt() ?? 150;
    final stepCount = (summaryData?['stepCount'] as num?)?.toInt() ?? 0;
    final caloriesBurned = (summaryData?['caloriesBurned'] as num?)?.toInt() ?? 0;
    final formattedSteps = NumberFormat('#,###').format(stepCount);
    final recoveryStatus = summaryData?['recoveryStatus'] as String? ?? 'Phục hồi tốt ⚡';
    final aiFeedback = summaryData?['aiFeedback'] as String? ?? 
        'Phong độ tập luyện tuần qua của bạn rất xuất sắc! Duy trì nhịp độ vận động hợp lý để phát triển thể lực và giữ vững sức khỏe.';

    final isWeightLoss = weightChange <= 0;
    final activePercent = (activeMinutes / (targetActiveMinutes > 0 ? targetActiveMinutes : 1) * 100).clamp(0, 100).toInt();

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
                    color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF2563EB), size: 28),
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
                              'Tổng Kết Luyện Tập Tuần',
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
                        'Thời gian vận động, số bước chân & thể lực',
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weight & Recovery Summary Card
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
                        Text('Cân nặng hiện tại:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        Text('$weight kg', style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isWeightLoss ? Colors.green : Colors.amber).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${weightChange > 0 ? "+" : ""}$weightChange kg',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isWeightLoss ? Colors.green.shade700 : Colors.amber.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(recoveryStatus, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Workout Stats Cards (Active mins, Step count, Calo burned)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Vận động', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF047857), fontWeight: FontWeight.w600)),
                            const Icon(Icons.timer_rounded, color: Color(0xFF059669), size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('$activeMinutes phút', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        Text('Mục tiêu $targetActiveMinutes p ($activePercent%)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF047857))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFBCFE8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bước chân', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBE185D), fontWeight: FontWeight.w600)),
                            const Icon(Icons.directions_walk_rounded, color: Color(0xFFDB2777), size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(formattedSteps, style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF831843))),
                        Text('Đốt cháy ~$caloriesBurned kcal', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBE185D))),
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
                    Color(0xFF2563EB), // Blue 600
                    Color(0xFF4F46E5), // Indigo 600
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
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
                      Icon(Icons.fitness_center_rounded, color: Color(0xFF93C5FD), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Đánh Giá Luyện Tập',
                        style: TextStyle(
                          color: Color(0xFFDBEAFE),
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
                      context.push(AppRoutes.workoutDiary);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Xem Lịch Tập', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14)),
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
