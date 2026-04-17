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

        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Chế độ ăn',
            style: AppTheme.headlineStyle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bạn có chế độ ăn uống?',
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Chúng tôi sẽ gợi ý dinh dưỡng phù hợp',
          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
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
              return _buildOption(
                title: diet.title,
                icon: diet.icon,
                examples: diet.examples,
                isSelected: selectedDiet == diet.title,
              );
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              if (selectedDiet != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Chế độ ăn: $selectedDiet',
                    style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: BlackButton2(
                  label: 'Tiếp tục',
                  onPressed: widget.onNext,
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

  Widget _buildOption({
    required String title,
    required IconData icon,
    required List<String> examples,
    required bool isSelected,
  }) {
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
            style: AppTheme.semiboldStyle.copyWith(color: isSelected ? Colors.white : Colors.black87, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
            Text(
              examples.join(', '),
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
