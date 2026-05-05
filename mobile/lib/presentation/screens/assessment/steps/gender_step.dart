import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class GenderStep extends StatefulWidget {
  final VoidCallback onNext;

  const GenderStep({super.key, required this.onNext});

  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;
    final selectedGender = state.selectedGender;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // HEADER (simple fade)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: 1,
            child: Column(
              children: [
                Text('Giới tính', style: AppTheme.headlineStyle, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Giới tính của bạn là gì?',
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Thông tin này giúp chúng tôi cá nhân hóa trải nghiệm tập luyện',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // OPTIONS
          ...AssessmentState.genderOptions.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected = selectedGender == option.title;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: 1,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                offset: const Offset(0, 0),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildGenderOptionWithImage(
                    context: context,
                    title: option.title,
                    description: option.description,
                    imagePath: option.imagePath,
                    isSelected: isSelected,
                    onTap: () {
                      context.read<AssessmentCubit>().selectGender(option.title);
                    },
                  ),
                ),
              ),
            );
          }),

          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                if (selectedGender != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Giới tính: $selectedGender',
                      style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.primary),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: BlackButton2(
                    label: 'Tiếp tục',
                    onPressed: selectedGender != null ? widget.onNext : null,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOptionWithImage({
    required BuildContext context,
    required String title,
    required String description,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transformAlignment: Alignment.center,
        transform: isSelected ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppTheme.primary.withOpacity(0.12) : Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              // LEFT CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            title == 'Nam' ? Icons.male : Icons.female,
                            color: isSelected ? AppTheme.primary : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            title,
                            style: AppTheme.semiboldStyle.copyWith(
                              fontSize: 18,
                              color: isSelected ? AppTheme.primary : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(description, style: AppTheme.bodyStyle.copyWith(color: Colors.grey)),
                      const SizedBox(height: 14),

                      // CHECK
                      Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppTheme.primary : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chọn $title',
                            style: AppTheme.bodyStyle.copyWith(color: isSelected ? AppTheme.primary : Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // RIGHT IMAGE
              Image.asset(imagePath, width: 120, height: 160, fit: BoxFit.cover),
            ],
          ),
        ),
      ),
    );
  }
}
