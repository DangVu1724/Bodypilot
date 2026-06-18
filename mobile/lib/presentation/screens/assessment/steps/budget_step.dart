import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class BudgetOption {
  final String value;
  final String title;
  final String description;
  final IconData icon;

  const BudgetOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class BudgetStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onSubmit;

  const BudgetStep({super.key, required this.onNext, this.onSubmit});

  @override
  State<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends State<BudgetStep> {
  static const List<BudgetOption> options = [
    BudgetOption(
      value: 'LOW',
      title: 'Tiết kiệm (Low)',
      description: 'Ưu tiên các thực phẩm cơ bản, giàu dinh dưỡng với chi phí tối ưu.',
      icon: Icons.savings_outlined,
    ),
    BudgetOption(
      value: 'MEDIUM',
      title: 'Trung bình (Medium)',
      description: 'Chi tiêu hợp lý, cân bằng giữa chi phí và sự đa dạng nguyên liệu.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    BudgetOption(
      value: 'HIGH',
      title: 'Thoải mái (High)',
      description: 'Không giới hạn ngân sách, ưu tiên thực phẩm cao cấp, hữu cơ.',
      icon: Icons.workspace_premium_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedBudget = assessmentState.selectedBudget;
    final isLoading = assessmentState.status == AssessmentStatus.loading;

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
                'Ngân sách ẩm thực',
                style: AppTheme.headlineStyle.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ngân sách cho thực đơn hàng ngày?',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn ngân sách để AI gợi ý các bữa ăn phù hợp với túi tiền của bạn.',
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
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedBudget == option.value;
              return GestureDetector(
                onTap: () {
                  context.read<AssessmentCubit>().selectBudget(option.value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
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
                          option.icon,
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
                              option.title,
                              style: AppTheme.semiboldStyle.copyWith(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.description,
                              style: AppTheme.bodyStyle.copyWith(
                                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                fontSize: 13,
                              ),
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
              if (selectedBudget != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đã chọn: ${options.firstWhere((o) => o.value == selectedBudget).title}',
                    style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.primary),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: BlackButton2(
                  label: isLoading ? 'Đang lưu...' : 'Hoàn tất',
                  onPressed: selectedBudget != null && !isLoading
                      ? () {
                          if (widget.onSubmit != null) {
                            widget.onSubmit!();
                          } else {
                            context.read<AssessmentCubit>().submitAssessment();
                          }
                        }
                      : null,
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
