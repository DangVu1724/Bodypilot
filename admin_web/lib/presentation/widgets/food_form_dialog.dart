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
  late TextEditingController _imageUrlController;
  late TextEditingController _descController;
  late TextEditingController _healthScoreController;

  // Servings management
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
          // Prefer matching by ID, fallback to name
          if (food.category?.id != null) {
            try {
              _selectedCategory = _categories.firstWhere((c) => c.id == food.category!.id);
            } catch (_) {}
          }
          if (_selectedCategory == null && food.categoryName != null) {
            try {
              _selectedCategory = _categories.firstWhere((c) => c.name == food.categoryName);
            } catch (_) {}
          }
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
        defaultServingId: _selectedDefaultServingId,
        imageUrl: _imageUrlController.text,
        description: _descController.text,
        healthScore: int.tryParse(_healthScoreController.text),
        servings: _servings,
        category: _selectedCategory,
        categoryName: _selectedCategory?.name,
      );
      Navigator.of(context).pop(updatedFood);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleType = widget.type == 'DISH' ? 'Món ăn' : 'Nguyên liệu';
    return AlertDialog(
      title: Text(
        widget.food == null ? 'Thêm $titleType' : 'Sửa $titleType',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
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
                            child: DropdownButtonFormField<String>(
                              value: _selectedDefaultServingId,
                              decoration: const InputDecoration(labelText: 'Khẩu phần mặc định'),
                              hint: const Text('Chọn mặc định'),
                              items: _servings
                                  .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.grams}g)')))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedDefaultServingId = v),
                              validator: (v) => _servings.isNotEmpty && v == null ? 'Bắt buộc' : null,
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
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildServingsSection(),
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

  Widget _buildServingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Khẩu phần (Servings)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddEditServingDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_servings.isEmpty)
          const Text('Chưa có khẩu phần nào.', style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _servings.length,
            itemBuilder: (context, index) {
              final s = _servings[index];
              final isDefault = s.id == _selectedDefaultServingId;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(s.name, style: TextStyle(fontWeight: isDefault ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('${s.unitCode} | ${s.grams}g'),
                leading: isDefault
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : const Icon(Icons.circle_outlined, size: 20),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showAddEditServingDialog(s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () {
                        setState(() {
                          _servings.removeAt(index);
                          if (isDefault && _servings.isNotEmpty) {
                            _selectedDefaultServingId = _servings.first.id;
                          } else if (_servings.isEmpty) {
                            _selectedDefaultServingId = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddEditServingDialog([FoodServingModel? serving]) {
    final nameController = TextEditingController(text: serving?.name ?? '');
    final gramsController = TextEditingController(text: serving?.grams.toString() ?? '');
    String selectedUnitCode = serving?.unitCode ?? 'GRAM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(serving == null ? 'Thêm khẩu phần' : 'Sửa khẩu phần'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên (vd: Bát, Cái)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUnitCode,
                decoration: const InputDecoration(labelText: 'Mã đơn vị'),
                items: [
                  'GRAM',
                  'ML',
                  'PIECE',
                  'BOWL',
                  'CUP',
                  'SLICE',
                  'PORTION',
                ].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setStateDialog(() => selectedUnitCode = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gramsController,
                decoration: const InputDecoration(labelText: 'Khối lượng (g)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final grams = double.tryParse(gramsController.text) ?? 0;
                if (nameController.text.isNotEmpty && grams > 0) {
                  setState(() {
                    if (serving == null) {
                      final newServing = FoodServingModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        unitCode: selectedUnitCode,
                        grams: grams,
                      );
                      _servings.add(newServing);
                      if (_servings.length == 1) _selectedDefaultServingId = newServing.id;
                    } else {
                      final index = _servings.indexWhere((s) => s.id == serving.id);
                      if (index != -1) {
                        _servings[index] = FoodServingModel(
                          id: serving.id,
                          name: nameController.text,
                          unitCode: selectedUnitCode,
                          grams: grams,
                        );
                      }
                    }
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
