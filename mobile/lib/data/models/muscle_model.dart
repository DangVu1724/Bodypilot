class MuscleModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? bodyPartId;
  final String? bodyPartName;
  final String? imageUrl;

  MuscleModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.bodyPartId,
    this.bodyPartName,
    this.imageUrl,
  });

  factory MuscleModel.fromJson(Map<String, dynamic> json) {
    return MuscleModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      bodyPartId: json['bodyPartId'] as String?,
      bodyPartName: json['bodyPartName'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'bodyPartId': bodyPartId,
      'bodyPartName': bodyPartName,
      'imageUrl': imageUrl,
    };
  }
}
