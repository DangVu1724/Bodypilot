class FoodServingModel {
  final String id;
  final String name;
  final double grams;
  final bool isDefault;

  FoodServingModel({
    required this.id,
    required this.name,
    required this.grams,
    required this.isDefault,
  });

  factory FoodServingModel.fromJson(Map<String, dynamic> json) {
    return FoodServingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      grams: (json['grams'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grams': grams,
      'isDefault': isDefault,
    };
  }
}
