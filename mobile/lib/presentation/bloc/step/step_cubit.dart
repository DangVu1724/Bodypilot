import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/services/step_tracker_service.dart';
import 'step_state.dart';

class StepCubit extends Cubit<StepState> {
  final StepTrackerService _stepTrackerService = StepTrackerService();

  StepCubit() : super(const StepState()) {
    init();
  }

  Future<void> init() async {
    final savedSteps = await _stepTrackerService.getSavedTodaySteps();
    emit(state.copyWith(steps: savedSteps));

    _stepTrackerService.initStepTracker(
      onStepCountUpdated: (todaySteps) {
        emit(state.copyWith(steps: todaySteps, isPermissionGranted: true));
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
