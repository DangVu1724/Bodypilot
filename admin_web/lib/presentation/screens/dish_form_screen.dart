import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';

class DishFormScreen extends StatefulWidget {
  final FoodModel? dish;

  const DishFormScreen({super.key, this.dish});

  @override
  State<DishFormScreen> createState() => _DishFormScreenState();
}

class _DishFormScreenState extends State<DishFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
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
  
  // Recipe details
  late TextEditingController _cookingTimeController;
  late TextEditingController _servingsController;

  bool _isLoading = true;
  List<FoodCategoryModel> _categories = [];
  FoodCategoryModel? _selectedCategory;

  // Recipe Steps
  final List<TextEditingController> _stepControllers = [];

  // Recipe Ingredients
  List<FoodModel> _allIngredients = [];
  List<RecipeIngredientModel> _recipeIngredients = [];

  @override
  void initState() {
    super.initState();
    final f = widget.dish;
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

    _cookingTimeController = TextEditingController(text: f?.recipe?.cookingTimeMinutes?.toString() ?? '');
    _servingsController = TextEditingController(text: f?.recipe?.servings.toString() ?? '1');

    // Parse existing steps (assuming separated by \n\n)
    if (f?.recipe?.instructions != null && f!.recipe!.instructions!.isNotEmpty) {
      final steps = f.recipe!.instructions!.split('\n\n');
      for (var step in steps) {
        if (step.trim().isNotEmpty) {
          _stepControllers.add(TextEditingController(text: step.trim()));
        }
      }
    }
    if (_stepControllers.isEmpty) {
      _stepControllers.add(TextEditingController());
    }

    if (f?.recipe?.ingredients != null) {
      _recipeIngredients = List.from(f!.recipe!.ingredients);
    }

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        adminRepository.getAllFoodCategories(),
        adminRepository.getAllIngredients(),
      ]);
      final allCategories = futures[0] as List<FoodCategoryModel>;
      final ingredients = futures[1] as List<FoodModel>;

      if (!mounted) return;
      setState(() {
        _categories = allCategories.where((c) => c.appliesTo == 'DISH' || c.appliesTo == 'BOTH').toList();
        final dish = widget.dish;
        if (dish != null) {
          // Prefer matching by ID, fallback to name
          if (dish.category?.id != null) {
            try {
              _selectedCategory = _categories.firstWhere((c) => c.id == dish.category!.id);
            } catch (_) {}
          }
          if (_selectedCategory == null && dish.categoryName != null) {
            try {
              _selectedCategory = _categories.firstWhere((c) => c.name == dish.categoryName);
            } catch (_) {}
          }
        }
        _allIngredients = ingredients;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
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
    _cookingTimeController.dispose();
    _servingsController.dispose();
    for (var c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Prepare instructions
      final instructions = _stepControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join('\n\n');

      final recipe = RecipeModel(
        id: widget.dish?.recipe?.id ?? '',
        servings: int.tryParse(_servingsController.text) ?? 1,
        cookingTimeMinutes: int.tryParse(_cookingTimeController.text),
        instructions: instructions,
        ingredients: _recipeIngredients,
      );

      final updatedFood = FoodModel(
        id: widget.dish?.id ?? '',
        name: _nameController.text,
        type: 'DISH',
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
        recipe: recipe,
      );

      setState(() => _isLoading = true);
      try {
        if (widget.dish == null) {
          await adminRepository.createFood(updatedFood);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm món ăn thành công')));
        } else {
          await adminRepository.updateFood(widget.dish!.id, updatedFood);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật món ăn thành công')));
        }
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu món ăn: $e')));
      }
    }
  }

  void _addIngredient(FoodModel ingredient, String quantityText, String? displayQuantity) {
    final qty = quantityText.isNotEmpty ? double.tryParse(quantityText) : 0.0;
    // At least one of the two must be filled
    if ((qty == null || qty < 0) && (displayQuantity == null || displayQuantity.isEmpty)) return;
    
    setState(() {
      final existingIndex = _recipeIngredients.indexWhere((r) => r.foodId == ingredient.id);
      if (existingIndex >= 0) {
        final existing = _recipeIngredients[existingIndex];
        _recipeIngredients[existingIndex] = RecipeIngredientModel(
          id: existing.id,
          foodId: ingredient.id,
          foodName: ingredient.name,
          quantityGrams: (qty ?? 0) + (existing.quantityGrams),
          displayQuantity: displayQuantity ?? existing.displayQuantity,
        );
      } else {
        _recipeIngredients.add(RecipeIngredientModel(
          id: '',
          foodId: ingredient.id,
          foodName: ingredient.name,
          quantityGrams: qty ?? 0,
          displayQuantity: displayQuantity,
        ));
      }
    });
  }

  void _showAddIngredientDialog() {
    FoodModel? selectedFood;
    final qtyController = TextEditingController();
    final displayQtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm nguyên liệu'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<FoodModel>(
                      displayStringForOption: (option) => option.name,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<FoodModel>.empty();
                        }
                        return _allIngredients.where((FoodModel option) {
                          return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (FoodModel selection) {
                        setDialogState(() {
                          selectedFood = selection;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                            labelText: 'Tìm nguyên liệu',
                            hintText: 'Nhập tên nguyên liệu...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (selectedFood != null)
                      Text('Đã chọn: ${selectedFood!.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: displayQtyController,
                      decoration: const InputDecoration(
                        labelText: 'Định lượng hiển thị (vd: 1 thìa, 1 bó)',
                        hintText: 'Nhập cách hiển thị lượng nguyên liệu',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Khối lượng quy đổi (gram)',
                        suffixText: 'g',
                        hintText: 'Để tính dinh dưỡng',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedFood != null && (qtyController.text.isNotEmpty || displayQtyController.text.isNotEmpty)) {
                      _addIngredient(selectedFood!, qtyController.text, displayQtyController.text.isNotEmpty ? displayQtyController.text : null);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dish == null ? 'Thêm Món Ăn Mới' : 'Chỉnh Sửa Món Ăn'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: const Icon(Icons.save),
              label: const Text('Lưu Món Ăn'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Basic Info
                    Expanded(
                      flex: 4,
                      child: _buildBasicInfoSection(),
                    ),
                    const SizedBox(width: 24),
                    // Column 2: Recipe (Ingredients + Steps)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildServingsSection(),
                          const SizedBox(height: 24),
                          _buildIngredientsSection(),
                          const SizedBox(height: 24),
                          _buildStepsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin cơ bản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên món ăn', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FoodCategoryModel>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Danh mục (Category)', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDefaultServingId,
              decoration: const InputDecoration(labelText: 'Khẩu phần mặc định', border: OutlineInputBorder()),
              hint: const Text('Chọn khẩu phần mặc định'),
              items: _servings.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.grams}g)'))).toList(),
              onChanged: (v) => setState(() => _selectedDefaultServingId = v),
              validator: (v) => _servings.isNotEmpty && v == null ? 'Vui lòng chọn khẩu phần mặc định' : null,
            ),
            const SizedBox(height: 16),
            const Text('Dinh dưỡng / 100g', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calo (kcal)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _proteinController, decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _fatController, decoration: const InputDecoration(labelText: 'Fat (g)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _carbsController, decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _fiberController, decoration: const InputDecoration(labelText: 'Chất xơ (g)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _sugarController, decoration: const InputDecoration(labelText: 'Đường (g)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _sodiumController, decoration: const InputDecoration(labelText: 'Natri (mg)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _healthScoreController, decoration: const InputDecoration(labelText: 'Health Score (1-100)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _cookingTimeController, decoration: const InputDecoration(labelText: 'T/g Nấu (phút)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nguyên liệu (Ingredients)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddIngredientDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm nguyên liệu'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue, elevation: 0),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_recipeIngredients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: const Center(child: Text('Chưa có nguyên liệu nào. Hãy thêm nguyên liệu để định lượng khẩu phần.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recipeIngredients.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final ri = _recipeIngredients[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ri.foodName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ri.displayQuantity ?? '${ri.quantityGrams} g', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => _recipeIngredients.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Công thức (Instructions)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _stepControllers.add(TextEditingController())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm bước'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, foregroundColor: Colors.green, elevation: 0),
                )
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stepControllers.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _stepControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung bước ${index + 1}...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _stepControllers[index].dispose();
                          _stepControllers.removeAt(index);
                        });
                      },
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildServingsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Khẩu phần (Servings)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditServingDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm khẩu phần'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange, elevation: 0),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_servings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: const Center(child: Text('Chưa có khẩu phần nào. Hãy thêm ít nhất một khẩu phần (vd: 100g).', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _servings.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final s = _servings[index];
                  final isDefault = s.id == _selectedDefaultServingId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.name, style: TextStyle(fontWeight: isDefault ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text('Đơn vị: ${s.unitCode} | ${s.grams}g'),
                    leading: isDefault ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.circle_outlined, color: Colors.grey),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showAddEditServingDialog(s)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
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
        ),
      ),
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
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên khẩu phần (vd: Bát, Cái, Cup)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUnitCode,
                decoration: const InputDecoration(labelText: 'Mã đơn vị'),
                items: ['GRAM', 'ML', 'PIECE', 'BOWL', 'CUP', 'SLICE', 'PORTION']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setStateDialog(() => selectedUnitCode = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: gramsController, decoration: const InputDecoration(labelText: 'Khối lượng quy đổi (gram)'), keyboardType: TextInputType.number),
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
                        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
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
