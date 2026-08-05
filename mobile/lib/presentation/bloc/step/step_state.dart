import 'package:equatable/equatable.dart';
import 'package:mobile/data/repositories/step_repository.dart';

class StepState extends Equatable {
  final int steps;
  final int targetSteps;
  final double userWeight;
  final String pedestrianStatus;
  final bool isPermissionGranted;
  final String? errorMessage;
  final List<StepHistoryModel> history;
  final bool isLoadingHistory;

  const StepState({
    this.steps = 0,
    this.targetSteps = 10000,
    this.userWeight = 65.0,
    this.pedestrianStatus = 'unknown',
    this.isPermissionGranted = true,
    this.errorMessage,
    this.history = const [],
    this.isLoadingHistory = false,
  });

  double get caloriesBurned => steps * (0.0005 * userWeight);

  double get distanceKm => steps * 0.00075;

  double get progress => targetSteps > 0 ? (steps / targetSteps).clamp(0.0, 1.0) : 0.0;

  StepState copyWith({
    int? steps,
    int? targetSteps,
    double? userWeight,
    String? pedestrianStatus,
    bool? isPermissionGranted,
    String? errorMessage,
    List<StepHistoryModel>? history,
    bool? isLoadingHistory,
  }) {
    return StepState(
      steps: steps ?? this.steps,
      targetSteps: targetSteps ?? this.targetSteps,
      userWeight: userWeight ?? this.userWeight,
      pedestrianStatus: pedestrianStatus ?? this.pedestrianStatus,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      errorMessage: errorMessage,
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  @override
  List<Object?> get props => [
        steps,
        targetSteps,
        userWeight,
        pedestrianStatus,
        isPermissionGranted,
        errorMessage,
        history,
        isLoadingHistory,
      ];
}
