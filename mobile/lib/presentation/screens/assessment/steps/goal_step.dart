import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class GoalStep extends StatefulWidget {
  final VoidCallback onNext;

  const GoalStep({super.key, required this.onNext});

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedGoal = assessmentState.selectedGoal;

    return Column(
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
            'Mục tiêu',
            style: AppTheme.headlineStyle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mục tiêu tập luyện của bạn là gì?',
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn mục tiêu giúp chúng tôi đề xuất kế hoạch phù hợp',
          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AssessmentState.goalOptions.map((goalOption) {
            return _buildOption(context, goalOption.title, goalOption.icon, selectedGoal == goalOption.title);
          }).toList(),
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
              if (selectedGoal != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Mục tiêu: $selectedGoal',
                    style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: BlackButton2(
                  label: 'Tiếp tục',
                  onPressed: selectedGoal != null ? widget.onNext : null,
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

  Widget _buildOption(BuildContext context, String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        context.read<AssessmentCubit>().selectGoal(title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
        ),
        child: ListTile(
          title: Text(
            title,
            style: AppTheme.semiboldStyle.copyWith(color: isSelected ? Colors.white : Colors.black87, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(icon, size: 40, color: isSelected ? Colors.white : AppTheme.primary),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) {
              if (value == true) {
                context.read<AssessmentCubit>().selectGoal(title);
              }
            },
            activeColor: Colors.white,
            checkColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: isSelected
                ? const BorderSide(color: Colors.white, width: 2)
                : const BorderSide(color: Colors.grey, width: 1.5),
          ),
        ),
      ),
    );
  }
}
