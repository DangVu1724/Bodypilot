import 'workout_category_model.dart';

class ExerciseModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? difficulty;
  final double? metValue;
  final List<String>? equipment;
  final WorkoutCategoryModel? category;

  ExerciseModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.mediaUrl,
    this.thumbnailUrl,
    this.difficulty,
    this.metValue,
    this.equipment,
    this.category,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      difficulty: json['difficulty'] as String?,
      metValue: (json['metValue'] as num?)?.toDouble(),
      equipment: (json['equipment'] as List<dynamic>?)?.map((e) => e as String).toList(),
      category: json['category'] != null ? WorkoutCategoryModel.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'difficulty': difficulty,
      'metValue': metValue,
      'equipment': equipment,
      'category': category?.toJson(),
    };
  }
}
