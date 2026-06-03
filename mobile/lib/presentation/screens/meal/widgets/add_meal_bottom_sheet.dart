import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/models/food_model.dart';
import 'package:core_shared/models/daily_eating_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_state.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';

class AddMealBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final MealType selectedMealType;

  const AddMealBottomSheet({super.key, required this.selectedDate, required this.selectedMealType});

  @override
  State<AddMealBottomSheet> createState() => _AddMealBottomSheetState();
}

class _AddMealBottomSheetState extends State<AddMealBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isPastDate {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final selectedDay = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    return selectedDay.isBefore(today);
  }

  FoodModel? _selectedFood;
  double _quantity = 100; // default quantity in grams
  final TextEditingController _quantityController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    // Pre-search/prefetch if needed
    context.read<FoodCubit>().searchFoods(query: '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _getMealTypeName(MealType type) {
    switch (type) {
      case MealType.BREAKFAST:
        return 'Breakfast';
      case MealType.LUNCH:
        return 'Lunch';
      case MealType.DINNER:
        return 'Dinner';
      case MealType.SNACK:
        return 'Snack';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle and Title
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add to ${_getMealTypeName(widget.selectedMealType)}',
                  style: AppTheme.headlineStyle.copyWith(fontSize: 22, color: AppTheme.textPrimary),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isPastDate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Only today and future dates can add meals.',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                context.read<FoodCubit>().searchFoods(query: val);
              },
              decoration: InputDecoration(
                hintText: 'Search food...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          context.read<FoodCubit>().searchFoods(query: '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[100]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main body (either list or quantity configuration)
          Expanded(child: _selectedFood == null ? _buildFoodList() : _buildQuantityConfig()),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, state) {
        if (state.status == FoodStatus.loading && state.foods.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final dishes = state.foods.where((food) => food.type.toUpperCase() == 'DISH').toList();

        final filteredFoods = dishes.where((food) {
          if (_searchQuery.isEmpty) return true;
          return food.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredFoods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No dishes found', style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: filteredFoods.length,
          itemBuilder: (context, index) {
            final food = filteredFoods[index];
            final isDish = food.type == 'DISH';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: Colors.grey[50],
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? Image.network(
                          food.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                ),
                title: Text(
                  food.name,
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${food.caloriesPer100g.toStringAsFixed(0)} kcal • 100g',
                  style: AppTheme.bodyStyle.copyWith(fontSize: 13, color: AppTheme.textSecondary),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: isDish ? Colors.green.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: isDish ? Colors.green[800] : AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        isDish ? 'Dish' : 'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDish ? Colors.green[800] : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedFood = food;
                    _quantity = 100;
                    _quantityController.text = '100';
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuantityConfig() {
    final food = _selectedFood!;
    final double calories = food.caloriesPer100g * (_quantity / 100.0);
    final double protein = food.proteinPer100g * (_quantity / 100.0);
    final double fat = food.fatPer100g * (_quantity / 100.0);
    final double carbs = food.carbsPer100g * (_quantity / 100.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected food card preview
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedFood = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: AppTheme.headlineStyle.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                      style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Portion size configuration
          Text('Portion Size (g)', style: AppTheme.semiboldStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_quantity > 10) {
                    setState(() {
                      _quantity -= 10;
                      _quantityController.text = _quantity.toStringAsFixed(0);
                    });
                  }
                },
                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary, size: 28),
              ),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineStyle.copyWith(fontSize: 24),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _quantity = parsed;
                      });
                    }
                  },
                  decoration: const InputDecoration(suffixText: 'g', border: InputBorder.none, filled: false),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _quantity += 10;
                    _quantityController.text = _quantity.toStringAsFixed(0);
                  });
                },
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Portions Quick Presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [50, 100, 150, 200, 300, 500].map((preset) {
              final isSelected = _quantity == preset;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _quantity = preset.toDouble();
                    _quantityController.text = preset.toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${preset}g',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Dynamic Nutrition Info based on current quantity
          Text('Nutrients for this portion', style: AppTheme.semiboldStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildNutritionRow('Calories', '${calories.toStringAsFixed(0)} kcal', Colors.orange),
                const Divider(),
                _buildNutritionRow('Protein', '${protein.toStringAsFixed(1)} g', Colors.blue),
                const Divider(),
                _buildNutritionRow('Carbs', '${carbs.toStringAsFixed(1)} g', Colors.amber),
                const Divider(),
                _buildNutritionRow('Fats', '${fat.toStringAsFixed(1)} g', Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Add Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPastDate
                  ? null
                  : () async {
                      // Construct MealItemDTO map for body payload
                      final itemData = {
                        'foodId': food.id,
                        'servingQuantity': _quantity,
                        'isCustom': false,
                        // Snapshot fields fallback
                        'foodName': food.name,
                        'calories': calories,
                        'protein': protein,
                        'fat': fat,
                        'carbs': carbs,
                        'servingUnit': food.servings.isNotEmpty ? food.servings.first.name : 'grams',
                        'imageUrl': food.imageUrl,
                      };

                      await context.read<MealCubit>().addFoodToDiary(
                        date: widget.selectedDate,
                        mealType: widget.selectedMealType,
                        itemData: itemData,
                      );

                      if (!mounted) return;

                      await context.read<MealCubit>().fetchDailyEating(widget.selectedDate);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${food.name} to ${_getMealTypeName(widget.selectedMealType)}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
              child: const Text('Add to Diary'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: indicatorColor),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.bodyStyle),
            ],
          ),
          Text(value, style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
