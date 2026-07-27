class DailyWorkoutModel {
  final String? id;
  final DateTime date;
  final String? note;
  final bool isAiGenerated;
  final double totalCaloriesPlanned;
  final double totalCaloriesBurned;
  final bool isCompleted;
  final List<DailyWorkoutItemModel> workoutItems;

  DailyWorkoutModel({
    this.id,
    required this.date,
    this.note,
    this.isAiGenerated = false,
    this.totalCaloriesPlanned = 0.0,
    this.totalCaloriesBurned = 0.0,
    this.isCompleted = false,
    required this.workoutItems,
  });

  factory DailyWorkoutModel.fromJson(Map<String, dynamic> json) {
    return DailyWorkoutModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      isAiGenerated: json['isAiGenerated'] ?? false,
      totalCaloriesPlanned: ((json['totalCaloriesPlanned'] ?? 0) as num).toDouble(),
      totalCaloriesBurned: ((json['totalCaloriesBurned'] ?? 0) as num).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
      workoutItems: (json['workoutItems'] as List? ?? [])
          .map((i) => DailyWorkoutItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'note': note,
      'isAiGenerated': isAiGenerated,
      'totalCaloriesPlanned': totalCaloriesPlanned,
      'totalCaloriesBurned': totalCaloriesBurned,
      'isCompleted': isCompleted,
      'workoutItems': workoutItems.map((i) => i.toJson()).toList(),
    };
  }
}

class DailyWorkoutItemModel {
  final String? id;
  final String? exerciseId;
  final int orderIndex;
  final bool isCompleted;

  // Snapshots
  final String exerciseNameSnapshot;
  final int? setsSnapshot;
  final int? repsSnapshot;
  final double? weightKgSnapshot;
  final int? restSecondsSnapshot;
  final int? durationMinutesSnapshot;
  final double? distanceKmSnapshot;
  final double caloriesBurnedSnapshot;
  final bool isCustom;
  final String? notes;

  DailyWorkoutItemModel({
    this.id,
    this.exerciseId,
    this.orderIndex = 0,
    this.isCompleted = false,
    required this.exerciseNameSnapshot,
    this.setsSnapshot,
    this.repsSnapshot,
    this.weightKgSnapshot,
    this.restSecondsSnapshot,
    this.durationMinutesSnapshot,
    this.distanceKmSnapshot,
    this.caloriesBurnedSnapshot = 0.0,
    this.isCustom = false,
    this.notes,
  });

  factory DailyWorkoutItemModel.fromJson(Map<String, dynamic> json) {
    return DailyWorkoutItemModel(
      id: json['id'],
      exerciseId: json['exerciseId'],
      orderIndex: json['orderIndex'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      exerciseNameSnapshot: (json['exerciseNameSnapshot'] ?? json['exerciseName']) as String? ?? '',
      setsSnapshot: json['setsSnapshot'] ?? json['sets'],
      repsSnapshot: json['repsSnapshot'] ?? json['reps'],
      weightKgSnapshot: ((json['weightKgSnapshot'] ?? json['weightKg']) as num?)?.toDouble(),
      restSecondsSnapshot: json['restSecondsSnapshot'] ?? json['restSeconds'],
      durationMinutesSnapshot: json['durationMinutesSnapshot'] ?? json['durationMinutes'],
      distanceKmSnapshot: ((json['distanceKmSnapshot'] ?? json['distanceKm']) as num?)?.toDouble(),
      caloriesBurnedSnapshot: ((json['caloriesBurnedSnapshot'] ?? json['caloriesBurned'] ?? 0) as num).toDouble(),
      isCustom: json['isCustom'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'isCompleted': isCompleted,
      'exerciseNameSnapshot': exerciseNameSnapshot,
      'setsSnapshot': setsSnapshot,
      'repsSnapshot': repsSnapshot,
      'weightKgSnapshot': weightKgSnapshot,
      'restSecondsSnapshot': restSecondsSnapshot,
      'durationMinutesSnapshot': durationMinutesSnapshot,
      'distanceKmSnapshot': distanceKmSnapshot,
      'caloriesBurnedSnapshot': caloriesBurnedSnapshot,
      'isCustom': isCustom,
      'notes': notes,
    };
  }
}
