import 'workout_session_exercise_model.dart';

class WorkoutSessionModel {
  final String? id;
  final String? planId;
  final int dayNumber;
  final String name;
  final List<WorkoutSessionExerciseModel>? exercises;

  WorkoutSessionModel({
    this.id,
    this.planId,
    required this.dayNumber,
    required this.name,
    this.exercises,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as String?,
      planId: json['planId'] as String?,
      dayNumber: json['dayNumber'] as int,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutSessionExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'planId': planId,
      'dayNumber': dayNumber,
      'name': name,
      if (exercises != null) 'exercises': exercises!.map((e) => e.toJson()).toList(),
    };
  }
}
