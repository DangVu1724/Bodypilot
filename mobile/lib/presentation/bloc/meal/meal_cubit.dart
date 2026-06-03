import 'package:core_shared/models/daily_eating_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';
import 'package:mobile/presentation/bloc/meal/meal_state.dart';

class MealCubit extends Cubit<MealState> {
  final NutritionDiaryRepository _repository;

  MealCubit(this._repository) : super(const MealState());

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
    final dateStr = _formatDate(date);
    if (!state.dailyEatings.containsKey(dateStr)) {
      fetchDailyEating(date);
    }
  }

  Future<void> fetchDailyEating(DateTime date) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      final dailyEating = await _repository.getDailyEating(date);
      
      final updatedDailyEatings = Map<String, DailyEatingModel>.from(state.dailyEatings);
      updatedDailyEatings[_formatDate(date)] = dailyEating;

      emit(state.copyWith(
        status: MealStatus.success,
        dailyEatings: updatedDailyEatings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MealStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> fetchWeeklyEating(DateTime startDate, DateTime endDate) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      final dailyEatingsList = await _repository.getDailyEatingRange(startDate, endDate);
      
      final updatedDailyEatings = Map<String, DailyEatingModel>.from(state.dailyEatings);
      for (var eating in dailyEatingsList) {
        updatedDailyEatings[_formatDate(eating.date)] = eating;
      }

      emit(state.copyWith(
        status: MealStatus.success,
        dailyEatings: updatedDailyEatings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MealStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> addFoodToDiary({
    required DateTime date,
    required MealType mealType,
    required Map<String, dynamic> itemData,
  }) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      final updatedDailyEating = await _repository.addFoodToDiary(
        date: date,
        mealType: mealType,
        itemData: itemData,
      );

      final updatedDailyEatings = Map<String, DailyEatingModel>.from(state.dailyEatings);
      updatedDailyEatings[_formatDate(date)] = updatedDailyEating;

      emit(state.copyWith(
        status: MealStatus.success,
        dailyEatings: updatedDailyEatings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MealStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> removeFoodFromDiary(String itemId, DateTime date) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      await _repository.removeFoodFromDiary(itemId);
      await fetchDailyEating(date);
    } catch (e) {
      emit(state.copyWith(
        status: MealStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> clearMeal(DateTime date, MealType mealType) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      await _repository.clearMeal(date, mealType);
      await fetchDailyEating(date);
    } catch (e) {
      emit(state.copyWith(
        status: MealStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> clearDay(DateTime date) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      await _repository.clearDay(date);
      
      final updatedDailyEatings = Map<String, DailyEatingModel>.from(state.dailyEatings);
      updatedDailyEatings.remove(_formatDate(date));

      emit(state.copyWith(
        status: MealStatus.success,
        dailyEatings: updatedDailyEatings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MealStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateDailyNote(DateTime date, String note) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      await _repository.updateDailyNote(date, note);
      await fetchDailyEating(date);
    } catch (e) {
      emit(state.copyWith(
        status: MealStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> toggleMealItemStatus(String itemId, bool isEaten, DateTime date) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      final updatedDailyEating = await _repository.updateMealItemStatus(itemId, isEaten);
      final updatedDailyEatings = Map<String, DailyEatingModel>.from(state.dailyEatings);
      updatedDailyEatings[_formatDate(date)] = updatedDailyEating;
      emit(state.copyWith(status: MealStatus.success, dailyEatings: updatedDailyEatings));
    } catch (e) {
      emit(state.copyWith(status: MealStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> toggleMealSlotStatus(String slotId, bool isEaten, DateTime date) async {
    emit(state.copyWith(status: MealStatus.loading));
    try {
      final updatedDailyEating = await _repository.updateMealSlotStatus(slotId, isEaten);
      final updatedDailyEatings = Map<String, DailyEatingModel>.from(state.dailyEatings);
      updatedDailyEatings[_formatDate(date)] = updatedDailyEating;
      emit(state.copyWith(status: MealStatus.success, dailyEatings: updatedDailyEatings));
    } catch (e) {
      emit(state.copyWith(status: MealStatus.failure, errorMessage: e.toString()));
    }
  }
}
