import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/food_repository.dart';
import 'food_list_state.dart';
import 'package:core_shared/models/food_model.dart';

class FoodListCubit extends Cubit<FoodListState> {
  final FoodRepository _foodRepository;

  static final Map<String, List<FoodModel>> _cache = {};

  FoodListCubit(this._foodRepository) : super(const FoodListState());

  bool _isFoodMatchingType(FoodModel f, String type) {
    final targetType = type.toUpperCase();
    final fType = f.type.toUpperCase();
    final catAppliesTo = f.category?.appliesTo.toUpperCase();

    final bool matchType = (fType == targetType || fType == 'BOTH');
    final bool matchCategory = (catAppliesTo == null || catAppliesTo == targetType || catAppliesTo == 'BOTH');

    return matchType && matchCategory;
  }

  void initializeWithCache({required List<FoodModel> initialFoods, required String type}) {
    final filtered = initialFoods.where((f) => _isFoodMatchingType(f, type)).toList();

    if (filtered.isNotEmpty) {
      emit(state.copyWithCategory(
        status: FoodListStatus.success,
        foods: filtered,
        selectedCategoryId: '',
        page: 0,
        hasReachedMax: false,
      ));

      final cacheKey = '${type}_ALL_';
      _cache[cacheKey] = filtered;
    }
  }

  Future<void> searchFoods({
    required String type,
    String query = '',
    String? categoryId,
  }) async {
    final cacheKey = '${type}_${categoryId ?? 'ALL'}_$query';

    emit(state.copyWithCategory(
      status: FoodListStatus.loading,
      selectedCategoryId: categoryId,
      page: 0,
      hasReachedMax: false,
      isLoadingMore: false,
    ));

    if (_cache.containsKey(cacheKey)) {
      emit(
        state.copyWithCategory(
          status: FoodListStatus.success,
          foods: _cache[cacheKey]!,
          selectedCategoryId: categoryId,
          page: 0,
          hasReachedMax: true,
        ),
      );
      return;
    }

    try {
      final response = await _foodRepository.searchFoods(
        query,
        categoryId: categoryId,
        type: type,
        page: 0,
        size: 30,
      );

      final filteredFoods = response.content.where((f) => _isFoodMatchingType(f, type)).toList();
      _cache[cacheKey] = filteredFoods;

      emit(
        state.copyWithCategory(
          status: FoodListStatus.success,
          foods: filteredFoods,
          selectedCategoryId: categoryId,
          page: 0,
          hasReachedMax: response.last,
        ),
      );
    } catch (e) {
      emit(
        state.copyWithCategory(
          status: FoodListStatus.failure,
          selectedCategoryId: categoryId,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Tải thêm trang tiếp theo khi cuộn xuống dưới cùng (Load More)
  Future<void> loadMoreFoods({
    required String type,
    String query = '',
  }) async {
    if (state.hasReachedMax || state.isLoadingMore || state.status != FoodListStatus.success) return;

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.page + 1;

    try {
      final response = await _foodRepository.searchFoods(
        query,
        categoryId: state.selectedCategoryId,
        type: type,
        page: nextPage,
        size: 30,
      );

      final filteredFoods = response.content.where((f) => _isFoodMatchingType(f, type)).toList();

      emit(state.copyWith(
        status: FoodListStatus.success,
        foods: [...state.foods, ...filteredFoods],
        page: nextPage,
        hasReachedMax: response.last || filteredFoods.isEmpty,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void selectCategory({required String type, required String? categoryId, String query = ''}) {
    if (state.selectedCategoryId == categoryId && state.status == FoodListStatus.success) return;
    searchFoods(type: type, categoryId: categoryId, query: query);
  }
}
