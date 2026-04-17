import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class AllergyCategoryStep extends StatelessWidget {
  final VoidCallback onNext;

  const AllergyCategoryStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;
    final selectedCategory = state.selectedAllergyCategory;

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
            'Dị ứng thức ăn',
            style: AppTheme.headlineStyle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bạn bị dị ứng với nhóm thực phẩm nào?',
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn nhóm để xem các thực phẩm cụ thể bạn cần tránh',
          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AssessmentState.allergyCategories.map((category) {
                  final isSelected = selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      context.read<AssessmentCubit>().selectAllergyCategory(category);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
                      ),
                      child: Text(
                        category,
                        style: AppTheme.semiboldStyle.copyWith(
                          fontSize: 16,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: BlackButton2(
            label: 'Tiếp tục',
            onPressed: selectedCategory != null ? onNext : null,
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
