import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/food_repository.dart';
import 'food_state.dart';

class FoodCubit extends Cubit<FoodState> {
  final FoodRepository foodRepository;

  FoodCubit(this.foodRepository) : super(const FoodState());

  Future<void> init() async {
    await loadCategories();
    await searchFoods();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await foodRepository.getFoodCategories();
      emit(state.copyWith(categories: categories));
    } catch (e) {
      emit(state.copyWith(
        status: FoodStatus.failure,
        errorMessage: 'Failed to load categories',
      ));
    }
  }

  Future<void> searchFoods({
    String query = '',
    String? categoryId,
    int page = 0,
    int size = 60,
  }) async {
    emit(state.copyWith(
      status: FoodStatus.loading,
      selectedCategoryId: categoryId,
    ));

    try {
      final response = await foodRepository.searchFoods(
        query,
        categoryId: categoryId,
        page: page,
        size: size,
      );

      emit(state.copyWith(
        status: FoodStatus.success,
        foods: page == 0 ? response.content : [...state.foods, ...response.content],
        currentPage: response.pageNumber,
        totalPages: response.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FoodStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> getFoodDetails(String foodId) async {
    emit(state.copyWith(status: FoodStatus.loading));
    try {
      final food = await foodRepository.getFoodDetails(foodId);
      emit(state.copyWith(
        status: FoodStatus.success,
        selectedFood: food,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FoodStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) return;
    searchFoods(categoryId: categoryId);
  }

  void loadNextPage({String query = ''}) {
    if (state.status != FoodStatus.loading && state.currentPage < state.totalPages - 1) {
      searchFoods(
        query: query,
        categoryId: state.selectedCategoryId,
        page: state.currentPage + 1,
      );
    }
  }

  void clear() {
    emit(const FoodState());
  }
}
