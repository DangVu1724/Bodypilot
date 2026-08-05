import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/step_repository.dart';
import 'package:mobile/data/services/step_tracker_service.dart';
import 'package:mobile/data/services/token_service.dart';
import 'step_state.dart';

class StepCubit extends Cubit<StepState> {
  final StepTrackerService _stepTrackerService = StepTrackerService();
  int _lastSyncedSteps = -1;

  StepCubit() : super(const StepState()) {
    init();
  }

  Future<void> init() async {
    final savedSteps = await _stepTrackerService.getSavedTodaySteps();
    emit(state.copyWith(steps: savedSteps));
    syncTodayStepsToBackend(savedSteps);
    fetchStepHistory();

    _stepTrackerService.initStepTracker(
      onStepCountUpdated: (todaySteps) {
        emit(state.copyWith(steps: todaySteps, isPermissionGranted: true));
        // Sync to backend if step count changed significantly (>= 50 steps) or first time
        if (_lastSyncedSteps < 0 || (todaySteps - _lastSyncedSteps).abs() >= 50) {
          syncTodayStepsToBackend(todaySteps);
        }
      },
      onStatusChanged: (status) {
        emit(state.copyWith(pedestrianStatus: status));
      },
      onError: (error) {
        emit(state.copyWith(
          errorMessage: error.toString(),
          isPermissionGranted: false,
        ));
      },
    );
  }

  Future<void> syncTodayStepsToBackend(int steps) async {
    final userId = TokenService.getUserId();
    if (userId == null || userId.isEmpty) return;

    _lastSyncedSteps = steps;
    final calories = steps * (0.0005 * state.userWeight);
    final distanceKm = steps * 0.00075;

    await stepRepository.syncTodaySteps(
      userId: userId,
      stepCount: steps,
      caloriesBurned: calories,
      distanceKm: distanceKm,
    );
  }

  Future<void> fetchStepHistory() async {
    final userId = TokenService.getUserId();
    if (userId == null || userId.isEmpty) return;

    emit(state.copyWith(isLoadingHistory: true));
    final history = await stepRepository.getStepHistory(userId);
    emit(state.copyWith(history: history, isLoadingHistory: false));
  }

  void updateUserWeight(double weight) {
    if (weight > 0) {
      emit(state.copyWith(userWeight: weight));
    }
  }

  void setTargetSteps(int target) {
    if (target > 0) {
      emit(state.copyWith(targetSteps: target));
    }
  }

  @override
  Future<void> close() {
    _stepTrackerService.dispose();
    return super.close();
  }
}
