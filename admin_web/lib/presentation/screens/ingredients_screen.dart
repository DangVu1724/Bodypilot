import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';
import '../../data/models/page_response_model.dart';
import '../widgets/food_form_dialog.dart';
import 'ingredient_detail_screen.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  late Future<PageResponseModel<FoodModel>> _ingredientsFuture;
  List<CategoryFilterItem> _categoryFilterItems = [const CategoryFilterItem(id: null, label: 'Tất cả')];
  String _searchQuery = '';
  String? _selectedCategoryId;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadIngredients(page: 0);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await adminRepository.getAllFoodCategories();
      final ingredientCategories = categories.where((c) => c.appliesTo == 'INGREDIENT' || c.appliesTo == 'BOTH').toList();
      if (mounted) {
        setState(() {
          _categoryFilterItems = [
            const CategoryFilterItem(id: null, label: 'Tất cả'),
            ...ingredientCategories.map((c) => CategoryFilterItem(id: c.id, label: c.name)),
          ];
        });
      }
    } catch (_) {}
  }

  void _loadIngredients({int page = 0}) {
    setState(() {
      _currentPage = page;
      _ingredientsFuture = adminRepository.getAllIngredients(
        page: page,
        size: 20,
        search: _searchQuery,
        categoryId: _selectedCategoryId,
      );
    });
  }

  void _refreshIngredients() {
    _loadIngredients(page: _currentPage);
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadIngredients(page: 0);
  }

  Future<void> _showAddEditDialog([FoodModel? food]) async {
    FoodModel? fullFood = food;
    if (food != null) {
      try {
        fullFood = await adminRepository.getFoodById(food.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể lấy chi tiết nguyên liệu: $e')));
        }
        return;
      }
    }

    if (!mounted) return;

    final result = await showDialog<FoodModel>(
      context: context,
      builder: (context) => FoodFormDialog(
        food: fullFood,
        type: 'INGREDIENT',
      ),
    );

    if (result != null) {
      try {
        if (food == null) {
          await adminRepository.createFood(result);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thành công')));
        } else {
          await adminRepository.updateFood(food.id, result);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sửa thành công')));
        }
        _refreshIngredients();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _deleteIngredient(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa nguyên liệu này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminRepository.deleteFood(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
        _refreshIngredients();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PageResponseModel<FoodModel>>(
      future: _ingredientsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final pageData = snapshot.data ?? PageResponseModel<FoodModel>.empty();
        final ingredients = pageData.content;

        return BaseTableScreen(
          title: 'Nguyên liệu',
          subtitle: 'Quản lý kho thực phẩm thô (Ingredients) làm công thức',
          onRefresh: _refreshIngredients,
          onAddPressed: () => _showAddEditDialog(),
          onSearchChanged: _onSearchChanged,
          searchHint: 'Tìm theo tên nguyên liệu...',
          categoryFilters: _categoryFilterItems,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (catId) {
            _selectedCategoryId = catId;
            _loadIngredients(page: 0);
          },
          isLoading: isLoading,
          currentPage: pageData.pageNumber,
          totalPages: pageData.totalPages,
          totalElements: pageData.totalElements,
          pageSize: pageData.pageSize,
          onPageChanged: (newPage) => _loadIngredients(page: newPage),
          columns: const ['ID', 'Tên thực phẩm', 'Calo/100g', 'Protein', 'Hạng mục', 'Thao tác'],
          rows: ingredients
              .map(
                (ing) => DataRow(
                  cells: [
                    DataCell(Text(ing.id.length >= 8 ? ing.id.substring(0, 8) : ing.id)),
                    DataCell(Text(ing.name)),
                    DataCell(Text('${ing.caloriesPer100g} kcal')),
                    DataCell(Text('${ing.proteinPer100g}g')),
                    DataCell(Text(ing.categoryName ?? 'Chưa phân loại')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => IngredientDetailScreen(ingredientId: ing.id)),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAddEditDialog(ing)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _deleteIngredient(ing.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        );
      },
    );
  }
}
