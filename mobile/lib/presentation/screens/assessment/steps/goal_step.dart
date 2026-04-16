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
        Text(
          'Mục tiêu tập luyện của bạn là gì?',
          style: GoogleFonts.workSans(fontSize: 36, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AssessmentState.goalOptions.map((goalOption) {
            return _buildOption(context, goalOption.title, goalOption.icon, selectedGoal == goalOption.title);
          }).toList(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: BlackButton2(
            label: 'Continue',
            onPressed: selectedGoal != null ? widget.onNext : null,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
            style: GoogleFonts.workSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
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
