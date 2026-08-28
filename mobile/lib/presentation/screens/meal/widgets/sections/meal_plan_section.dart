import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_state.dart';
import 'package:core_shared/models/daily_eating_model.dart';
import 'package:mobile/presentation/screens/meal/meal_plan_screen.dart';
import 'package:mobile/core/utils/category_image_helper.dart';

class MealPlanSection extends StatefulWidget {
  const MealPlanSection({super.key});

  @override
  State<MealPlanSection> createState() => _MealPlanSectionState();
}

class _MealPlanSectionState extends State<MealPlanSection> {
  String selectedMeal = 'Bữa Sáng';
  final List<String> meals = ['Bữa Sáng', 'Bữa Trưa', 'Bữa Tối'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealCubit>().fetchDailyEating(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Thực Đơn Hàng Ngày', style: AppTheme.headlineStyle.copyWith(fontSize: 20, color: AppTheme.textPrimary)),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(MaterialPageRoute(builder: (context) => const MealPlanScreen()));
              },
              child: Text('Xem tất cả', style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMealTabs(),
        const SizedBox(height: 16),
        BlocBuilder<MealCubit, MealState>(
          builder: (context, state) {
            return _buildMealCard(state);
          },
        ),
      ],
    );
  }

  Widget _buildMealTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: meals.map((meal) {
          bool isSelected = selectedMeal == meal;
          return GestureDetector(
            onTap: () => setState(() => selectedMeal = meal),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4A3728) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                meal,
                style: AppTheme.semiboldStyle.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealCard(MealState state) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyEating = state.dailyEatings[today];

    final selectedType = _mealTypeFromLabel(selectedMeal);
    final slot = dailyEating?.mealSlots.firstWhere(
      (item) => item.mealType == selectedType,
      orElse: () => MealSlotModel(mealType: selectedType, items: const []),
    );
    final items = slot?.items ?? [];

    if (items.isEmpty) {
      return _buildEmptyMealCard();
    }

    return SizedBox(
      height: 275,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 215,
            margin: EdgeInsets.only(
              right: index == items.length - 1 ? 0 : 12,
              top: 4,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image
                CategoryFoodImage(
                  imageUrl: item.imageUrlSnapshot,
                  categoryName: item.foodNameSnapshot,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.foodNameSnapshot,
                              style: AppTheme.semiboldStyle.copyWith(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF2F7),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFBEE3F8), width: 1),
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF48BB78), size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Stack macro parameters vertically
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMacroItem('Serving', '${item.servingQuantity.toStringAsFixed(0)} ${item.servingUnitSnapshot ?? 'g'}', const Color(0xFF00B4D8)),
                          const SizedBox(height: 4),
                          _buildMacroItem('Calories', '${item.caloriesSnapshot.toStringAsFixed(0)} kcal', Colors.orange),
                          const SizedBox(height: 4),
                          _buildMacroItem('Protein', '${item.proteinSnapshot.toStringAsFixed(1)}g', Colors.blue),
                          const SizedBox(height: 4),
                          _buildMacroItem('Fat', '${item.fatSnapshot.toStringAsFixed(1)}g', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  MealType _mealTypeFromLabel(String label) {
    switch (label) {
      case 'Breakfast':
      case 'Bữa Sáng':
        return MealType.BREAKFAST;
      case 'Lunch':
      case 'Bữa Trưa':
        return MealType.LUNCH;
      case 'Dinner':
      case 'Bữa Tối':
        return MealType.DINNER;
      default:
        return MealType.BREAKFAST;
    }
  }

  Widget _buildEmptyMealCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text('Chưa có món ăn nào cho hôm nay.', style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTheme.bodyStyle.copyWith(fontSize: 11, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: AppTheme.semiboldStyle.copyWith(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
