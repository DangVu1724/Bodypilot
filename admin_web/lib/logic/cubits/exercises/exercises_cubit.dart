import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/admin_repository.dart';
import 'exercises_state.dart';

class ExercisesCubit extends Cubit<ExercisesState> {
  final AdminRepository adminRepository;

  ExercisesCubit({required this.adminRepository}) : super(ExercisesInitial());

  Future<void> fetchExercises({
    int page = 0,
    int size = 20,
    String? search,
    String? categoryId,
  }) async {
    emit(ExercisesLoading());
    try {
      final pageData = await adminRepository.getAllExercises(
        page: page,
        size: size,
        search: search,
        categoryId: categoryId,
      );
      emit(ExercisesSuccess(pageData, searchQuery: search, currentPage: page));
    } catch (e) {
      final String msg = e.toString().replaceAll('Exception: ', '');
      emit(ExercisesFailure(msg));
    }
  }

  Future<bool> deleteExercise(String id) async {
    try {
      await adminRepository.deleteExercise(id);
      if (state is ExercisesSuccess) {
        final currentState = state as ExercisesSuccess;
        fetchExercises(page: currentState.currentPage, search: currentState.searchQuery);
      }
      return true;
    } catch (e) {
      emit(ExercisesFailure('Lỗi xóa bài tập: $e'));
      return false;
    }
  }
}
