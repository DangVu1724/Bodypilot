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
      if (!isClosed) {
        emit(ExerciseLoaded(
          exercises: response.content,
          totalElements: response.totalElements,
          hasMore: !response.last,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(ExerciseError(_formatErrorMessage(e)));
    }
  }

  Future<void> fetchExercisesByCategory(String categoryId, {bool forceRefresh = false}) async {
    if (!isClosed) emit(ExerciseLoading());
    try {
      final response = await _repository.searchExercises(
        categoryId: categoryId,
        page: 0,
        size: 20,
        forceRefresh: forceRefresh,
      );
      if (!isClosed) {
        emit(ExerciseLoaded(
          exercises: response.content,
          totalElements: response.totalElements,
          hasMore: !response.last && response.content.length >= 20,
          currentPage: 0,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(ExerciseError(_formatErrorMessage(e)));
    }
  }

  String _formatErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('DioException') || str.contains('SocketException') || str.contains('connection error') || str.contains('Failed to connect') || str.contains('NetworkException')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra lại Wifi/4G.';
    }
    return 'Không thể tải danh sách bài tập. Vui lòng thử lại sau.';
  }

  Future<void> loadMoreExercises(String categoryId) async {
    final currentState = state;
    if (currentState is! ExerciseLoaded || !currentState.hasMore || currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final response = await _repository.searchExercises(
        categoryId: categoryId,
        page: nextPage,
        size: 20,
      );

      final newExercises = List.of(currentState.exercises)..addAll(response.content);
      final isLast = response.last || response.content.isEmpty || response.content.length < 20;

      if (!isClosed) {
        emit(currentState.copyWith(
          exercises: newExercises,
          totalElements: response.totalElements,
          hasMore: !isLast,
          isLoadingMore: false,
          currentPage: nextPage,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  void clear() {
    emit(ExerciseInitial());
  }
}
