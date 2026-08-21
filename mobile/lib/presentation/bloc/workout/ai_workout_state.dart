import 'package:equatable/equatable.dart';
import 'package:core_shared/models/daily_workout_model.dart';

abstract class AiWorkoutState extends Equatable {
  const AiWorkoutState();

  @override
  List<Object?> get props => [];
}

class AiWorkoutInitial extends AiWorkoutState {}

class AiWorkoutLoading extends AiWorkoutState {}

class AiWorkoutSuccess extends AiWorkoutState {
  final List<DailyWorkoutModel> suggestions;
  final bool isFallback;

  const AiWorkoutSuccess({
    required this.suggestions,
    required this.isFallback,
  });

  @override
  List<Object?> get props => [suggestions, isFallback];
}

class AiWorkoutError extends AiWorkoutState {
  final String message;

  const AiWorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
