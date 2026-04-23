import 'food_category_model.dart';
import 'food_serving_model.dart';
import 'diet_tag_model.dart';
import 'recipe_model.dart';

class FoodModel {
  final String id;
  final String name;
  final String type;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumMgPer100g;
  final FoodCategoryModel? category;
  final String? categoryName; 
  final double? defaultServingSize;
  final String? defaultUnit;
  final String? imageUrl;
  final String? description;
  final int? healthScore;
  final List<FoodServingModel> servings;
  final List<DietTagModel> dietTags;
  final RecipeModel? recipe;

  FoodModel({
    required this.id,
    required this.name,
    required this.type,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumMgPer100g,
    this.category,
    this.categoryName,
    this.defaultServingSize,
    this.defaultUnit,
    this.imageUrl,
    this.description,
    this.healthScore,
    this.servings = const [],
    this.dietTags = const [],
    this.recipe,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
      proteinPer100g: (json['proteinPer100g'] as num).toDouble(),
      fatPer100g: (json['fatPer100g'] as num).toDouble(),
      carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
      fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
      sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
      sodiumMgPer100g: (json['sodiumMgPer100g'] as num?)?.toDouble(),
      category: json['category'] != null
          ? FoodCategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      categoryName: json['categoryName'] as String?,
      defaultServingSize: (json['defaultServingSize'] as num?)?.toDouble(),
      defaultUnit: json['defaultUnit'] as String?,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      healthScore: json['healthScore'] as int?,
      servings: (json['servings'] as List<dynamic>?)
              ?.map((e) => FoodServingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dietTags: (json['dietTags'] as List<dynamic>?)
              ?.map((e) => DietTagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recipe: json['recipe'] != null
          ? RecipeModel.fromJson(json['recipe'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'fatPer100g': fatPer100g,
      'carbsPer100g': carbsPer100g,
      'fiberPer100g': fiberPer100g,
      'sugarPer100g': sugarPer100g,
      'sodiumMgPer100g': sodiumMgPer100g,
      'category': category?.toJson(),
      'categoryName': categoryName,
      'defaultServingSize': defaultServingSize,
      'defaultUnit': defaultUnit,
      'imageUrl': imageUrl,
      'description': description,
      'healthScore': healthScore,
      'servings': servings.map((e) => e.toJson()).toList(),
      'dietTags': dietTags.map((e) => e.toJson()).toList(),
      'recipe': recipe?.toJson(),
    };
  }
}