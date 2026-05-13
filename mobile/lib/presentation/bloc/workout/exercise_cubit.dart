import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/exercise_repository.dart';
import 'exercise_state.dart';

class ExerciseCubit extends Cubit<ExerciseState> {
  final ExerciseRepository _repository;

  ExerciseCubit(this._repository) : super(ExerciseInitial());

  Future<void> fetchStrengthExercises({bool forceRefresh = false}) async {
    if (!forceRefresh && state is ExerciseLoaded) return;
    
    if (!isClosed) emit(ExerciseLoading());
    try {
      final response = await _repository.searchExercises(
        size: 10,
      );
      if (!isClosed) emit(ExerciseLoaded(response.content));
    } catch (e) {
      if (!isClosed) emit(ExerciseError(e.toString()));
    }
  }

  Future<void> fetchExercisesByCategory(String categoryId) async {
    if (!isClosed) emit(ExerciseLoading());
    try {
      final response = await _repository.searchExercises(
        categoryId: categoryId,
        size: 20,
      );
      if (!isClosed) emit(ExerciseLoaded(response.content));
    } catch (e) {
      if (!isClosed) emit(ExerciseError(e.toString()));
    }
  }

  void clear() {
    emit(ExerciseInitial());
  }
}
