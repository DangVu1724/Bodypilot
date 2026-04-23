class RecipeIngredientModel {
  final String id;
  final String foodId;
  final String foodName;
  final double quantityGrams;

  RecipeIngredientModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.quantityGrams,
  });

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientModel(
      id: json['id'] as String,
      foodId: json['foodId'] as String,
      foodName: json['foodName'] as String,
      quantityGrams: (json['quantityGrams'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'quantityGrams': quantityGrams,
    };
  }
}
