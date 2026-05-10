import 'workout_session_model.dart';

class WorkoutPlanModel {
  final String? id;
  final String title;
  final String goal;
  final String difficulty;
  final int totalDays;
  final String? thumbnailUrl;
  final bool isPremium;
  final List<WorkoutSessionModel>? sessions;

  WorkoutPlanModel({
    this.id,
    required this.title,
    required this.goal,
    required this.difficulty,
    required this.totalDays,
    this.thumbnailUrl,
    required this.isPremium,
    this.sessions,
  });

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: json['id'] as String?,
      title: (json['title'] as String?) ?? 'Untitled Plan',
      goal: (json['goal'] as String?) ?? 'GENERAL',
      difficulty: (json['difficulty'] as String?) ?? 'BEGINNER',
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      sessions: (json['sessions'] as List<dynamic>?)
          ?.map((e) => WorkoutSessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'goal': goal,
      'difficulty': difficulty,
      'totalDays': totalDays,
      'thumbnailUrl': thumbnailUrl,
      'isPremium': isPremium,
      if (sessions != null) 'sessions': sessions!.map((e) => e.toJson()).toList(),
    };
  }
}
