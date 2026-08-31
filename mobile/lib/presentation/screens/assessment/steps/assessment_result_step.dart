import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class AssessmentResultStep extends StatelessWidget {
  final VoidCallback onComplete;

  const AssessmentResultStep({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;

    final double weight = (state.selectedWeight).toDouble();
    final double height = (state.selectedHeight).toDouble();
    final int age = state.selectedAge;
    final isMale = state.selectedGender?.toUpperCase() == 'MALE' || state.selectedGender == 'Nam';
    final goalCode = state.selectedGoal ?? 'MAINTAIN';
    final activityCode = state.selectedActivityLevel ?? 'MODERATE';

    // 1. BMI Calculation
    final double heightM = height / 100.0;
    final double bmi = (heightM > 0) ? (weight / (heightM * heightM)) : 0.0;

    // 2. BMI Classification (WHO WPRO Asian Standard)
    String bmiCategory;
    String bmiDescription;
    Color bmiColor;
    IconData bmiIcon;

    if (bmi < 18.5) {
      bmiCategory = 'Thiếu cân';
      bmiDescription = 'Thể trạng của bạn đang ở mức thiếu cân. Cần chú ý bổ sung dinh dưỡng và nâng cao calo nạp vào.';
      bmiColor = const Color(0xFF3B82F6); // Blue
      bmiIcon = Icons.sentiment_dissatisfied_rounded;
    } else if (bmi < 23.0) {
      bmiCategory = 'Thể trạng lý tưởng';
      bmiDescription = 'Chúc mừng! Bạn có chỉ số cơ thể rất cân đối và khỏe mạnh.';
      bmiColor = const Color(0xFF10B981); // Emerald Green
      bmiIcon = Icons.sentiment_very_satisfied_rounded;
    } else if (bmi < 25.0) {
      bmiCategory = 'Thừa cân (Tiền béo phì)';
      bmiDescription = 'Bạn đang ở mức thừa cân nhẹ. Nên kết hợp ăn uống lành mạnh và duy trì thói quen vận động.';
      bmiColor = const Color(0xFFF59E0B); // Amber
      bmiIcon = Icons.sentiment_neutral_rounded;
    } else if (bmi < 30.0) {
      bmiCategory = 'Béo phì độ I';
      bmiDescription = 'Chỉ số béo phì độ I. Bạn nên áp dụng thực đơn thâm hụt calo và duy trì luyện tập đều đặn.';
      bmiColor = const Color(0xFFF97316); // Orange
      bmiIcon = Icons.warning_amber_rounded;
    } else {
      bmiCategory = 'Béo phì độ II';
      bmiDescription = 'Chỉ số béo phì độ II. Cần theo dõi sức khỏe cẩn thận và áp dụng phác đồ giảm cân bài bản.';
      bmiColor = const Color(0xFFEF4444); // Red
      bmiIcon = Icons.error_outline_rounded;
    }

    // 3. BMR Calculation (Mifflin-St Jeor)
    final double bmrBase = 10 * weight + 6.25 * height - 5 * age;
    final double bmr = isMale ? (bmrBase + 5) : (bmrBase - 161);

    // 4. PAL (Physical Activity Level)
    double pal = 1.55;
    String activityTitle;
    switch (activityCode.toUpperCase()) {
      case 'SEDENTARY':
        pal = 1.2;
        activityTitle = 'Ít vận động (Ngồi nhiều)';
        break;
      case 'LIGHT':
        pal = 1.375;
        activityTitle = 'Nhẹ nhàng (1 - 3 buổi/tuần)';
        break;
      case 'MODERATE':
        pal = 1.55;
        activityTitle = 'Vừa phải (3 - 5 buổi/tuần)';
        break;
      case 'ACTIVE':
        pal = 1.725;
        activityTitle = 'Nhiều (6 - 7 buổi/tuần)';
        break;
      case 'VERY_ACTIVE':
        pal = 1.9;
        activityTitle = 'Rất nhiều (Cường độ cao)';
        break;
      default:
        activityTitle = 'Vừa phải (3 - 5 buổi/tuần)';
    }

    // 5. TDEE Calculation
    final double tdee = bmr * pal;

    // 6. Target Calories Calculation
    double targetCalories = tdee;
    switch (goalCode.toUpperCase()) {
      case 'LOSE_1KG':
        targetCalories = tdee - 1000;
        break;
      case 'LOSE_0_5KG':
        targetCalories = tdee - 500;
        break;
      case 'MAINTAIN':
      case 'HEALTHY_LIFESTYLE':
        targetCalories = tdee;
        break;
      case 'GAIN_0_5KG':
        targetCalories = tdee + 500;
        break;
      case 'GAIN_1KG':
        targetCalories = tdee + 1000;
        break;
      case 'GAIN_MUSCLE':
        targetCalories = tdee + 300;
        break;
    }

    // 7. Goal Title Translation
    String goalTitle;
    switch (goalCode.toUpperCase()) {
      case 'LOSE_1KG':
        goalTitle = 'Giảm 1.0 kg / tuần';
        break;
      case 'LOSE_0_5KG':
        goalTitle = 'Giảm 0.5 kg / tuần';
        break;
      case 'MAINTAIN':
        goalTitle = 'Duy trì vóc dáng';
        break;
      case 'GAIN_0_5KG':
        goalTitle = 'Tăng 0.5 kg / tuần';
        break;
      case 'GAIN_1KG':
        goalTitle = 'Tăng 1.0 kg / tuần';
        break;
      case 'GAIN_MUSCLE':
        goalTitle = 'Tăng cơ nạc (Lean Bulk)';
        break;
      case 'HEALTHY_LIFESTYLE':
        goalTitle = 'Sống khỏe mạnh';
        break;
      default:
        goalTitle = 'Duy trì vóc dáng';
    }

    final numberFormat = NumberFormat('#,###');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Celebration Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  'Phân Tích Thể Trạng Hoàn Tất',
                  style: GoogleFonts.beVietnamPro(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hệ thống AI đã tự động tính toán các chỉ số sức khỏe dựa trên khảo sát của bạn.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: const Color(0xFF94A3B8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Evaluation Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bmiColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bmiColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(bmiIcon, color: bmiColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Đánh giá BMI:',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: bmiColor, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              bmiCategory,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bmiDescription,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Các Chỉ Số Sinh Học Cốt Lõi',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // 2x2 Grid of Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Chỉ số BMI',
                  value: bmi.toStringAsFixed(1),
                  unit: 'kg/m²',
                  subtitle: bmiCategory,
                  icon: Icons.speed_rounded,
                  accentColor: bmiColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'BMR (Cơ bản)',
                  value: numberFormat.format(bmr.round()),
                  unit: 'kcal/ngày',
                  subtitle: 'Trao đổi chất nghỉ',
                  icon: Icons.local_fire_department_rounded,
                  accentColor: const Color(0xFFF07025),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'TDEE (Tổng tiêu hao)',
                  value: numberFormat.format(tdee.round()),
                  unit: 'kcal/ngày',
                  subtitle: 'Đốt cháy trung bình',
                  icon: Icons.flash_on_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Calo Mục Tiêu',
                  value: numberFormat.format(targetCalories.round()),
                  unit: 'kcal/ngày',
                  subtitle: 'Cần nạp mỗi ngày',
                  icon: Icons.track_changes_rounded,
                  accentColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Info Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flag_rounded, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Lộ Trình & Thể Trạng Đã Đăng Ký',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildInfoRow('Mục tiêu thể hình:', goalTitle, isHighlight: true),
                const SizedBox(height: 10),
                _buildInfoRow('Giới tính:', isMale ? 'Nam' : 'Nữ'),
                const SizedBox(height: 10),
                _buildInfoRow('Độ tuổi:', '$age tuổi'),
                const SizedBox(height: 10),
                _buildInfoRow('Chiều cao:', '${height.toInt()} cm'),
                const SizedBox(height: 10),
                _buildInfoRow('Cân nặng hiện tại:', '${weight.toStringAsFixed(1).replaceAll('.0', '')} kg'),
                if (state.targetWeight > 0) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow('Cân nặng mục tiêu:', '${state.targetWeight} kg'),
                ],
                const SizedBox(height: 10),
                _buildInfoRow('Mức độ vận động:', activityTitle),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Complete Button
          SizedBox(
            width: double.infinity,
            child: BlackButton2(
              label: 'Hoàn thành khảo sát',
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
              onPressed: onComplete,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.beVietnamPro(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? AppTheme.primary : const Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

