import 'exercise_model.dart';

class WorkoutSessionExerciseModel {
  final String? id;
  final ExerciseModel exercise;
  final int order;
  final int? sets;
  final int? reps;
  final double? weightKg;
  final int? restSeconds;
  final int? durationMinutes;
  final double? distanceKm;

  WorkoutSessionExerciseModel({
    this.id,
    required this.exercise,
    required this.order,
    this.sets,
    this.reps,
    this.weightKg,
    this.restSeconds,
    this.durationMinutes,
    this.distanceKm,
  });

  factory WorkoutSessionExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionExerciseModel(
      id: json['id'] as String?,
      exercise: json['exercise'] != null 
          ? ExerciseModel.fromJson(json['exercise'] as Map<String, dynamic>)
          : ExerciseModel(id: '', code: '', name: 'Unknown Exercise'),
      order: (json['order'] as num?)?.toInt() ?? 0,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      restSeconds: json['restSeconds'] as int?,
      durationMinutes: json['durationMinutes'] as int?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'exercise': exercise.toJson(),
      'order': order,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'restSeconds': restSeconds,
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
    };
  }
}
