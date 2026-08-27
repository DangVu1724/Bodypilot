import 'package:core_shared/models/food_model.dart';
import 'package:equatable/equatable.dart';

enum FoodListStatus { initial, loading, success, failure }

class FoodListState extends Equatable {
  final FoodListStatus status;
  final List<FoodModel> foods;
  final String? selectedCategoryId;
  final int page;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String errorMessage;

  const FoodListState({
    this.status = FoodListStatus.initial,
    this.foods = const [],
    this.selectedCategoryId,
    this.page = 0,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.errorMessage = '',
  });

  FoodListState copyWith({
    FoodListStatus? status,
    List<FoodModel>? foods,
    String? selectedCategoryId,
    int? page,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return FoodListState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  FoodListState copyWithCategory({
    FoodListStatus? status,
    List<FoodModel>? foods,
    required String? selectedCategoryId,
    int? page,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return FoodListState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      selectedCategoryId: selectedCategoryId,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, foods, selectedCategoryId, page, hasReachedMax, isLoadingMore, errorMessage];
}
