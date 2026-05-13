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
      if (!isClosed) emit(WorkoutPlanError(e.toString()));
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
      if (!isClosed) emit(WorkoutPlanError(e.toString()));
    }
  }
}
