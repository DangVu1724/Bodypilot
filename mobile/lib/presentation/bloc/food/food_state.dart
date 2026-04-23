import 'package:equatable/equatable.dart';
import 'package:mobile/data/models/food_category_model.dart';
import 'package:mobile/data/models/food_model.dart';

enum FoodStatus { initial, loading, success, failure }

class FoodState extends Equatable {
  final FoodStatus status;
  final List<FoodModel> foods;
  final List<FoodCategoryModel> categories;
  final String? selectedCategoryId;
  final int currentPage;
  final int totalPages;
  final String? errorMessage;
  final FoodModel? selectedFood;

  const FoodState({
    this.status = FoodStatus.initial,
    this.foods = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.currentPage = 0,
    this.totalPages = 0,
    this.errorMessage,
    this.selectedFood,
  });

  FoodState copyWith({
    FoodStatus? status,
    List<FoodModel>? foods,
    List<FoodCategoryModel>? categories,
    String? selectedCategoryId,
    int? currentPage,
    int? totalPages,
    String? errorMessage,
    FoodModel? selectedFood,
  }) {
    return FoodState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedFood: selectedFood ?? this.selectedFood,
    );
  }

  @override
  List<Object?> get props => [
        status,
        foods,
        categories,
        selectedCategoryId,
        currentPage,
        totalPages,
        errorMessage,
        selectedFood,
      ];
}
