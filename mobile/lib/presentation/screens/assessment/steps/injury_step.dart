import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class InjuryStep extends StatefulWidget {
  final VoidCallback onNext;

  const InjuryStep({super.key, required this.onNext});

  @override
  State<InjuryStep> createState() => _InjuryStepState();
}

class _InjuryStepState extends State<InjuryStep> {
  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedInjuries = assessmentState.selectedInjuries;

    // Group injuries by body part
    final Map<String, List<dynamic>> groupedInjuries = {};
    if (assessmentState.availableInjuries.isNotEmpty) {
      for (var injury in assessmentState.availableInjuries) {
        final bodyPart = injury.bodyPart ?? 'OTHER';
        if (!groupedInjuries.containsKey(bodyPart)) {
          groupedInjuries[bodyPart] = [];
        }
        groupedInjuries[bodyPart]!.add(injury);
      }
    }

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
                'Chấn thương & Đau nhức',
                style: AppTheme.headlineStyle.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn có đang gặp chấn thương nào không?',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'AI sẽ điều chỉnh bài tập để tránh làm nặng thêm chấn thương',
              style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: assessmentState.availableInjuries.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: groupedInjuries.keys.length,
                  itemBuilder: (context, index) {
                    final bodyPart = groupedInjuries.keys.elementAt(index);
                    final injuries = groupedInjuries[bodyPart]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatBodyPart(bodyPart),
                                style: GoogleFonts.workSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: injuries.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, innerIndex) {
                            final injury = injuries[innerIndex];
                            final isSelected = selectedInjuries.contains(injury.code);
                            return _buildInjuryOption(
                              title: injury.name,
                              icon: AssessmentState.getInjuryIcon(injury.code),
                              isSelected: isSelected,
                              code: injury.code,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
        ),
        _buildBottomSection(selectedInjuries),
      ],
    );
  }

  String _formatBodyPart(String bodyPart) {
    switch (bodyPart) {
      case 'KNEE':
        return 'ĐẦU GỐI';
      case 'BACK':
        return 'LƯNG';
      case 'SHOULDER':
        return 'VAI';
      case 'ARM':
        return 'TAY';
      case 'LEG':
        return 'CHÂN';
      case 'FULL_BODY':
        return 'TOÀN THÂN';
      default:
        return bodyPart;
    }
  }

  Widget _buildInjuryOption({required String title, required IconData icon, required bool isSelected, required String code}) {
    return GestureDetector(
      onTap: () => context.read<AssessmentCubit>().toggleInjury(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 12, color: AppTheme.primary),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(List<String> selectedInjuries) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedInjuries.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Đã chọn ${selectedInjuries.length} chấn thương',
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
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
    );
  }
}
