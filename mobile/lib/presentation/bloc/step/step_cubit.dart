import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/step_repository.dart';
import 'package:mobile/data/services/step_tracker_service.dart';
import 'package:mobile/data/services/token_service.dart';
import 'step_state.dart';

class StepCubit extends Cubit<StepState> with WidgetsBindingObserver {
  final StepTrackerService _stepTrackerService = StepTrackerService();
  int _lastSyncedSteps = -1;

  StepCubit() : super(const StepState()) {
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshOnAppResumed();
    }
  }

  Future<void> refreshOnAppResumed() async {
    final savedSteps = await _stepTrackerService.getSavedTodaySteps();
    if (savedSteps > state.steps) {
      emit(state.copyWith(steps: savedSteps));
    }
    if (state.steps > 0) {
      syncTodayStepsToBackend(state.steps);
    }
    fetchStepHistory();
  }

  Future<void> init() async {
    final savedSteps = await _stepTrackerService.getSavedTodaySteps();
    int currentSteps = savedSteps;
    emit(state.copyWith(steps: currentSteps));

    final userId = TokenService.getUserId();
    if (userId != null && userId.isNotEmpty) {
      // 1. Fetch today's steps already recorded on the server
      final backendToday = await stepRepository.getTodaySteps(userId);
      if (backendToday != null && backendToday.stepCount > currentSteps) {
        currentSteps = backendToday.stepCount;
        await _stepTrackerService.restoreTodaySteps(currentSteps);
        emit(state.copyWith(steps: currentSteps));
      }
      fetchStepHistory();
    }

    _stepTrackerService.initStepTracker(
      onStepCountUpdated: (todaySteps) {
        emit(state.copyWith(steps: todaySteps, isPermissionGranted: true));
        // Sync to backend if step count changed significantly (>= 50 steps) or first time
        if (todaySteps > 0 && (_lastSyncedSteps < 0 || (todaySteps - _lastSyncedSteps).abs() >= 50)) {
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
    if (steps <= 0) return;
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
    WidgetsBinding.instance.removeObserver(this);
    _stepTrackerService.dispose();
    return super.close();
  }
}
