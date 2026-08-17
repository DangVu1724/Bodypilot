class FoodSmartSwapCandidateModel {
  final String foodId;
  final String foodName;
  final String categoryName;
  final String? imageUrl;
  final double recommendedServingQuantity;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double matchScore;
  final String matchReason;
  final String? swapGroup;

  FoodSmartSwapCandidateModel({
    required this.foodId,
    required this.foodName,
    required this.categoryName,
    this.imageUrl,
    required this.recommendedServingQuantity,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.matchScore,
    required this.matchReason,
    this.swapGroup,
  });

  factory FoodSmartSwapCandidateModel.fromJson(Map<String, dynamic> json) {
    return FoodSmartSwapCandidateModel(
      foodId: json['foodId'] as String,
      foodName: json['foodName'] as String? ?? 'Món ăn',
      categoryName: json['categoryName'] as String? ?? 'Khác',
      imageUrl: json['imageUrl'] as String?,
      recommendedServingQuantity: (json['recommendedServingQuantity'] as num?)?.toDouble() ?? 100.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 80.0,
      matchReason: json['matchReason'] as String? ?? 'Tương đồng dinh dưỡng',
      swapGroup: json['swapGroup'] as String?,
    );
  }
}
