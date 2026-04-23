import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/models/food_model.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_state.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/theme/app_theme.dart';

class NutrientTag extends StatelessWidget {
  final String value;
  final String label;

  const NutrientTag({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.2)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 10),
          ),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class DietCard extends StatelessWidget {
  final FoodModel food;

  const DietCard({
    super.key,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
              ? NetworkImage(food.imageUrl!)
              : const AssetImage('assets/images/fruit.png') as ImageProvider,
          fit: BoxFit.cover,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NutrientTag(value: '${food.proteinPer100g.toStringAsFixed(0)}g', label: 'Protein'),
                    const SizedBox(width: 8),
                    NutrientTag(value: '${food.fatPer100g.toStringAsFixed(0)}g', label: 'Fat'),
                  ],
                ),
                const Spacer(),
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${food.caloriesPer100g.toStringAsFixed(0)}kcal',
                      style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: Colors.white70)),
                    ),
                    Text(
                      '${food.recipe?.cookingTimeMinutes ?? 0} mins',
                      style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DietSection extends StatelessWidget {
  const DietSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, state) {
        final dishes = state.foods.where((f) => f.type == 'DISH').toList();
        Logger().d('Found ${dishes.length} dishes');
        
        if (state.status == FoodStatus.loading && dishes.isEmpty) {
          return const SizedBox(
            height: 230,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (dishes.isEmpty) {
          return const SizedBox(
            height: 230,
            child: Center(child: Text('No dishes available')),
          );
        }
        
        return SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              return DietCard(food: dishes[index]);
            },
          ),
        );
      },
    );
  }
}
