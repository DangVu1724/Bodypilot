class BodyPartModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;

  BodyPartModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory BodyPartModel.fromJson(Map<String, dynamic> json) {
    return BodyPartModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
