import 'package:core_shared/models/exercise_model.dart';
import 'package:equatable/equatable.dart';

abstract class ExerciseState extends Equatable {
  const ExerciseState();

  @override
  List<Object?> get props => [];
}

class ExerciseInitial extends ExerciseState {}

class ExerciseLoading extends ExerciseState {}

class ExerciseLoaded extends ExerciseState {
  final List<ExerciseModel> exercises;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;

  const ExerciseLoaded({
    required this.exercises,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.currentPage = 0,
  });

  ExerciseLoaded copyWith({
    List<ExerciseModel>? exercises,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
  }) {
    return ExerciseLoaded(
      exercises: exercises ?? this.exercises,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [exercises, hasMore, isLoadingMore, currentPage];
}

class ExerciseError extends ExerciseState {
  final String message;

  const ExerciseError(this.message);

  @override
  List<Object?> get props => [message];
}
