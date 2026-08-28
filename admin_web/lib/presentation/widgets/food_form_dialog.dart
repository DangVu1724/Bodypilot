import 'package:core_shared/core_shared.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';

class FoodFormDialog extends StatefulWidget {
  final FoodModel? food;
  final String type; // 'INGREDIENT' or 'DISH'

  const FoodFormDialog({super.key, this.food, required this.type});

  @override
  State<FoodFormDialog> createState() => _FoodFormDialogState();
}

class _FoodFormDialogState extends State<FoodFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  late TextEditingController _fiberController;
  late TextEditingController _sugarController;
  late TextEditingController _sodiumController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descController;
  late TextEditingController _healthScoreController;

  List<FoodServingModel> _servings = [];
  String? _selectedDefaultServingId;

  bool _isLoading = true;
  List<FoodCategoryModel> _categories = [];
  FoodCategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _nameController = TextEditingController(text: f?.name ?? '');
    _caloriesController = TextEditingController(text: f?.caloriesPer100g.toString() ?? '');
    _proteinController = TextEditingController(text: f?.proteinPer100g.toString() ?? '');
    _fatController = TextEditingController(text: f?.fatPer100g.toString() ?? '');
    _carbsController = TextEditingController(text: f?.carbsPer100g.toString() ?? '');
    _fiberController = TextEditingController(text: f?.fiberPer100g?.toString() ?? '');
    _sugarController = TextEditingController(text: f?.sugarPer100g?.toString() ?? '');
    _sodiumController = TextEditingController(text: f?.sodiumMgPer100g?.toString() ?? '');
    _imageUrlController = TextEditingController(text: f?.imageUrl ?? '');
    _descController = TextEditingController(text: f?.description ?? '');
    _healthScoreController = TextEditingController(text: f?.healthScore?.toString() ?? '');

    _servings = List.from(f?.servings ?? []);
    _selectedDefaultServingId = f?.defaultServingId;

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allCategories = await adminRepository.getAllFoodCategories();
      if (!mounted) return;
      setState(() {
        _categories = allCategories.where((c) => c.appliesTo == widget.type || c.appliesTo == 'BOTH').toList();
        final food = widget.food;
        if (food != null) {
          if (food.category?.id != null) {
            try {
              _selectedCategory = _categories.firstWhere((c) => c.id == food.category!.id);
            } catch (_) {}
          }
          if (_selectedCategory == null && food.category?.name != null) {
            try {
              _selectedCategory = _categories.firstWhere(
                (c) => c.name.toLowerCase() == food.category!.name.toLowerCase(),
              );
            } catch (_) {}
          }
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _imageUrlController.dispose();
    _descController.dispose();
    _healthScoreController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedFood = FoodModel(
        id: widget.food?.id ?? '',
        name: _nameController.text,
        type: widget.type,
        caloriesPer100g: double.tryParse(_caloriesController.text) ?? 0,
        proteinPer100g: double.tryParse(_proteinController.text) ?? 0,
        fatPer100g: double.tryParse(_fatController.text) ?? 0,
        carbsPer100g: double.tryParse(_carbsController.text) ?? 0,
        fiberPer100g: double.tryParse(_fiberController.text),
        sugarPer100g: double.tryParse(_sugarController.text),
        sodiumMgPer100g: double.tryParse(_sodiumController.text),
        category: _selectedCategory,
        categoryName: _selectedCategory?.name,
        defaultServingId: _selectedDefaultServingId,
        imageUrl: _imageUrlController.text,
        description: _descController.text,
        healthScore: int.tryParse(_healthScoreController.text),
        servings: _servings,
      );

      Navigator.of(context).pop(updatedFood);
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.food != null;
    final isDish = widget.type == 'DISH';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 850),
        padding: const EdgeInsets.all(32),
        child: _isLoading
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isDish ? Icons.restaurant_rounded : Icons.kitchen_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit
                                    ? (isDish ? 'Sửa Món Ăn' : 'Sửa Nguyên Liệu')
                                    : (isDish ? 'Thêm Món Ăn Mới' : 'Thêm Nguyên Liệu Mới'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit ? 'Cập nhật thông tin chi tiết thực phẩm' : 'Điền đầy đủ các chỉ số dinh dưỡng',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFF1F5F9)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: _buildInputDecoration('Tên thực phẩm'),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<FoodCategoryModel>(
                                    initialValue: _selectedCategory,
                                    decoration: _buildInputDecoration('Danh mục (Category)'),
                                    items: _categories
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedCategory = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              decoration: _buildInputDecoration('Mô tả thực phẩm'),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Chỉ số Dinh dưỡng (Tính trên 100g)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _caloriesController,
                                    decoration: _buildInputDecoration('Calo (kcal/100g)'),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v!.isEmpty ? 'Nhập Calo' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _proteinController,
                                    decoration: _buildInputDecoration('Protein (g/100g)'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _carbsController,
                                    decoration: _buildInputDecoration('Carbs (g/100g)'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _fatController,
                                    decoration: _buildInputDecoration('Chất béo (g/100g)'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _fiberController,
                                    decoration: _buildInputDecoration('Chất xơ (g/100g)'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sugarController,
                                    decoration: _buildInputDecoration('Đường (g/100g)'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sodiumController,
                                    decoration: _buildInputDecoration('Muối/Sodium (mg)'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _imageUrlController,
                                    decoration: _buildInputDecoration('Đường dẫn Hình ảnh (Image URL)'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _healthScoreController,
                                    decoration: _buildInputDecoration('Điểm sức khỏe (1 - 100)'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text(
                          'Hủy bỏ',
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
