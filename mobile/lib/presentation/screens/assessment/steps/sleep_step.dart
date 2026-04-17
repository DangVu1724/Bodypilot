import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class SleepStep extends StatefulWidget {
  final VoidCallback onNext;

  const SleepStep({super.key, required this.onNext});

  @override
  State<SleepStep> createState() => _SleepStepState();
}

class _SleepStepState extends State<SleepStep> {
  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedSleep = assessmentState.selectedSleep;

    return SingleChildScrollView(
      // ✅ Bọc SingleChildScrollView
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Giấc ngủ của bạn',
              style: AppTheme.headlineStyle.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Giấc ngủ của bạn là bao nhiêu giờ mỗi ngày?',
            style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn mức độ giấc ngủ giúp chúng tôi đề xuất kế hoạch phù hợp',
            style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AssessmentState.sleepOptions.map((sleepOption) {
              return _buildOption(context, sleepOption.title, sleepOption.icon, selectedSleep == sleepOption.title);
            }).toList(),
          ),
          const SizedBox(height: 32), // ✅ Thay thế Spacer() bằng SizedBox cố định
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                if (selectedSleep != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Đã chọn: $selectedSleep',
                      style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: BlackButton2(
                    label: 'Tiếp tục',
                    onPressed: selectedSleep != null ? widget.onNext : null,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // ✅ Thêm padding bottom
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        context.read<AssessmentCubit>().setSleepQuality(title);
      },
      child: Container(
        width: MediaQuery.of(context).size.width - 48, // ✅ Fix chiều rộng để tránh overflow ngang
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
        ),
        child: Row(
          // ✅ Đổi từ ListTile sang Row để kiểm soát tốt hơn
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTheme.semiboldStyle.copyWith(color: isSelected ? Colors.white : Colors.black87, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                if (value == true) {
                  context.read<AssessmentCubit>().setSleepQuality(title);
                }
              },
              activeColor: Colors.white,
              checkColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: isSelected
                  ? const BorderSide(color: Colors.white, width: 2)
                  : const BorderSide(color: Colors.grey, width: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
