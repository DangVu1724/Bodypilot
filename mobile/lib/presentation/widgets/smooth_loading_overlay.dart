import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/screens/workout/widgets/workout_skeleton.dart';

class SmoothLoadingOverlay extends StatefulWidget {
  final String title;
  const SmoothLoadingOverlay({super.key, this.title = 'Đang tải dữ liệu...'});

  @override
  State<SmoothLoadingOverlay> createState() => _SmoothLoadingOverlayState();
}

class _SmoothLoadingOverlayState extends State<SmoothLoadingOverlay> {
  late String _randomTip;

  static const List<String> _fitnessTips = [
    '💡 Mẹo: Uống 500ml nước trước khi tập 30 phút để nạp đủ năng lượng cho cơ bắp.',
    '💡 Mẹo: Nạp protein & carb phức hợp sau buổi tập giúp tối ưu phục hồi cơ bắp.',
    '💡 Mẹo: Giữ hít thở đều đặn trong các rep nặng để bảo vệ cột sống & duy trì áp suất.',
    '💡 Mẹo: Ngủ đủ 7-8 tiếng mỗi đêm là thời điểm vàng để cơ bắp tổng hợp và phát triển.',
    '💡 Mẹo: Khởi động kỹ 5-10 phút giúp làm nóng khớp & ngăn ngừa chấn thương.',
    '💡 Mẹo: Đa dạng thực đơn hàng tuần giúp cơ thể cân bằng đủ vi chất dinh dưỡng.',
  ];

  @override
  void initState() {
    super.initState();
    final random = Random();
    _randomTip = _fitnessTips[random.nextInt(_fitnessTips.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tip Banner Box
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withOpacity(0.12),
                const Color(0xFF6366F1).withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _randomTip,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Shimmer List
        const ExerciseVerticalSkeleton(),
      ],
    );
  }
}
