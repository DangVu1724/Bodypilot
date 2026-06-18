import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class DislikedFoodOption {
  final String code;
  final String title;
  final IconData icon;

  const DislikedFoodOption({required this.code, required this.title, required this.icon});
}

class DislikedFoodsStep extends StatefulWidget {
  final VoidCallback onNext;

  const DislikedFoodsStep({super.key, required this.onNext});

  @override
  State<DislikedFoodsStep> createState() => _DislikedFoodsStepState();
}

class _DislikedFoodsStepState extends State<DislikedFoodsStep> {
  late final TextEditingController _noteController;

  static const List<DislikedFoodOption> options = [
    DislikedFoodOption(code: 'NONE', title: 'Không có', icon: Icons.sentiment_satisfied),
    DislikedFoodOption(code: 'ORGAN_MEAT', title: 'Nội tạng', icon: Icons.restaurant),
    DislikedFoodOption(code: 'SEAFOOD', title: 'Hải sản', icon: Icons.set_meal),
    DislikedFoodOption(code: 'SPICY_FOOD', title: 'Đồ cay', icon: Icons.whatshot),
    DislikedFoodOption(code: 'FRIED_FOOD', title: 'Đồ chiên rán', icon: Icons.cookie),
    DislikedFoodOption(code: 'FAST_FOOD', title: 'Đồ ăn nhanh', icon: Icons.lunch_dining),
    DislikedFoodOption(code: 'SUGARY_FOOD', title: 'Đồ ngọt', icon: Icons.cake),
    DislikedFoodOption(code: 'PROCESSED_FOOD', title: 'Đồ chế biến sẵn', icon: Icons.inventory_2),
    DislikedFoodOption(code: 'DAIRY_PRODUCTS', title: 'Sữa & Chế phẩm', icon: Icons.local_cafe),
    DislikedFoodOption(code: 'OTHER', title: 'Khác', icon: Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();
    final initialNote = context.read<AssessmentCubit>().state.dislikedFoodsNote;
    _noteController = TextEditingController(text: initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedDisliked = assessmentState.dislikedFoodGroups;

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Hạn chế thực phẩm',
                    style: AppTheme.headlineStyle.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn muốn hạn chế nhóm thực phẩm nào?',
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'AI sẽ điều chỉnh thực đơn giảm thiểu hoặc loại bỏ các nhóm này (Không dùng cho dị ứng nguy hiểm).',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selectedDisliked.contains(option.code);
                    return _buildCategoryOption(
                      title: option.title,
                      icon: option.icon,
                      isSelected: isSelected,
                      code: option.code,
                    );
                  },
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bạn không thích hoặc muốn hạn chế thực phẩm cụ thể nào khác?',
                    style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  onChanged: (value) {
                    context.read<AssessmentCubit>().setDislikedFoodsNote(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: rau ngò, hành tây, cà tím, mướp đắng...',
                    hintStyle: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomSection(selectedDisliked),
      ],
    );
  }

  Widget _buildCategoryOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required String code,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<AssessmentCubit>().toggleDislikedFoodGroup(code);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade200, width: 1.5),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: AppTheme.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))
            else
              BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 10, color: AppTheme.primary),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: isSelected ? Colors.white : AppTheme.primary),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.semiboldStyle.copyWith(
                        fontSize: 12,
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

  Widget _buildBottomSection(List<String> selectedDisliked) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          if (selectedDisliked.isNotEmpty && !selectedDisliked.contains('NONE'))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Đã chọn ${selectedDisliked.length} nhóm hạn chế',
                style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.primary),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: BlackButton2(
              label: 'Tiếp tục',
              onPressed: selectedDisliked.isNotEmpty ? widget.onNext : null,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
