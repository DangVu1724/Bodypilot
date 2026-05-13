class RecipeIngredientModel {
  final String id;
  final String foodId;
  final String foodName;
  final double quantityGrams;
  final String? displayQuantity;

  RecipeIngredientModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    this.quantityGrams = 0,
    this.displayQuantity,
  });

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientModel(
      id: json['id'] as String,
      foodId: json['foodId'] as String,
      foodName: json['foodName'] as String,
      quantityGrams: (json['quantityGrams'] as num?)?.toDouble() ?? 0,
      displayQuantity: json['displayQuantity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'quantityGrams': quantityGrams,
      'displayQuantity': displayQuantity,
    };
  }
}
