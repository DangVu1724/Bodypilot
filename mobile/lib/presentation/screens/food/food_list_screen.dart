import 'package:core_shared/models/food_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_state.dart';
import 'package:mobile/presentation/bloc/food_list/food_list_cubit.dart';
import 'package:mobile/presentation/bloc/food_list/food_list_state.dart';
import 'package:mobile/presentation/widgets/skeleton.dart';

class FoodListScreen extends StatefulWidget {
  final String type; // 'DISH' or 'INGREDIENT'

  const FoodListScreen({super.key, required this.type});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  void _loadFoods() {
    context.read<FoodListCubit>().searchFoods(
      type: widget.type,
      query: _searchController.text,
      categoryId: context.read<FoodListCubit>().state.selectedCategoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'DISH' ? 'All Dishes' : 'All Ingredients';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: BlocBuilder<FoodListCubit, FoodListState>(
              builder: (context, state) {
                final foods = state.foods;

                Widget content;
                if (state.status == FoodListStatus.loading) {
                  content = _buildSkeleton();
                } else if (foods.isEmpty) {
                  content = const Center(child: Text('No items found'));
                } else {
                  content = widget.type == 'DISH' ? _buildDishList(foods) : _buildIngredientGrid(foods);
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey<int>(state.status == FoodListStatus.loading ? 0 : 1),
                    child: content,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar Design
          Container(
            height: 55,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(28)),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _loadFoods(),
              decoration: InputDecoration(
                hintText: 'Search delicious ${widget.type.toLowerCase()}s...',
                hintStyle: AppTheme.bodyStyle.copyWith(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary, // Giả sử màu chính của bạn
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Title
          Text("Categories", style: AppTheme.semiboldStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 12),

          _buildCategoryFilters(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, globalState) {
        final filteredCategories = globalState.categories
            .where((c) => c.appliesTo == widget.type || c.appliesTo == 'BOTH')
            .toList();

        return BlocBuilder<FoodListCubit, FoodListState>(
          builder: (context, listState) {
            return SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredCategories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : filteredCategories[index - 1];
                  final isSelected = listState.selectedCategoryId == category?.id;

                  return GestureDetector(
                    onTap: () {
                      context.read<FoodListCubit>().selectCategory(
                        type: widget.type,
                        categoryId: category?.id,
                        query: _searchController.text,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey[300]!),
                      ),
                      child: Text(
                        isAll ? 'All' : category!.name,
                        style: AppTheme.semiboldStyle.copyWith(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDishList(List<FoodModel> foods) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _DishListItem(food: food),
        );
      },
    );
  }

  Widget _buildIngredientGrid(List<FoodModel> foods) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _IngredientGridItem(food: food);
      },
    );
  }

  Widget _buildSkeleton() {
    return widget.type == 'DISH'
        ? ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Skeleton(width: double.infinity, height: 180, borderRadius: 24),
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) =>
                const Skeleton(width: double.infinity, height: double.infinity, borderRadius: 20),
          );
  }
}

class _DishListItem extends StatelessWidget {
  final FoodModel food;

  const _DishListItem({required this.food});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.foodDetail, arguments: food.id),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey.shade100, // Fallback color
        ),
        child: Stack(
          children: [
            // Background image with error builder
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                    ? Image.network(
                        food.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.restaurant, color: Colors.grey.shade300, size: 60),
                          );
                        },
                      )
                    : Center(
                        child: Icon(Icons.restaurant, color: Colors.grey.shade300, size: 60),
                      ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(food.name, style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${food.caloriesPer100g.toStringAsFixed(0)}kcal',
                        style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('•', style: AppTheme.bodyStyle.copyWith(color: Colors.white70)),
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
      ),
    );
  }
}

class _IngredientGridItem extends StatelessWidget {
  final FoodModel food;

  const _IngredientGridItem({required this.food});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.ingredientDetail, arguments: food.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                    ? Image.network(
                        food.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Icon(Icons.restaurant, color: Colors.grey.shade300, size: 40),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Icon(Icons.restaurant, color: Colors.grey.shade300, size: 40),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.semiboldStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.caloriesPer100g.toStringAsFixed(0)} kcal/100g',
                    style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
