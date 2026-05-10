import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_plan_state.dart';

class WorkoutPlanCubit extends Cubit<WorkoutPlanState> {
  final WorkoutRepository _workoutRepository;

  WorkoutPlanCubit(this._workoutRepository) : super(WorkoutPlanInitial());

  Future<void> fetchPlans() async {
    if (!isClosed) emit(WorkoutPlanLoading());
    try {
      final plans = await _workoutRepository.getAllPlans();
      if (!isClosed) emit(WorkoutPlanLoaded(plans));
    } catch (e) {
      if (!isClosed) emit(WorkoutPlanError(e.toString()));
    }
  }

  Future<void> fetchPlansFull() async {
    if (!isClosed) emit(WorkoutPlanLoading());
    try {
      final plans = await _workoutRepository.getAllPlansFull();
      if (!isClosed) emit(WorkoutPlanLoaded(plans));
    } catch (e) {
      if (!isClosed) emit(WorkoutPlanError(e.toString()));
    }
  }
}
