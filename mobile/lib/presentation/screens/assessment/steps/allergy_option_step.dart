import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class AllergyOptionStep extends StatefulWidget {
  final VoidCallback onNext;

  const AllergyOptionStep({super.key, required this.onNext});

  @override
  State<AllergyOptionStep> createState() => _AllergyOptionStepState();
}

class _AllergyOptionStepState extends State<AllergyOptionStep> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;
    final selectedCategory = state.selectedAllergyCategory ?? AssessmentState.allergyCategories.first;
    final selectedAllergies = state.selectedAllergies;
    final options = AssessmentState.allergyOptions.where((option) => option.category == selectedCategory).toList();

    return Column(
      children: [
        const SizedBox(height: 20),

        // Header
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Dị ứng thực phẩm',
            style: AppTheme.headlineStyle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Chọn các thực phẩm bạn bị dị ứng',
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Chuyển nhóm thực phẩm để chọn nhanh hơn',
          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Category chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: AssessmentState.allergyCategories.map((category) {
              final isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    context.read<AssessmentCubit>().selectAllergyCategory(category);
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: AppTheme.primary,
                  labelStyle: AppTheme.semiboldStyle.copyWith(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: StadiumBorder(side: BorderSide(color: isSelected ? AppTheme.primary : Colors.transparent)),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Options grid
        Expanded(
          child: selectedCategory == 'Không có'
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.check_circle_outline, size: 60, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 24),
                      Text('Bạn không có dị ứng thực phẩm', style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        'Tuyệt vời! Chúng tôi sẽ gợi ý đa dạng món ăn',
                        style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _animationController,
                  child: GridView.builder(
                    itemCount: options.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = selectedAllergies.contains(option.name);
                      return _buildAllergyCard(
                        name: option.name,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.read<AssessmentCubit>().toggleAllergy(option.name);
                        },
                      );
                    },
                  ),
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
              if (selectedCategory == 'Không có' || selectedAllergies.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedCategory == 'Không có' ? 'Đã chọn: Không dị ứng' : 'Đã chọn: ${selectedAllergies.join(', ')}',
                    style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildAllergyCard({required String name, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: isSelected ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
