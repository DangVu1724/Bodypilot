class FoodServingModel {
  final String id;
  final String name;
  final String unitCode;
  final double grams;

  FoodServingModel({
    required this.id,
    required this.name,
    required this.unitCode,
    required this.grams,
  });

  factory FoodServingModel.fromJson(Map<String, dynamic> json) {
    return FoodServingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      unitCode: json['unitCode'] as String? ?? 'GRAM',
      grams: (json['grams'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unitCode': unitCode,
      'grams': grams,
    };
  }
}
