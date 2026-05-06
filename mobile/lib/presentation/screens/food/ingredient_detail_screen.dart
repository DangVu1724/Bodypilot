import 'package:core_shared/models/food_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_state.dart';
import 'package:mobile/presentation/widgets/skeleton.dart';

class IngredientDetailScreen extends StatefulWidget {
  final String foodId;

  const IngredientDetailScreen({super.key, required this.foodId});

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FoodCubit>().getFoodDetails(widget.foodId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<FoodCubit, FoodState>(
        builder: (context, state) {
          if (state.status == FoodStatus.loading) {
            return const IngredientDetailSkeleton();
          }

          if (state.status == FoodStatus.failure) {
            return Center(child: Text(state.errorMessage ?? 'Error loading ingredient details'));
          }

          final food = state.selectedFood;
          if (food == null) {
            return const Center(child: Text('Ingredient not found'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(food),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(food),
                      const SizedBox(height: 32),
                      _buildNutritionInfo(food),
                      const SizedBox(height: 32),
                      if (food.description != null && food.description!.isNotEmpty) ...[
                        Text('Description', style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
                        const SizedBox(height: 12),
                        Text(
                          food.description!,
                          style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(FoodModel food) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
            ? Image.network(food.imageUrl!, fit: BoxFit.cover)
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildHeader(FoodModel food) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                food.name,
                style: AppTheme.bodyStyle.copyWith(fontSize: 28),
              ),
            ),
            if (food.healthScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Score ${food.healthScore}',
                      style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          food.categoryName ?? 'Raw Ingredient',
          style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNutritionInfo(FoodModel food) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nutrition Facts', style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text('Per 100g', style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNutrientItem('Calories', food.caloriesPer100g.toStringAsFixed(0), 'kcal', AppTheme.primary),
            _buildNutrientItem('Protein', food.proteinPer100g.toStringAsFixed(1), 'g', Colors.blue),
            _buildNutrientItem('Fat', food.fatPer100g.toStringAsFixed(1), 'g', Colors.orange),
            _buildNutrientItem('Carbs', food.carbsPer100g.toStringAsFixed(1), 'g', Colors.green),
          ],
        ),
        const SizedBox(height: 24),
        _buildDetailedNutrient('Fiber', food.fiberPer100g, 'g'),
        _buildDetailedNutrient('Sugar', food.sugarPer100g, 'g'),
        _buildDetailedNutrient('Sodium', food.sodiumMgPer100g, 'mg'),
      ],
    );
  }

  Widget _buildNutrientItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: AppTheme.bodyStyle.copyWith(color: color, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTheme.semiboldStyle.copyWith(fontSize: 12)),
        Text(unit, style: AppTheme.bodyStyle.copyWith(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildDetailedNutrient(String label, double? value, String unit) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyStyle),
          Text('${value.toStringAsFixed(1)} $unit', style: AppTheme.semiboldStyle),
        ],
      ),
    );
  }
}
