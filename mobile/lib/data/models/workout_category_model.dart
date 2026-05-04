class WorkoutCategoryModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? workoutType;

  WorkoutCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.workoutType,
  });

  factory WorkoutCategoryModel.fromJson(Map<String, dynamic> json) {
    return WorkoutCategoryModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      workoutType: json['workoutType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'workoutType': workoutType,
    };
  }
}
