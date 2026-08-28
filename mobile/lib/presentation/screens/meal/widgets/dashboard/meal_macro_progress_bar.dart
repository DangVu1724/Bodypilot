import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget thanh tiến trình hiển thị chỉ số dinh dưỡng (Calo, Protein, Carbs, Fat)
class MealMacroProgressBar extends StatelessWidget {
  final double currentCalories;
  final double targetCalories;
  final double currentProtein;
  final double targetProtein;
  final double currentCarbs;
  final double targetCarbs;
  final double currentFat;
  final double targetFat;

  const MealMacroProgressBar({
    super.key,
    required this.currentCalories,
    required this.targetCalories,
    required this.currentProtein,
    required this.targetProtein,
    required this.currentCarbs,
    required this.targetCarbs,
    required this.currentFat,
    required this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    final calProgress = (targetCalories > 0) ? (currentCalories / targetCalories).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng Calo Trong Ngày',
                style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              Text(
                '${currentCalories.toStringAsFixed(0)} / ${targetCalories.toStringAsFixed(0)} kcal',
                style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: calProgress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7A30)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMacroItem('Chất đạm', currentProtein, targetProtein, Colors.blue)),
              Expanded(child: _buildMacroItem('Tinh bột', currentCarbs, targetCarbs, Colors.amber)),
              Expanded(child: _buildMacroItem('Chất béo', currentFat, targetFat, Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, double current, double target, Color color) {
    final progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
