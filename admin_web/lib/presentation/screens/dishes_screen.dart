import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';
import '../widgets/food_form_dialog.dart';
import 'dish_detail_screen.dart';
import 'dish_form_screen.dart';

class DishesScreen extends StatefulWidget {
  const DishesScreen({super.key});

  @override
  State<DishesScreen> createState() => _DishesScreenState();
}

class _DishesScreenState extends State<DishesScreen> {
  late Future<List<FoodModel>> _dishesFuture;

  @override
  void initState() {
    super.initState();
    _dishesFuture = adminRepository.getAllDishes();
  }

  void _refreshDishes() {
    setState(() {
      _dishesFuture = adminRepository.getAllDishes(forceRefresh: true);
    });
  }

  Future<void> _showAddEditDialog([FoodModel? food]) async {
    FoodModel? fullFood = food;
    if (food != null) {
      try {
        fullFood = await adminRepository.getFoodById(food.id);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể lấy chi tiết món ăn: $e')));
        return;
      }
    }

    if (!mounted) return;

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
    return FutureBuilder<List<FoodModel>>(
      future: _dishesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final dishes = snapshot.data ?? [];

        return BaseTableScreen(
          title: 'Món ăn',
          subtitle: 'Quản lý các thành phẩm (Dishes) từ hệ thống',
          onRefresh: _refreshDishes,
          onAddPressed: () => _showAddEditDialog(),
          columns: const ['ID', 'Tên món', 'Calo/100g', 'Protein', 'Carbs', 'Thao tác'],
          rows: dishes.map((dish) => DataRow(cells: [
            DataCell(Text(dish.id.substring(0, 8))),
            DataCell(Text(dish.name)),
            DataCell(Text('${dish.caloriesPer100g} kcal')),
            DataCell(Text('${dish.proteinPer100g}g')),
            DataCell(Text('${dish.carbsPer100g}g')),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DishDetailScreen(dishId: dish.id)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAddEditDialog(dish)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _deleteDish(dish.id)),
              ],
            )),
          ])).toList(),
        );
      },
    );
  }
}
