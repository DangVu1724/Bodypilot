import 'package:core_shared/models/workout_plan_model.dart';

abstract class WorkoutPlanState {}

class WorkoutPlanInitial extends WorkoutPlanState {}

class WorkoutPlanLoading extends WorkoutPlanState {}

class WorkoutPlanLoaded extends WorkoutPlanState {
  final List<WorkoutPlanModel> plans;
  WorkoutPlanLoaded(this.plans);
}

class WorkoutPlanError extends WorkoutPlanState {
  final String message;
  WorkoutPlanError(this.message);
}
