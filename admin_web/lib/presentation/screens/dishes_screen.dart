import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../../logic/cubits/dishes/dishes_cubit.dart';
import '../../logic/cubits/dishes/dishes_state.dart';
import '../widgets/base_table_screen.dart';
import 'dish_detail_screen.dart';
import 'dish_form_screen.dart';

class DishesScreen extends StatelessWidget {
  const DishesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DishesCubit(adminRepository: adminRepository)..fetchDishes(),
      child: const _DishesScreenContent(),
    );
  }
}

class _DishesScreenContent extends StatefulWidget {
  const _DishesScreenContent();

  @override
  State<_DishesScreenContent> createState() => _DishesScreenContentState();
}

class _DishesScreenContentState extends State<_DishesScreenContent> {
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

  void _confirmDeleteDish(BuildContext context, FoodModel dish) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa món ăn "${dish.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<DishesCubit>().deleteDish(dish.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xóa món ăn thành công!')),
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
    return BlocBuilder<DishesCubit, DishesState>(
      builder: (context, state) {
        final isLoading = state is DishesLoading;
        final pageData = state is DishesSuccess ? state.pageData : null;
        final items = pageData?.content ?? [];

        return BaseTableScreen(
          title: 'Quản lý Món ăn',
          subtitle: 'Danh sách công thức thực đơn và dinh dưỡng món ăn',
          searchHint: 'Tìm kiếm tên món ăn...',
          categoryFilters: _categoryFilterItems,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (catId) {
            setState(() {
              _selectedCategoryId = catId;
            });
            context.read<DishesCubit>().fetchDishes(search: _searchQuery, categoryId: catId);
          },
          onSearchChanged: (query) {
            _searchQuery = query;
            context.read<DishesCubit>().fetchDishes(search: query, categoryId: _selectedCategoryId);
          },
          onRefresh: () => context.read<DishesCubit>().fetchDishes(search: _searchQuery, categoryId: _selectedCategoryId),
          onAddPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (context) => const DishFormScreen()),
            );
            if (result == true && context.mounted) {
              context.read<DishesCubit>().fetchDishes(search: _searchQuery, categoryId: _selectedCategoryId);
            }
          },
          currentPage: pageData?.pageNumber ?? 0,
          totalPages: pageData?.totalPages ?? 1,
          totalElements: pageData?.totalElements ?? 0,
          pageSize: pageData?.pageSize ?? 20,
          onPageChanged: (newPage) {
            context.read<DishesCubit>().fetchDishes(
                  page: newPage,
                  search: _searchQuery,
                  categoryId: _selectedCategoryId,
                );
          },
          isLoading: isLoading,
          columns: const [
            'Tên Món ăn',
            'Danh mục',
            'Calo (trên 100g)',
            'Macros (P/C/F)',
            'Hành động',
          ],
          rows: items.map((dish) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          dish.imageUrl ?? '',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.restaurant, size: 22, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          dish.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(dish.category?.name ?? '---', style: const TextStyle(fontSize: 14))),
                DataCell(Text('${dish.caloriesPer100g.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                DataCell(
                  Text(
                    '${dish.proteinPer100g.toStringAsFixed(1)}g / ${dish.carbsPer100g.toStringAsFixed(1)}g / ${dish.fatPer100g.toStringAsFixed(1)}g',
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
                              builder: (context) => DishDetailScreen(dishId: dish.id),
                            ),
                          );
                        },
                        tooltip: 'Xem chi tiết',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DishFormScreen(dish: dish),
                            ),
                          );
                          if (result == true && context.mounted) {
                            context.read<DishesCubit>().fetchDishes(search: _searchQuery, categoryId: _selectedCategoryId);
                          }
                        },
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () => _confirmDeleteDish(context, dish),
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
