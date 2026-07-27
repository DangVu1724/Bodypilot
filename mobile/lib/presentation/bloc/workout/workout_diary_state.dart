import 'package:core_shared/core_shared.dart';
import 'package:equatable/equatable.dart';

enum WorkoutDiaryStatus { initial, loading, success, failure }

class WorkoutDiaryState extends Equatable {
  final WorkoutDiaryStatus status;
  final Map<String, DailyWorkoutModel> dailyWorkouts;
  final DateTime? selectedDate;
  final String? errorMessage;

  const WorkoutDiaryState({
    this.status = WorkoutDiaryStatus.initial,
    this.dailyWorkouts = const {},
    this.selectedDate,
    this.errorMessage,
  });

  WorkoutDiaryState copyWith({
    WorkoutDiaryStatus? status,
    Map<String, DailyWorkoutModel>? dailyWorkouts,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return WorkoutDiaryState(
      status: status ?? this.status,
      dailyWorkouts: dailyWorkouts ?? this.dailyWorkouts,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, dailyWorkouts, selectedDate, errorMessage];
}
