import 'package:equatable/equatable.dart';
import '../../../data/models/workout_category_model.dart';

abstract class WorkoutCategoryState extends Equatable {
  const WorkoutCategoryState();

  @override
  List<Object?> get props => [];
}

class WorkoutCategoryInitial extends WorkoutCategoryState {}

class WorkoutCategoryLoading extends WorkoutCategoryState {}

class WorkoutCategoryLoaded extends WorkoutCategoryState {
  final List<WorkoutCategoryModel> categories;

  const WorkoutCategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class WorkoutCategoryError extends WorkoutCategoryState {
  final String message;

  const WorkoutCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
