import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class FocusBodyPartStep extends StatefulWidget {
  final VoidCallback onNext;

  const FocusBodyPartStep({super.key, required this.onNext});

  @override
  State<FocusBodyPartStep> createState() => _FocusBodyPartStepState();
}

class _FocusBodyPartStepState extends State<FocusBodyPartStep> {
  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedFocus = assessmentState.selectedFocusBodyPart;
    final options = AssessmentState.focusBodyPartOptions;

    return Column(
      children: [
        const SizedBox(height: 20),
        Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Nhu cầu tập luyện',
                style: AppTheme.headlineStyle.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn muốn ưu tiên tập trung nhóm cơ nào nhất?',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'AI sẽ tối ưu các bài tập chuyên sâu hơn cho bộ phận này',
              style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final option = options[index];
              return _buildOption(context, option, selectedFocus == option.value);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.transparent,
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
                  'Đã chọn: ${options.firstWhere((o) => o.value == selectedFocus, orElse: () => options.first).title}',
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.primary),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<AssessmentCubit, AssessmentState>(
                  builder: (context, state) {
                    final isLoading = state.status == AssessmentStatus.loading;
                    return BlackButton2(
                      label: isLoading ? 'Đang lưu...' : 'Hoàn tất',
                      onPressed: isLoading ? null : () => context.read<AssessmentCubit>().submitAssessment(),
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, FocusBodyPartOption option, bool isSelected) {
    return GestureDetector(
      onTap: () {
        context.read<AssessmentCubit>().selectFocusBodyPart(option.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, size: 28, color: isSelected ? Colors.white : AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTheme.semiboldStyle.copyWith(color: isSelected ? Colors.white : Colors.black87, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: AppTheme.bodyStyle.copyWith(color: isSelected ? Colors.white70 : Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
