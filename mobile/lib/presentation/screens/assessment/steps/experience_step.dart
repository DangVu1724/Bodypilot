import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class ExperienceStep extends StatelessWidget {
  final VoidCallback onNext;

  const ExperienceStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;
    final hasExperience = state.hasExperience;

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
            'Kinh nghiệm',
            style: AppTheme.headlineStyle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bạn đã từng tập gym chưa?',
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Thông tin này giúp chúng tôi cá nhân hóa trải nghiệm tập luyện',
          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),

        // 🎯 Ảnh nằm giữa
        Expanded(
          child: Center(child: Image.asset(AssessmentState.experienceImage, height: 280, fit: BoxFit.contain)),
        ),

        const SizedBox(height: 16),

        // Selection Cards
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                context: context,
                title: 'Chưa từng tập',
                icon: Icons.history,
                isSelected: hasExperience == false,
                onTap: () => context.read<AssessmentCubit>().setExperience(false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceCard(
                context: context,
                title: 'Đã từng tập',
                icon: Icons.fitness_center,
                isSelected: hasExperience == true,
                onTap: () => context.read<AssessmentCubit>().setExperience(true),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Fixed Bottom Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              if (hasExperience != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đã chọn: ${hasExperience ? 'Đã từng tập' : 'Chưa từng tập'}',
                    style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: BlackButton2(
                  label: 'Tiếp tục',
                  onPressed: hasExperience != null ? onNext : null,
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

  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.semiboldStyle.copyWith(
                fontSize: 15,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
