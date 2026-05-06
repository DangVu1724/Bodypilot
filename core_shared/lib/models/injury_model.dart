class InjuryModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String? bodyPart;

  InjuryModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.bodyPart,
  });

  factory InjuryModel.fromJson(Map<String, dynamic> json) {
    return InjuryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      bodyPart: json['bodyPart'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'bodyPart': bodyPart,
    };
  }
}
