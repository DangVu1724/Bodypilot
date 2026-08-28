import 'package:core_shared/models/daily_eating_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/category_image_helper.dart';

class AiMealSlotCard extends StatelessWidget {
  final MealSlotModel slot;

  static const Map<MealType, String> _mealTypeNames = {
    MealType.BREAKFAST: 'Bữa sáng',
    MealType.LUNCH: 'Bữa trưa',
    MealType.DINNER: 'Bữa tối',
    MealType.SNACK: 'Bữa phụ / Bữa xế',
  };

  static const Map<MealType, IconData> _mealTypeIcons = {
    MealType.BREAKFAST: Icons.wb_sunny_outlined,
    MealType.LUNCH: Icons.wb_twilight,
    MealType.DINNER: Icons.nightlight_round_outlined,
    MealType.SNACK: Icons.apple_outlined,
  };

  const AiMealSlotCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final mealName = _mealTypeNames[slot.mealType] ?? slot.customName ?? 'Bữa ăn';
    final mealIcon = _mealTypeIcons[slot.mealType] ?? Icons.restaurant_menu;
    final totalCalories = slot.items.fold<double>(0, (sum, item) => sum + item.caloriesSnapshot);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFF7A30).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(mealIcon, color: const Color(0xFFFF7A30), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  mealName,
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Meal Items list
          if (slot.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Không có gợi ý món ăn cho bữa này.',
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slot.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final item = slot.items[index];
                return _buildMealItemRow(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMealItemRow(MealItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          CategoryFoodImage(
            imageUrl: item.imageUrlSnapshot,
            categoryName: item.foodNameSnapshot,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodNameSnapshot,
                  style: GoogleFonts.workSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Định lượng: ${item.servingQuantity.toStringAsFixed(0)} ${item.servingUnitSnapshot ?? 'g'}',
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),

                // Macros row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroItem(
                      '${item.caloriesSnapshot.toStringAsFixed(0)} kcal',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                    _buildMacroItem(
                      'P: ${item.proteinSnapshot.toStringAsFixed(0)}g',
                      Icons.fitness_center,
                      Colors.blue,
                    ),
                    _buildMacroItem('F: ${item.fatSnapshot.toStringAsFixed(0)}g', Icons.opacity, Colors.red),
                    _buildMacroItem('C: ${item.carbsSnapshot.toStringAsFixed(0)}g', Icons.grain, Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.workSans(fontSize: 11, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
