import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
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
  late TextEditingController _servingSizeController;
  late TextEditingController _unitController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descController;
  late TextEditingController _healthScoreController;

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
    _servingSizeController = TextEditingController(text: f?.defaultServingSize?.toString() ?? '');
    _unitController = TextEditingController(text: f?.defaultUnit ?? 'g');
    _imageUrlController = TextEditingController(text: f?.imageUrl ?? '');
    _descController = TextEditingController(text: f?.description ?? '');
    _healthScoreController = TextEditingController(text: f?.healthScore?.toString() ?? '');
    
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allCategories = await adminRepository.getAllFoodCategories();
      if (!mounted) return;
      setState(() {
        _categories = allCategories.where((c) => c.appliesTo == widget.type || c.appliesTo == 'BOTH').toList();
        if (widget.food?.categoryName != null) {
          try {
            _selectedCategory = _categories.firstWhere((c) => c.name == widget.food!.categoryName);
          } catch (_) {}
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải danh mục: $e')));
      }
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
    _servingSizeController.dispose();
    _unitController.dispose();
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
        defaultServingSize: double.tryParse(_servingSizeController.text),
        defaultUnit: _unitController.text,
        imageUrl: _imageUrlController.text,
        description: _descController.text,
        healthScore: int.tryParse(_healthScoreController.text),
        categoryName: _selectedCategory?.name, // Only categoryName is in FoodModel for now, or you can map id if needed
      );
      Navigator.of(context).pop(updatedFood);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleType = widget.type == 'DISH' ? 'Món ăn' : 'Nguyên liệu';
    return AlertDialog(
      title: Text(widget.food == null ? 'Thêm $titleType' : 'Sửa $titleType', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600,
        child: _isLoading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên thực phẩm'),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FoodCategoryModel>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục (Category)'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _caloriesController,
                        decoration: const InputDecoration(labelText: 'Calo/100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _proteinController,
                        decoration: const InputDecoration(labelText: 'Protein/100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fatController,
                        decoration: const InputDecoration(labelText: 'Fat/100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _carbsController,
                        decoration: const InputDecoration(labelText: 'Carbs/100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fiberController,
                        decoration: const InputDecoration(labelText: 'Chất xơ/100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sugarController,
                        decoration: const InputDecoration(labelText: 'Đường/100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sodiumController,
                        decoration: const InputDecoration(labelText: 'Natri(mg)/100g'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _servingSizeController,
                        decoration: const InputDecoration(labelText: 'Serving mặc định (số lượng)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Đơn vị (g, ml, bowl...)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _healthScoreController,
                        decoration: const InputDecoration(labelText: 'Health Score (0-100)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
