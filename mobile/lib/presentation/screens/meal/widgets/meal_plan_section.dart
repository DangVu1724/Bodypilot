import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_state.dart';
import 'package:core_shared/models/daily_eating_model.dart';
import 'package:mobile/presentation/screens/meal/meal_plan_screen.dart';

class MealPlanSection extends StatefulWidget {
  const MealPlanSection({super.key});

  @override
  State<MealPlanSection> createState() => _MealPlanSectionState();
}

class _MealPlanSectionState extends State<MealPlanSection> {
  String selectedMeal = 'Breakfast';
  final List<String> meals = ['Breakfast', 'Lunch', 'Dinner'];

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
            Text('Your Meal Plan', style: AppTheme.headlineStyle.copyWith(fontSize: 20, color: AppTheme.textPrimary)),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(MaterialPageRoute(builder: (context) => const MealPlanScreen()));
              },
              child: Text('See All', style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 14)),
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
    return Row(
      children: meals.map((meal) {
        bool isSelected = selectedMeal == meal;
        return GestureDetector(
          onTap: () => setState(() => selectedMeal = meal),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
    final item = slot?.items.isNotEmpty == true ? slot!.items.first : null;

    if (item == null) {
      return _buildEmptyMealCard();
    }

    final imageUrl = (item.imageUrlSnapshot ?? '').isNotEmpty
        ? item.imageUrlSnapshot!
        : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          // Food Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.foodNameSnapshot,
                      style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F7),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBEE3F8), width: 1),
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF48BB78), size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroItem('Calories', '${item.caloriesSnapshot.toStringAsFixed(0)} kcal', Colors.orange),
                    _buildMacroItem('Protein', '${item.proteinSnapshot.toStringAsFixed(1)}g', Colors.blue),
                    _buildMacroItem('Fat', '${item.fatSnapshot.toStringAsFixed(1)}g', Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MealType _mealTypeFromLabel(String label) {
    switch (label) {
      case 'Breakfast':
        return MealType.BREAKFAST;
      case 'Lunch':
        return MealType.LUNCH;
      case 'Dinner':
        return MealType.DINNER;
      default:
        return MealType.BREAKFAST;
    }
  }

  Widget _buildEmptyMealCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text('No meals added for today yet.', style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 35,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
            Text(value, style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}
