import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';
import '../../data/models/page_response_model.dart';
import 'dish_detail_screen.dart';
import 'dish_form_screen.dart';

class DishesScreen extends StatefulWidget {
  const DishesScreen({super.key});

  @override
  State<DishesScreen> createState() => _DishesScreenState();
}

class _DishesScreenState extends State<DishesScreen> {
  late Future<PageResponseModel<FoodModel>> _dishesFuture;
  List<CategoryFilterItem> _categoryFilterItems = [const CategoryFilterItem(id: null, label: 'Tất cả')];
  String _searchQuery = '';
  String? _selectedCategoryId;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDishes(page: 0);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await adminRepository.getAllFoodCategories();
      final dishCategories = categories.where((c) => c.appliesTo == 'DISH' || c.appliesTo == 'BOTH').toList();
      if (mounted) {
        setState(() {
          _categoryFilterItems = [
            const CategoryFilterItem(id: null, label: 'Tất cả'),
            ...dishCategories.map((c) => CategoryFilterItem(id: c.id, label: c.name)),
          ];
        });
      }
    } catch (_) {}
  }

  void _loadDishes({int page = 0}) {
    setState(() {
      _currentPage = page;
      _dishesFuture = adminRepository.getAllDishes(
        page: page,
        size: 20,
        search: _searchQuery,
        categoryId: _selectedCategoryId,
      );
    });
  }

  void _refreshDishes() {
    _loadDishes(page: _currentPage);
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadDishes(page: 0);
  }

  Future<void> _showAddEditDialog([FoodModel? food]) async {
    FoodModel? fullFood = food;
    if (food != null) {
      try {
        fullFood = await adminRepository.getFoodById(food.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể lấy chi tiết món ăn: $e')));
        }
        return;
      }
    }

    if (!mounted) {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => DishFormScreen(dish: fullFood)),
    );

    if (result == true) {
      _refreshDishes();
    }
  }

  Future<void> _deleteDish(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa món ăn này không?'),
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
        _refreshDishes();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PageResponseModel<FoodModel>>(
      future: _dishesFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final pageData = snapshot.data ?? PageResponseModel<FoodModel>.empty();
        final dishes = pageData.content;

        return BaseTableScreen(
          title: 'Món ăn',
          subtitle: 'Quản lý các thành phẩm (Dishes) từ hệ thống',
          onRefresh: _refreshDishes,
          onAddPressed: () => _showAddEditDialog(),
          onSearchChanged: _onSearchChanged,
          searchHint: 'Tìm theo tên món ăn...',
          categoryFilters: _categoryFilterItems,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (catId) {
            _selectedCategoryId = catId;
            _loadDishes(page: 0);
          },
          isLoading: isLoading,
          currentPage: pageData.pageNumber,
          totalPages: pageData.totalPages,
          totalElements: pageData.totalElements,
          pageSize: pageData.pageSize,
          onPageChanged: (newPage) => _loadDishes(page: newPage),
          columns: const ['ID', 'Tên món', 'Hạng mục', 'Calo/100g', 'Protein', 'Carbs', 'Thao tác'],
          rows: dishes
              .map(
                (dish) => DataRow(
                  cells: [
                    DataCell(Text(dish.id.length >= 8 ? dish.id.substring(0, 8) : dish.id)),
                    DataCell(Text(dish.name)),
                    DataCell(Text(dish.categoryName ?? 'Chưa phân loại')),
                    DataCell(Text('${dish.caloriesPer100g} kcal')),
                    DataCell(Text('${dish.proteinPer100g}g')),
                    DataCell(Text('${dish.carbsPer100g}g')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DishDetailScreen(dishId: dish.id)),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAddEditDialog(dish)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _deleteDish(dish.id),
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
