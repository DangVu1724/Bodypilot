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
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedGender = assessmentState.selectedGender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Giới tính của bạn là gì?', style: GoogleFonts.workSans(fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Thông tin này giúp chúng tôi cá nhân hóa trải nghiệm tập luyện',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        ...AssessmentState.genderOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGenderOptionWithImage(
              context: context,
              title: option.title,
              description: option.description,
              imagePath: option.imagePath,
              isSelected: selectedGender == option.title,
              onTap: () {
                context.read<AssessmentCubit>().selectGender(option.title);
              },
            ),
          ),
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: BlackButton2(
            label: 'Continue',
            onPressed: selectedGender != null ? widget.onNext : null,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 2)
              : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Row(
            children: [
              // Bên trái: Info + Checkbox
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.primary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phù hợp với ${title.toLowerCase()} giới',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              onTap();
                            },
                            activeColor: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chọn ${title.toLowerCase()}',
                            style: TextStyle(fontSize: 14, color: isSelected ? AppTheme.primary : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bên phải: Ảnh giới tính
              ClipRRect(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                child: Image.asset(
                  imagePath,
                  width: 150,
                  height: 170,
                  fit: BoxFit.cover, // Ảnh phủ kín toàn bộ
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
