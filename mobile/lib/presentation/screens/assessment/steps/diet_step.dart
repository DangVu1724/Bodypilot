import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class DietStep extends StatefulWidget {
  final VoidCallback onNext;

  const DietStep({super.key, required this.onNext});

  @override
  State<DietStep> createState() => _DietStepState();
}

class _DietStepState extends State<DietStep> {
  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedDiet = assessmentState.selectedDiet;

    return Column(
      children: [
        const SizedBox(height: 20),

        Text(
          'Bạn có chế độ ăn uống?',
          style: GoogleFonts.workSans(fontSize: 30, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Chúng tôi sẽ gợi ý dinh dưỡng phù hợp',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 30),

        // 🔥 GRID 2x2
        Expanded(
          child: GridView.builder(
            itemCount: AssessmentState.dietOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cột
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final diet = AssessmentState.dietOptions[index];
              return _buildOption(title: diet.title, icon: diet.icon, examples: diet.examples, isSelected: selectedDiet == diet.title);
            },
          ),
        ),

        // 🔘 Button
        SizedBox(
          width: double.infinity,
          child: BlackButton2(
            label: 'Continue',
            onPressed: widget.onNext,
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({required String title, required IconData icon, required List<String> examples, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        context.read<AssessmentCubit>().selectDiet(title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              examples.join(', '),
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
