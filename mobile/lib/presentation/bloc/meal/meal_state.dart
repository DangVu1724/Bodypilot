import 'package:core_shared/models/daily_eating_model.dart';
import 'package:equatable/equatable.dart';

enum MealStatus { initial, loading, success, failure }

class MealState extends Equatable {
  final MealStatus status;
  final Map<String, DailyEatingModel> dailyEatings;
  final DateTime? selectedDate;
  final String? errorMessage;

  const MealState({
    this.status = MealStatus.initial,
    this.dailyEatings = const {},
    this.selectedDate,
    this.errorMessage,
  });

  MealState copyWith({
    MealStatus? status,
    Map<String, DailyEatingModel>? dailyEatings,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return MealState(
      status: status ?? this.status,
      dailyEatings: dailyEatings ?? this.dailyEatings,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, dailyEatings, selectedDate, errorMessage];
}