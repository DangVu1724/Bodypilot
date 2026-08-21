import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class DislikedCategoryGroup {
  final String code;
  final String title;
  final IconData icon;
  final List<String> subItems;

  const DislikedCategoryGroup({
    required this.code,
    required this.title,
    required this.icon,
    required this.subItems,
  });
}

class DislikedFoodsStep extends StatefulWidget {
  final VoidCallback onNext;

  const DislikedFoodsStep({super.key, required this.onNext});

  @override
  State<DislikedFoodsStep> createState() => _DislikedFoodsStepState();
}

class _DislikedFoodsStepState extends State<DislikedFoodsStep> {
  late final TextEditingController _noteController;
  final Set<String> _selectedSubItems = {};
  String? _expandedCategoryCode;

  static const List<DislikedCategoryGroup> categoryGroups = [
    DislikedCategoryGroup(
      code: 'MEAT',
      title: 'Thịt & Gia cầm',
      icon: Icons.restaurant,
      subItems: ['Thịt gà', 'Thịt bò', 'Thịt heo', 'Thịt vịt', 'Thịt dê', 'Nội tạng'],
    ),
    DislikedCategoryGroup(
      code: 'GRAIN',
      title: 'Ngũ cốc & Tinh bột',
      icon: Icons.rice_bowl,
      subItems: ['Gạo lứt', 'Yến mạch', 'Khoai lang', 'Quinoa', 'Bánh mì nguyên cám'],
    ),
    DislikedCategoryGroup(
      code: 'DAIRY_PRODUCTS',
      title: 'Sữa & Trứng',
      icon: Icons.local_cafe,
      subItems: ['Sữa chua', 'Phô mai', 'Lòng đỏ trứng', 'Váng sữa'],
    ),
    DislikedCategoryGroup(
      code: 'SEAFOOD',
      title: 'Hải sản',
      icon: Icons.set_meal,
      subItems: ['Tôm', 'Cua', 'Cá biển', 'Mực', 'Nghêu / Sò / Ốc'],
    ),
    DislikedCategoryGroup(
      code: 'FRIED_FOOD',
      title: 'Món nước & Đồ rán',
      icon: Icons.cookie,
      subItems: ['Phở / Bún nhiều mỡ', 'Xôi mặn', 'Đồ chiên rán', 'Thức ăn nhanh'],
    ),
    DislikedCategoryGroup(
      code: 'SPICY_FOOD',
      title: 'Đồ cay & Ngọt',
      icon: Icons.whatshot,
      subItems: ['Rau củ đắng', 'Sầu riêng / Nhãn', 'Ớt / Đồ cay', 'Đồ ngọt nhiều đường'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<AssessmentCubit>().state;
    final initialNote = cubitState.dislikedFoodsNote ?? '';
    _noteController = TextEditingController(text: initialNote);

    if (initialNote.isNotEmpty) {
      final parts = initialNote.split(RegExp(r'[,;\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty);
      _selectedSubItems.addAll(parts);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _syncStateWithCubit() {
    final cubit = context.read<AssessmentCubit>();
    final activeGroups = <String>[];

    for (final group in categoryGroups) {
      final hasSelectedSubItem = group.subItems.any((item) => _selectedSubItems.contains(item));
      if (hasSelectedSubItem) {
        activeGroups.add(group.code);
      }
    }

    final customText = _noteController.text.trim();
    final allSubItems = List<String>.from(_selectedSubItems);
    if (customText.isNotEmpty && !allSubItems.contains(customText)) {
      allSubItems.add(customText);
    }

    final formattedNote = allSubItems.join(', ');
    
    for (final group in categoryGroups) {
      if (activeGroups.contains(group.code)) {
        if (!cubit.state.dislikedFoodGroups.contains(group.code)) {
          cubit.toggleDislikedFoodGroup(group.code);
        }
      } else {
        if (cubit.state.dislikedFoodGroups.contains(group.code)) {
          cubit.toggleDislikedFoodGroup(group.code);
        }
      }
    }

    cubit.setDislikedFoodsNote(formattedNote);
  }

  void _toggleSubItem(String groupCode, String item) {
    setState(() {
      if (_selectedSubItems.contains(item)) {
        _selectedSubItems.remove(item);
      } else {
        _selectedSubItems.add(item);
      }
    });
    _syncStateWithCubit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ShaderMask(
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
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn các loại thực phẩm cụ thể bạn không thích hoặc muốn hạn chế:',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categoryGroups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = categoryGroups[index];
                    final isExpanded = _expandedCategoryCode == group.code;
                    final selectedCount = group.subItems.where((item) => _selectedSubItems.contains(item)).length;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selectedCount > 0 ? AppTheme.primary : Colors.grey.shade200,
                          width: selectedCount > 0 ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () {
                              setState(() {
                                _expandedCategoryCode = isExpanded ? null : group.code;
                              });
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedCount > 0 ? AppTheme.primary.withOpacity(0.1) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(group.icon, color: selectedCount > 0 ? AppTheme.primary : const Color(0xFF64748B)),
                            ),
                            title: Text(
                              group.title,
                              style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: const Color(0xFF1E293B)),
                            ),
                            subtitle: selectedCount > 0
                                ? Text(
                                    'Đã chọn $selectedCount loại',
                                    style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                  )
                                : Text(
                                    'Bấm để xem các loại',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                            trailing: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: group.subItems.map((item) {
                                  final isSelected = _selectedSubItems.contains(item);
                                  return FilterChip(
                                    selected: isSelected,
                                    label: Text(item),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF334155),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    selectedColor: AppTheme.primary,
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    checkmarkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    onSelected: (_) {
                                      _toggleSubItem(group.code, item);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Thực phẩm kiêng cữ khác (nếu có):',
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  onChanged: (_) => _syncStateWithCubit(),
                  decoration: InputDecoration(
                    hintText: 'Nhập tên khác như: cần tây, mướp đắng, nấm mèo...',
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
        _buildBottomSection(),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          if (_selectedSubItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Đã chọn ${_selectedSubItems.length} thực phẩm kiêng cữ',
                style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.primary),
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
    );
  }
}
