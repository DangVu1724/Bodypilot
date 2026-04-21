class UserMetricsModel {
  final double? weight;
  final double? heightCm;
  final int? age;
  final String? goal;
  final String? activityLevel;
  final double? bmi;
  final double? bmr;
  final double? tdee;
  final double? targetCalories;

  UserMetricsModel({
    this.weight,
    this.heightCm,
    this.age,
    this.goal,
    this.activityLevel,
    this.bmi,
    this.bmr,
    this.tdee,
    this.targetCalories,
  });

  factory UserMetricsModel.fromJson(Map<String, dynamic> json) {
    return UserMetricsModel(
      weight: (json['weight'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toInt(),
      goal: json['goal'] as String?,
      activityLevel: json['activityLevel'] as String?,
      bmi: (json['bmi'] as num?)?.toDouble(),
      bmr: (json['bmr'] as num?)?.toDouble(),
      tdee: (json['tdee'] as num?)?.toDouble(),
      targetCalories: (json['targetCalories'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'heightCm': heightCm,
      'age': age,
      'goal': goal,
      'activityLevel': activityLevel,
      'bmi': bmi,
      'bmr': bmr,
      'tdee': tdee,
      'targetCalories': targetCalories,
    };
  }
}
