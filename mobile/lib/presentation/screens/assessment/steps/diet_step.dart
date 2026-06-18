import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';
import 'package:core_shared/models/diet_tag_model.dart';

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
    final selectedDietTagId = assessmentState.selectedDietTagId;
    final dietTags = assessmentState.availableDietTags;

    final displayDietTags = [
      if (dietTags.isNotEmpty)
        DietTagModel(
          id: 'none',
          name: 'Ăn uống bình thường',
          description: 'Không theo chế độ ăn kiêng đặc biệt nào',
        ),
      ...dietTags,
    ];

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
                'Chế độ ăn',
                style: AppTheme.headlineStyle.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chế độ ăn ưa thích của bạn?',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn một chế độ ăn đặc biệt nếu có. Chọn Ăn uống bình thường nếu ăn uống bình thường.',
              style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Expanded(
          child: dietTags.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: displayDietTags.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tag = displayDietTags[index];
                    final isSelected = selectedDietTagId == tag.id;
                    return GestureDetector(
                      onTap: () {
                        context.read<AssessmentCubit>().selectDietTag(tag.id);
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
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 28,
                                color: isSelected ? Colors.white : AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tag.name,
                                    style: AppTheme.semiboldStyle.copyWith(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (tag.description != null && tag.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tag.description!,
                                      style: AppTheme.bodyStyle.copyWith(
                                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
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
              if (selectedDietTagId != null && selectedDietTagId != 'none' && dietTags.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đã chọn: ${dietTags.firstWhere((t) => t.id == selectedDietTagId, orElse: () => dietTags.first).name}',
                    style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.primary),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: BlackButton2(
                  label: 'Tiếp tục',
                  onPressed: selectedDietTagId != null ? widget.onNext : null,
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
