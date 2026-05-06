class HealthConditionModel {
  final String id;
  final String name;
  final String code;
  final String? description;

  HealthConditionModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  factory HealthConditionModel.fromJson(Map<String, dynamic> json) {
    return HealthConditionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
    };
  }
}
