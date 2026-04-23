class FoodCategoryModel {
  final String id;
  final String name;
  final String code;
  final String appliesTo;

  FoodCategoryModel({
    required this.id,
    required this.name,
    required this.code,
    required this.appliesTo,
  });

  factory FoodCategoryModel.fromJson(Map<String, dynamic> json) {
    return FoodCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      appliesTo: json['appliesTo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'appliesTo': appliesTo,
    };
  }
}
