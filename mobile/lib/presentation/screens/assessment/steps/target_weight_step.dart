import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class TargetWeightStep extends StatelessWidget {
  final VoidCallback onNext;

  const TargetWeightStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Mục tiêu cân nặng',
            style: AppTheme.headlineStyle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Cân nặng mục tiêu mà bạn muốn đạt được là bao nhiêu?',
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn cân nặng mục tiêu để chúng tôi cân chỉnh chế độ tập luyện phù hợp',
          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Center(
          child: Column(
            children: [
              Text(
                '${state.targetWeight} kg',
                style: AppTheme.headlineStyle.copyWith(fontSize: 40, color: AppTheme.primary),
              ),
              const SizedBox(height: 10),
              Text(
                'Cân nặng hiện tại ${state.selectedWeight} kg',
                style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: state.targetWeight.toDouble(),
          min: 40,
          max: 120,
          divisions: 80,
          activeColor: AppTheme.primary,
          inactiveColor: Colors.grey.shade300,
          label: '${state.targetWeight} kg',
          onChanged: (value) {
            context.read<AssessmentCubit>().setTargetWeight(value.round());
          },
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mục tiêu: ${state.targetWeight} kg',
                  style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: BlackButton2(
                  label: 'Tiếp tục',
                  onPressed: onNext,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
