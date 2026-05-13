import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/exercise_repository.dart';
import 'workout_category_state.dart';

class WorkoutCategoryCubit extends Cubit<WorkoutCategoryState> {
  final ExerciseRepository _repository;

  WorkoutCategoryCubit(this._repository) : super(WorkoutCategoryInitial());

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && state is WorkoutCategoryLoaded) return;

    if (!isClosed) emit(WorkoutCategoryLoading());
    try {
      final categories = await _repository.getWorkoutCategories();
      if (!isClosed) emit(WorkoutCategoryLoaded(categories));
    } catch (e) {
      if (!isClosed) emit(WorkoutCategoryError(e.toString()));
    }
  }

  void clear() {
    emit(WorkoutCategoryInitial());
  }
}
