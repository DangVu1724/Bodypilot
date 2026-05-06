import 'package:core_shared/models/food_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_state.dart';
import 'package:mobile/presentation/widgets/skeleton.dart';

class FoodDetailScreen extends StatefulWidget {
  final String foodId;

  const FoodDetailScreen({super.key, required this.foodId});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<FoodCubit>().getFoodDetails(widget.foodId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FoodCubit, FoodState>(
        builder: (context, state) {
          if (state.status == FoodStatus.loading) {
            return const FoodDetailSkeleton();
          }

          if (state.status == FoodStatus.failure) {
            return Center(child: Text(state.errorMessage ?? 'Error loading food details'));
          }

          final food = state.selectedFood;
          if (food == null) {
            return const Center(child: Text('Food not found'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(food),
              SliverToBoxAdapter(child: _buildFoodInfo(food)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    labelColor: AppTheme.textPrimary,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: AppTheme.semiboldStyle,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Nutrition'),
                      Tab(text: 'Ingredients'),
                      Tab(text: 'Instructions'),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildNutritionTab(food), _buildIngredientsList(food), _buildInstructions(food)],
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
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: AppTheme.textPrimary),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: food.imageUrl != null
            ? Image.network(food.imageUrl!, fit: BoxFit.cover)
            : Container(
                color: AppTheme.surface,
                child: const Icon(Icons.fastfood, size: 100, color: AppTheme.textSecondary),
              ),
      ),
    );
  }

  Widget _buildFoodInfo(FoodModel food) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(food.name, style: AppTheme.headlineStyle.copyWith(fontSize: 24))),
              if (food.recipe?.cookingTimeMinutes != null)
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${food.recipe!.cookingTimeMinutes} Min',
                      style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (food.description != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.description!,
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                  maxLines: _isDescriptionExpanded ? null : 3,
                  overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                GestureDetector(
                  onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                  child: Text(
                    _isDescriptionExpanded ? 'View Less' : 'View More',
                    style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 14),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIngredientsList(FoodModel food) {
    final ingredients = food.recipe?.ingredients ?? [];
    if (ingredients.isEmpty) {
      return const Center(child: Text('No ingredients listed'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: ingredients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.restaurant, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(ingredient.foodName, style: AppTheme.semiboldStyle)),
              Text('${ingredient.quantityGrams}g', style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructions(FoodModel food) {
    final instructions = food.recipe?.instructions;
    if (instructions == null || instructions.isEmpty) {
      return const Center(child: Text('No instructions available'));
    }

    final steps = instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  if (index != steps.length - 1)
                    Expanded(child: Container(width: 2, color: AppTheme.primary.withOpacity(0.2))),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${index + 1}',
                        style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[index].trim(), style: AppTheme.bodyStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab(FoodModel food) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (food.healthScore != null) _buildHealthScore(food.healthScore!),
          const SizedBox(height: 24),
          Text('Macros per 100g', style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          _buildNutritionGrid(food),
          const SizedBox(height: 32),
          if (food.dietTags.isNotEmpty) ...[
            Text('Dietary Tags', style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: food.dietTags.map((tag) => _buildDietTag(tag.name)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthScore(int score) {
    Color scoreColor = score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  color: scoreColor,
                  backgroundColor: scoreColor.withOpacity(0.2),
                ),
              ),
              Text('$score', style: AppTheme.headlineStyle.copyWith(fontSize: 18, color: scoreColor)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health Score', style: AppTheme.semiboldStyle.copyWith(fontSize: 16)),
                Text(
                  'Based on nutritional density and ingredients.',
                  style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(FoodModel food) {
    final items = [
      _NutrientItem('Calories', '${food.caloriesPer100g}', 'kcal', Icons.local_fire_department_outlined),
      _NutrientItem('Protein', '${food.proteinPer100g}', 'g', Icons.egg_outlined),
      _NutrientItem('Carbs', '${food.carbsPer100g}', 'g', Icons.grain),
      _NutrientItem('Fats', '${food.fatPer100g}', 'g', Icons.pie_chart_outline),
      if (food.fiberPer100g != null) _NutrientItem('Fiber', '${food.fiberPer100g}', 'g', Icons.eco_outlined),
      if (food.sugarPer100g != null) _NutrientItem('Sugar', '${food.sugarPer100g}', 'g', Icons.opacity),
      if (food.sodiumMgPer100g != null)
        _NutrientItem('Sodium', '${food.sodiumMgPer100g}', 'mg', Icons.science_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.label, style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${item.value}${item.unit}', style: AppTheme.semiboldStyle.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDietTag(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Text(name, style: AppTheme.semiboldStyle.copyWith(fontSize: 12, color: AppTheme.primary)),
    );
  }
}

class _NutrientItem {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  _NutrientItem(this.label, this.value, this.unit, this.icon);
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
