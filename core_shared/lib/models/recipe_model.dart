import 'recipe_ingredient_model.dart';

class RecipeModel {
  final String id;
  final int servings;
  final int? cookingTimeMinutes;
  final String? instructions;
  final List<RecipeIngredientModel> ingredients;

  RecipeModel({
    required this.id,
    required this.servings,
    this.cookingTimeMinutes,
    this.instructions,
    required this.ingredients,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as String,
      servings: json['servings'] as int? ?? 1,
      cookingTimeMinutes: json['cookingTimeMinutes'] as int?,
      instructions: json['instructions'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((item) => RecipeIngredientModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'servings': servings,
      'cookingTimeMinutes': cookingTimeMinutes,
      'instructions': instructions,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }
}
