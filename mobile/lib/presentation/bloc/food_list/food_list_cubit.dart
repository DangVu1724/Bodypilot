import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/food_repository.dart';
import 'food_list_state.dart';
import 'package:core_shared/models/food_model.dart';

class FoodListCubit extends Cubit<FoodListState> {
  final FoodRepository _foodRepository;
  
  // Cache to store loaded foods. Key format: "{type}_{categoryId}_{query}"
  static final Map<String, List<FoodModel>> _cache = {};

  FoodListCubit(this._foodRepository) : super(const FoodListState());

  Future<void> searchFoods({
    required String type, // 'DISH' or 'INGREDIENT'
    String query = '',
    String? categoryId,
  }) async {
    // Generate cache key
    final cacheKey = '${type}_${categoryId ?? 'ALL'}_$query';

    // Update state to loading and set new category id instantly for UI response
    emit(state.copyWithCategory(
      status: FoodListStatus.loading,
      selectedCategoryId: categoryId,
    ));

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      emit(state.copyWithCategory(
        status: FoodListStatus.success,
        foods: _cache[cacheKey]!,
        selectedCategoryId: categoryId,
      ));
      // Optionally, we could still fetch in the background to update cache,
      // but for instant feedback and avoiding unnecessary calls, we return here.
      return;
    }

    try {
      final response = await _foodRepository.searchFoods(
        query,
        categoryId: categoryId,
        page: 0,
        size: 100, // Fetch a large chunk for the list to avoid immediate pagination logic for now
      );

      // Filter by type on the client side since the API might not support it
      final filteredFoods = response.content.where((f) => f.type == type).toList();

      // Save to cache
      _cache[cacheKey] = filteredFoods;

      emit(state.copyWithCategory(
        status: FoodListStatus.success,
        foods: filteredFoods,
        selectedCategoryId: categoryId,
      ));
    } catch (e) {
      emit(state.copyWithCategory(
        status: FoodListStatus.failure,
        selectedCategoryId: categoryId,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectCategory({
    required String type,
    required String? categoryId,
    String query = '',
  }) {
    if (state.selectedCategoryId == categoryId && state.status == FoodListStatus.success) return;
    searchFoods(type: type, categoryId: categoryId, query: query);
  }
}
