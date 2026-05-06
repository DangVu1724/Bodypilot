import 'package:core_shared/models/food_model.dart';
import 'package:equatable/equatable.dart';

enum FoodListStatus { initial, loading, success, failure }

class FoodListState extends Equatable {
  final FoodListStatus status;
  final List<FoodModel> foods;
  final String? selectedCategoryId;
  final String errorMessage;

  const FoodListState({
    this.status = FoodListStatus.initial,
    this.foods = const [],
    this.selectedCategoryId,
    this.errorMessage = '',
  });

  FoodListState copyWith({
    FoodListStatus? status,
    List<FoodModel>? foods,
    String? selectedCategoryId,
    String? errorMessage,
  }) {
    // Note: We use a special pattern for selectedCategoryId to allow nullification.
    // However, since Dart doesn't support an explicit 'undefined' value,
    // we assume if it's passed it should override, but usually it's nullable.
    // A better approach for nullable fields in copyWith is a wrapper class, 
    // but for simplicity we will just assume if we want to clear it we can pass a specific value or handle it in the cubit.
    // Actually, let's just make it a positional or explicitly handle null.
    // We will just do a standard copyWith. To clear it, we might just pass an empty string and convert back to null in the getter if needed, but let's just use it simply.
    // Wait, the standard way to clear a nullable value in copyWith without complex wrappers:
    return FoodListState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      // If we need to explicitly set selectedCategoryId to null, we will manage that in the cubit.
      selectedCategoryId: selectedCategoryId, 
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Helper method to explicitly update selectedCategoryId even if it's null
  FoodListState copyWithCategory({
    FoodListStatus? status,
    List<FoodModel>? foods,
    required String? selectedCategoryId,
    String? errorMessage,
  }) {
    return FoodListState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      selectedCategoryId: selectedCategoryId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, foods, selectedCategoryId, errorMessage];
}
