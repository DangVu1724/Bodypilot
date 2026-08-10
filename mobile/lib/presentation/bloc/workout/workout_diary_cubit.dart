import 'package:core_shared/core_shared.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/repositories/workout_diary_repository.dart';
import 'package:mobile/data/services/push_notification_service.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_state.dart';

class WorkoutDiaryCubit extends Cubit<WorkoutDiaryState> {
  final WorkoutDiaryRepository _repository;

  WorkoutDiaryCubit(this._repository) : super(const WorkoutDiaryState());

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
    final dateStr = _formatDate(date);
    if (!state.dailyWorkouts.containsKey(dateStr)) {
      fetchDailyWorkout(date);
    }
  }

  Future<void> fetchDailyWorkout(DateTime date) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      final dailyWorkout = await _repository.getDailyWorkout(date);
      
      final updatedDailyWorkouts = Map<String, DailyWorkoutModel>.from(state.dailyWorkouts);
      updatedDailyWorkouts[_formatDate(date)] = dailyWorkout;

      emit(state.copyWith(
        status: WorkoutDiaryStatus.success,
        dailyWorkouts: updatedDailyWorkouts,
      ));

      // If checking today's workout and there are pending exercise items, schedule dynamic reminder
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        if (dailyWorkout.workoutItems.isNotEmpty && !dailyWorkout.isCompleted) {
          final workoutName = dailyWorkout.note ?? 
              dailyWorkout.workoutItems.map((e) => e.exerciseNameSnapshot).where((name) => name.isNotEmpty).take(2).join(', ');
          if (workoutName.isNotEmpty) {
            PushNotificationService.scheduleTodayWorkoutReminder(
              workoutName: workoutName,
            );
          }
        }
      }
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutDiaryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> fetchWeeklyWorkouts(DateTime startDate, DateTime endDate) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      final dailyWorkoutsList = await _repository.getDailyWorkoutRange(startDate, endDate);
      
      final updatedDailyWorkouts = Map<String, DailyWorkoutModel>.from(state.dailyWorkouts);
      for (var workout in dailyWorkoutsList) {
        updatedDailyWorkouts[_formatDate(workout.date)] = workout;
      }

      emit(state.copyWith(
        status: WorkoutDiaryStatus.success,
        dailyWorkouts: updatedDailyWorkouts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutDiaryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> addExerciseToDiary({
    required DateTime date,
    required Map<String, dynamic> itemData,
  }) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      final updatedDailyWorkout = await _repository.addExerciseToDiary(
        date: date,
        itemData: itemData,
      );

      final updatedDailyWorkouts = Map<String, DailyWorkoutModel>.from(state.dailyWorkouts);
      updatedDailyWorkouts[_formatDate(date)] = updatedDailyWorkout;

      emit(state.copyWith(
        status: WorkoutDiaryStatus.success,
        dailyWorkouts: updatedDailyWorkouts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutDiaryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> removeExerciseFromDiary(String itemId, DateTime date) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      await _repository.removeExerciseFromDiary(itemId);
      await fetchDailyWorkout(date);
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutDiaryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateExerciseInDiary(String itemId, Map<String, dynamic> itemData, DateTime date) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      await _repository.updateExerciseInDiary(itemId, itemData);
      await fetchDailyWorkout(date);
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutDiaryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> clearDay(DateTime date) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      await _repository.clearDay(date);
      
      final updatedDailyWorkouts = Map<String, DailyWorkoutModel>.from(state.dailyWorkouts);
      updatedDailyWorkouts.remove(_formatDate(date));

      emit(state.copyWith(
        status: WorkoutDiaryStatus.success,
        dailyWorkouts: updatedDailyWorkouts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutDiaryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateDailyNote(DateTime date, String note) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      await _repository.updateDailyNote(date, note);
      await fetchDailyWorkout(date);
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutDiaryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> toggleExerciseStatus(String itemId, bool isCompleted, DateTime date) async {
    emit(state.copyWith(status: WorkoutDiaryStatus.loading));
    try {
      final updatedDailyWorkout = await _repository.updateExerciseStatus(itemId, isCompleted);
      final updatedDailyWorkouts = Map<String, DailyWorkoutModel>.from(state.dailyWorkouts);
      updatedDailyWorkouts[_formatDate(date)] = updatedDailyWorkout;

      if (isCompleted) {
        final items = updatedDailyWorkout.workoutItems;
        if (items.isNotEmpty && items.every((item) => item.isCompleted)) {
          PushNotificationService.showWorkoutCompletedNotification(
            totalCaloriesBurned: updatedDailyWorkout.totalCaloriesBurned,
          );
        }
      }

      emit(state.copyWith(status: WorkoutDiaryStatus.success, dailyWorkouts: updatedDailyWorkouts));
    } catch (e) {
      emit(state.copyWith(status: WorkoutDiaryStatus.failure, errorMessage: e.toString()));
    }
  }
}
