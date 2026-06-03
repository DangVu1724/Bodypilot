enum MealType { BREAKFAST, LUNCH, DINNER, SNACK }

class DailyEatingModel {
  final String? id;
  final DateTime date;
  final String? note;
  final bool isAiGenerated;
  final List<MealSlotModel> mealSlots;
  final double totalCaloriesPlanned;
  final double totalCaloriesEaten;

  DailyEatingModel({
    this.id,
    required this.date,
    this.note,
    this.isAiGenerated = false,
    required this.mealSlots,
    this.totalCaloriesPlanned = 0.0,
    this.totalCaloriesEaten = 0.0,
  });

  factory DailyEatingModel.fromJson(Map<String, dynamic> json) {
    return DailyEatingModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      isAiGenerated: json['isAiGenerated'] ?? false,
      mealSlots: (json['mealSlots'] as List).map((i) => MealSlotModel.fromJson(i)).toList(),
      totalCaloriesPlanned: ((json['totalCaloriesPlanned'] ?? 0) as num).toDouble(),
      totalCaloriesEaten: ((json['totalCaloriesEaten'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'note': note,
      'isAiGenerated': isAiGenerated,
      'mealSlots': mealSlots.map((i) => i.toJson()).toList(),
      'totalCaloriesPlanned': totalCaloriesPlanned,
      'totalCaloriesEaten': totalCaloriesEaten,
    };
  }
}

class MealSlotModel {
  final String? id;
  final MealType mealType;
  final String? customName;
  final int orderIndex;
  final bool isEaten;
  final List<MealItemModel> items;

  MealSlotModel({
    this.id,
    required this.mealType,
    this.customName,
    this.orderIndex = 0,
    this.isEaten = false,
    required this.items,
  });

  factory MealSlotModel.fromJson(Map<String, dynamic> json) {
    return MealSlotModel(
      id: json['id'],
      mealType: MealType.values.firstWhere((e) => e.name == json['mealType']),
      customName: json['customName'],
      orderIndex: json['orderIndex'] ?? 0,
      isEaten: json['isEaten'] ?? false,
      items: (json['items'] as List).map((i) => MealItemModel.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealType': mealType.name,
      'customName': customName,
      'orderIndex': orderIndex,
      'isEaten': isEaten,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class MealItemModel {
  final String? id;
  final double servingQuantity;
  final int orderIndex;
  final bool isCustom;
  final bool isEaten;
  final String? foodId;

  // Snapshots
  final String foodNameSnapshot;
  final double caloriesSnapshot;
  final double proteinSnapshot;
  final double fatSnapshot;
  final double carbsSnapshot;
  final double? fiberSnapshot;
  final String? servingUnitSnapshot;
  final String? imageUrlSnapshot;

  MealItemModel({
    this.id,
    required this.servingQuantity,
    this.orderIndex = 0,
    this.isCustom = false,
    this.isEaten = false,
    this.foodId,
    required this.foodNameSnapshot,
    required this.caloriesSnapshot,
    required this.proteinSnapshot,
    required this.fatSnapshot,
    required this.carbsSnapshot,
    this.fiberSnapshot,
    this.servingUnitSnapshot,
    this.imageUrlSnapshot,
  });

  factory MealItemModel.fromJson(Map<String, dynamic> json) {
    return MealItemModel(
      id: json['id'],
      servingQuantity: (json['servingQuantity'] as num).toDouble(),
      orderIndex: json['orderIndex'] ?? 0,
      isCustom: json['isCustom'] ?? false,
      isEaten: json['isEaten'] ?? false,
      foodId: json['foodId'],
      foodNameSnapshot: (json['foodNameSnapshot'] ?? json['foodName']) as String? ?? '',
      caloriesSnapshot: ((json['caloriesSnapshot'] ?? json['calories']) as num?)?.toDouble() ?? 0.0,
      proteinSnapshot: ((json['proteinSnapshot'] ?? json['protein']) as num?)?.toDouble() ?? 0.0,
      fatSnapshot: ((json['fatSnapshot'] ?? json['fat']) as num?)?.toDouble() ?? 0.0,
      carbsSnapshot: ((json['carbsSnapshot'] ?? json['carbs']) as num?)?.toDouble() ?? 0.0,
      fiberSnapshot: ((json['fiberSnapshot'] ?? json['fiber']) as num?)?.toDouble(),
      servingUnitSnapshot: (json['servingUnitSnapshot'] ?? json['servingUnit']) as String?,
      imageUrlSnapshot: (json['imageUrlSnapshot'] ?? json['imageUrl']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'servingQuantity': servingQuantity,
      'orderIndex': orderIndex,
      'isCustom': isCustom,
      'isEaten': isEaten,
      'foodId': foodId,
      'foodNameSnapshot': foodNameSnapshot,
      'caloriesSnapshot': caloriesSnapshot,
      'proteinSnapshot': proteinSnapshot,
      'fatSnapshot': fatSnapshot,
      'carbsSnapshot': carbsSnapshot,
      'fiberSnapshot': fiberSnapshot,
      'servingUnitSnapshot': servingUnitSnapshot,
      'imageUrlSnapshot': imageUrlSnapshot,
    };
  }
}
