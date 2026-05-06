import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';

class DishDetailScreen extends StatefulWidget {
  final String dishId;

  const DishDetailScreen({super.key, required this.dishId});

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> with SingleTickerProviderStateMixin {
  late Future<FoodModel> _dishFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _dishFuture = adminRepository.getFoodById(widget.dishId);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết món ăn', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          _buildActionButton(Icons.edit_outlined, 'Sửa', AppTheme.primaryColor),
          const SizedBox(width: 12),
          _buildActionButton(Icons.delete_outline, 'Xóa', Colors.red),
          const SizedBox(width: 24),
        ],
      ),
      body: FutureBuilder<FoodModel>(
        future: _dishFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final dish = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BÊN TRÁI: Hình ảnh
                    Expanded(
                      flex: 2,
                      child: _buildImageCard(dish),
                    ),
                    const SizedBox(width: 24),
                    // BÊN PHẢI: Thông tin & Dinh dưỡng
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildDetailsCard(dish),
                          const SizedBox(height: 24),
                          _buildNutritionCard(dish),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTabsSection(dish),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildImageCard(FoodModel dish) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hình ảnh', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: dish.imageUrl != null
                  ? Image.network(
                      dish.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.orange.shade50,
                        child: const Icon(Icons.broken_image_outlined, size: 64, color: Colors.orange),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(FoodModel dish) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin chung', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(dish.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            dish.description ?? 'Không có mô tả cho món ăn này.',
            style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildMetaItem('Danh mục', dish.categoryName ?? 'N/A', Colors.blue),
              const SizedBox(width: 48),
              _buildMetaItem('Thời gian nấu', '${dish.recipe?.cookingTimeMinutes ?? 0} phút', Colors.orange),
              const SizedBox(width: 48),
              _buildMetaItem('Health Score', '${dish.healthScore ?? 0}', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(FoodModel dish) {
    final macros = [
      _NutrientData('Calo', dish.caloriesPer100g, 'kcal', Icons.local_fire_department_outlined, Colors.orange),
      _NutrientData('Protein', dish.proteinPer100g, 'g', Icons.egg_outlined, Colors.blue),
      _NutrientData('Carbs', dish.carbsPer100g, 'g', Icons.grain, Colors.amber),
      _NutrientData('Chất béo', dish.fatPer100g, 'g', Icons.pie_chart_outline, Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dinh dưỡng (100g)', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: macros.length,
            itemBuilder: (context, index) {
              final m = macros[index];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: m.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(m.icon, color: m.color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(m.label, style: TextStyle(fontSize: 10, color: m.color.withOpacity(0.8))),
                          Text('${m.value}${m.unit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection(FoodModel dish) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Nguyên liệu'),
              Tab(text: 'Cách chế biến'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientsTab(dish),
                _buildInstructionsTab(dish),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(FoodModel dish) {
    final ingredients = dish.recipe?.ingredients ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ing = ingredients[index];
        return ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.restaurant, color: Colors.white, size: 20)),
          title: Text(ing.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text('${ing.quantityGrams.toInt()}g', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        );
      },
    );
  }

  Widget _buildInstructionsTab(FoodModel dish) {
    final instructions = dish.recipe?.instructions;
    if (instructions == null) return const Center(child: Text('Chưa có hướng dẫn'));
    final steps = instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: AppTheme.primaryColor, radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white))),
              const SizedBox(width: 16),
              Expanded(child: Text(steps[index].trim(), style: const TextStyle(fontSize: 16, height: 1.6))),
            ],
          ),
        );
      },
    );
  }
}

class _NutrientData {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  _NutrientData(this.label, this.value, this.unit, this.icon, this.color);
}
