import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../../logic/cubits/ingredients/ingredients_cubit.dart';
import '../../logic/cubits/ingredients/ingredients_state.dart';
import '../widgets/base_table_screen.dart';
import '../widgets/food_form_dialog.dart';
import 'ingredient_detail_screen.dart';

class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IngredientsCubit(adminRepository: adminRepository)..fetchIngredients(),
      child: const _IngredientsScreenContent(),
    );
  }
}

class _IngredientsScreenContent extends StatefulWidget {
  const _IngredientsScreenContent();

  @override
  State<_IngredientsScreenContent> createState() => _IngredientsScreenContentState();
}

class _IngredientsScreenContentState extends State<_IngredientsScreenContent> {
  List<CategoryFilterItem> _categoryFilterItems = [const CategoryFilterItem(id: null, label: 'Tất cả')];
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  void _showAddFoodDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const FoodFormDialog(type: 'INGREDIENT'),
    );
    if (result == true && mounted) {
      context.read<IngredientsCubit>().fetchIngredients(search: _searchQuery, categoryId: _selectedCategoryId);
    }
  }

  void _showEditFoodDialog(BuildContext context, FoodModel food) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FoodFormDialog(food: food, type: 'INGREDIENT'),
    );
    if (result == true && mounted) {
      context.read<IngredientsCubit>().fetchIngredients(search: _searchQuery, categoryId: _selectedCategoryId);
    }
  }

  void _confirmDeleteIngredient(BuildContext context, FoodModel ingredient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nguyên liệu "${ingredient.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<IngredientsCubit>().deleteIngredient(ingredient.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xóa nguyên liệu thành công!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IngredientsCubit, IngredientsState>(
      builder: (context, state) {
        final isLoading = state is IngredientsLoading;
        final pageData = state is IngredientsSuccess ? state.pageData : null;
        final items = pageData?.content ?? [];

        return BaseTableScreen(
          title: 'Quản lý Nguyên liệu',
          subtitle: 'Danh sách nguyên liệu thành phần món ăn',
          searchHint: 'Tìm kiếm tên nguyên liệu...',
          categoryFilters: _categoryFilterItems,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (catId) {
            setState(() {
              _selectedCategoryId = catId;
            });
            context.read<IngredientsCubit>().fetchIngredients(search: _searchQuery, categoryId: catId);
          },
          onSearchChanged: (query) {
            _searchQuery = query;
            context.read<IngredientsCubit>().fetchIngredients(search: query, categoryId: _selectedCategoryId);
          },
          onRefresh: () => context.read<IngredientsCubit>().fetchIngredients(search: _searchQuery, categoryId: _selectedCategoryId),
          onAddPressed: () => _showAddFoodDialog(context),
          currentPage: pageData?.pageNumber ?? 0,
          totalPages: pageData?.totalPages ?? 1,
          totalElements: pageData?.totalElements ?? 0,
          pageSize: pageData?.pageSize ?? 20,
          onPageChanged: (newPage) {
            context.read<IngredientsCubit>().fetchIngredients(
                  page: newPage,
                  search: _searchQuery,
                  categoryId: _selectedCategoryId,
                );
          },
          isLoading: isLoading,
          columns: const [
            'Tên Nguyên liệu',
            'Danh mục',
            'Calo (trên 100g)',
            'Protein / Carbs / Fat',
            'Hành động',
          ],
          rows: items.map((ingredient) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ingredient.imageUrl ?? '',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.kitchen, size: 22, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          ingredient.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(ingredient.category?.name ?? '---', style: const TextStyle(fontSize: 14))),
                DataCell(Text('${ingredient.caloriesPer100g.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                DataCell(
                  Text(
                    '${ingredient.proteinPer100g.toStringAsFixed(1)}g / ${ingredient.carbsPer100g.toStringAsFixed(1)}g / ${ingredient.fatPer100g.toStringAsFixed(1)}g',
                    style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20, color: AppTheme.textSecondary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IngredientDetailScreen(ingredientId: ingredient.id),
                            ),
                          );
                        },
                        tooltip: 'Xem chi tiết',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => _showEditFoodDialog(context, ingredient),
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () => _confirmDeleteIngredient(context, ingredient),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
