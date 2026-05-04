import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/exercise_repository.dart';
import 'exercise_state.dart';

class ExerciseCubit extends Cubit<ExerciseState> {
  final ExerciseRepository _repository;

  ExerciseCubit(this._repository) : super(ExerciseInitial());

  Future<void> fetchStrengthExercises() async {
    emit(ExerciseLoading());
    try {
      final response = await _repository.searchExercises(
        workoutType: 'STRENGTH',
        size: 10,
      );
      emit(ExerciseLoaded(response.content));
    } catch (e) {
      emit(ExerciseError(e.toString()));
    }
  }

  Future<void> fetchExercisesByCategory(String categoryId) async {
    emit(ExerciseLoading());
    try {
      final response = await _repository.searchExercises(
        categoryId: categoryId,
        size: 20,
      );
      emit(ExerciseLoaded(response.content));
    } catch (e) {
      emit(ExerciseError(e.toString()));
    }
  }

  void clear() {
    emit(ExerciseInitial());
  }
}
