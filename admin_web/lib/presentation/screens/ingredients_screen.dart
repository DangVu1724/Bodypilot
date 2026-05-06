import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';
import '../widgets/food_form_dialog.dart';
import 'ingredient_detail_screen.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  late Future<List<FoodModel>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _ingredientsFuture = adminRepository.getAllIngredients();
  }

  void _refreshIngredients() {
    setState(() {
      _ingredientsFuture = adminRepository.getAllIngredients(forceRefresh: true);
    });
  }

  Future<void> _showAddEditDialog([FoodModel? food]) async {
    FoodModel? fullFood = food;
    if (food != null) {
      try {
        fullFood = await adminRepository.getFoodById(food.id);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể lấy chi tiết nguyên liệu: $e')));
        return;
      }
    }

    if (!mounted) return;

    final result = await showDialog<FoodModel>(
      context: context,
      builder: (context) => FoodFormDialog(food: fullFood, type: 'INGREDIENT'),
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
    return FutureBuilder<List<FoodModel>>(
      future: _ingredientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final ingredients = snapshot.data ?? [];

        return BaseTableScreen(
          title: 'Nguyên liệu',
          subtitle: 'Quản lý thực phẩm thô (Ingredients) từ hệ thống',
          onRefresh: _refreshIngredients,
          onAddPressed: () => _showAddEditDialog(),
          columns: const ['ID', 'Tên thực phẩm', 'Calo/100g', 'Protein', 'Hạng mục', 'Thao tác'],
          rows: ingredients.map((ing) => DataRow(cells: [
            DataCell(Text(ing.id.substring(0, 8))),
            DataCell(Text(ing.name)),
            DataCell(Text('${ing.caloriesPer100g} kcal')),
            DataCell(Text('${ing.proteinPer100g}g')),
            DataCell(Text(ing.categoryName ?? 'Chưa phân loại')),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => IngredientDetailScreen(ingredientId: ing.id)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAddEditDialog(ing)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _deleteIngredient(ing.id)),
              ],
            )),
          ])).toList(),
        );
      },
    );
  }
}
