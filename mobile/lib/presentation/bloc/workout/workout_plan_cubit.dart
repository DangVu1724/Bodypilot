import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_plan_state.dart';

class WorkoutPlanCubit extends Cubit<WorkoutPlanState> {
  final WorkoutRepository _workoutRepository;

  WorkoutPlanCubit(this._workoutRepository) : super(WorkoutPlanInitial());

  Future<void> fetchPlans({bool forceRefresh = false}) async {
    if (!forceRefresh && state is WorkoutPlanLoaded) return;
    
    if (!isClosed) emit(WorkoutPlanLoading());
    try {
      final plans = await _workoutRepository.getAllPlans();
      if (!isClosed) emit(WorkoutPlanLoaded(plans));
    } catch (e) {
      if (!isClosed) emit(WorkoutPlanError(_formatErrorMessage(e)));
    }
  }

  Future<void> fetchPlansFull({bool forceRefresh = false}) async {
    if (!forceRefresh && state is WorkoutPlanLoaded) {
      final loadedState = state as WorkoutPlanLoaded;
      if (loadedState.plans.isNotEmpty) return;
    }

    if (!isClosed) emit(WorkoutPlanLoading());
    try {
      final plans = await _workoutRepository.getAllPlansFull();
      if (!isClosed) emit(WorkoutPlanLoaded(plans));
    } catch (e) {
      if (!isClosed) emit(WorkoutPlanError(_formatErrorMessage(e)));
    }
  }

  String _formatErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('DioException') || str.contains('SocketException') || str.contains('connection error') || str.contains('Failed to connect') || str.contains('NetworkException')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra lại Wifi/4G.';
    }
    return 'Không thể tải lịch tập gợi ý. Vui lòng thử lại sau.';
  }
}
