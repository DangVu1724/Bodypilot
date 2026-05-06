import 'package:core_shared/models/food_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_state.dart';
import 'package:mobile/presentation/screens/home/widgets/section_header.dart';

class BrowseMealsList extends StatelessWidget {
  const BrowseMealsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Browse Meals',
          onSeeAll: () => Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.foodList, arguments: 'DISH'),
        ),
        const SizedBox(height: 16),
        BlocBuilder<FoodCubit, FoodState>(
          builder: (context, state) {
            final dishes = state.foods.where((f) => f.type == 'DISH').toList();
            if (dishes.isEmpty) {
              return const Center(
                child: Padding(padding: EdgeInsets.all(20.0), child: Text('No meals found.')),
              );
            }

            // Get 5 random dishes
            final randomDishes = List<FoodModel>.from(dishes)..shuffle();
            final displayDishes = randomDishes.take(5).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayDishes.length,
              itemBuilder: (context, index) {
                final food = displayDishes[index];
                return GestureDetector(
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.foodDetail, arguments: food.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: AppTheme.headlineStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.local_fire_department, size: 14, color: Colors.red.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${food.caloriesPer100g.toStringAsFixed(0)}kcal',
                                    style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('•', style: AppTheme.bodyStyle.copyWith(color: Colors.grey)),
                                  ),
                                  Icon(Icons.health_and_safety, size: 14, color: Colors.amber.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${food.healthScore}',
                                    style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('•', style: AppTheme.bodyStyle.copyWith(color: Colors.grey)),
                                  ),
                                  Icon(Icons.access_time_filled, size: 14, color: Colors.blue.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${food.recipe?.cookingTimeMinutes ?? 15}min',
                                    style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  food.imageUrl!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey.shade100,
                                      child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 32),
                                    );
                                  },
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade100,
                                  child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 32),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
