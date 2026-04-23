class DietTagModel {
  final String id;
  final String name;
  final String? description;

  DietTagModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory DietTagModel.fromJson(Map<String, dynamic> json) {
    return DietTagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
