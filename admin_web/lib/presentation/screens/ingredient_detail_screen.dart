import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';

class IngredientDetailScreen extends StatefulWidget {
  final String ingredientId;

  const IngredientDetailScreen({super.key, required this.ingredientId});

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  late Future<FoodModel> _ingredientFuture;

  @override
  void initState() {
    super.initState();
    _ingredientFuture = adminRepository.getFoodById(widget.ingredientId);
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
        title: const Text('Chi tiết nguyên liệu', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          _buildActionButton(Icons.edit_outlined, 'Sửa', AppTheme.primaryColor),
          const SizedBox(width: 12),
          _buildActionButton(Icons.delete_outline, 'Xóa', Colors.red),
          const SizedBox(width: 24),
        ],
      ),
      body: FutureBuilder<FoodModel>(
        future: _ingredientFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final ingredient = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BÊN TRÁI: Hình ảnh
                    Expanded(
                      flex: 2,
                      child: _buildImageCard(ingredient),
                    ),
                    const SizedBox(width: 24),
                    // BÊN PHẢI: Thông tin & Dinh dưỡng
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildDetailsCard(ingredient),
                          const SizedBox(height: 24),
                          _buildNutritionCard(ingredient),
                        ],
                      ),
                    ),
                  ],
                ),
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

  Widget _buildImageCard(FoodModel ingredient) {
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
              child: ingredient.imageUrl != null
                  ? Image.network(
                      ingredient.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.green.shade50,
                        child: const Icon(Icons.broken_image_outlined, size: 64, color: Colors.green),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.eco_outlined, size: 64, color: Colors.grey),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(FoodModel ingredient) {
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
          Text(ingredient.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text('Mô tả nguyên liệu', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            ingredient.description ?? 'Không có mô tả cho nguyên liệu này.',
            style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildMetaItem('Danh mục', ingredient.categoryName ?? 'N/A', Colors.green),
              const SizedBox(width: 48),
              _buildMetaItem('Mã ID', ingredient.id.substring(0, 8), Colors.grey),
              const SizedBox(width: 48),
              _buildMetaItem('Health Score', '${ingredient.healthScore ?? 0}', Colors.orange),
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

  Widget _buildNutritionCard(FoodModel ingredient) {
    final macros = [
      _NutrientData('Calo', ingredient.caloriesPer100g, 'kcal', Icons.local_fire_department_outlined, Colors.orange),
      _NutrientData('Protein', ingredient.proteinPer100g, 'g', Icons.fitness_center, Colors.blue),
      _NutrientData('Chất béo', ingredient.fatPer100g, 'g', Icons.water_drop_outlined, Colors.red),
      _NutrientData('Carbs', ingredient.carbsPer100g, 'g', Icons.bakery_dining_outlined, Colors.amber),
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
}

class _NutrientData {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  _NutrientData(this.label, this.value, this.unit, this.icon, this.color);
}
