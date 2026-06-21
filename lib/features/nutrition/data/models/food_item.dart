// lib/features/nutrition/data/models/food_item.dart

class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? saturatedFatPer100g;
  final double? sodiumPer100g;
  final String? servingSize;
  final double? servingGrams;
  final String? nutriScore;
  final int? novaGroup;
  final Map<String, double>? micronutrients;
  final bool isGeneric;

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.saturatedFatPer100g,
    this.sodiumPer100g,
    this.servingSize,
    this.servingGrams,
    this.nutriScore,
    this.novaGroup,
    this.micronutrients,
    this.isGeneric = false,
  });

  /// Compute macros for a given quantity in grams
  double caloriesFor(double grams) => (caloriesPer100g * grams) / 100.0;
  double proteinFor(double grams) => (proteinPer100g * grams) / 100.0;
  double carbsFor(double grams) => (carbsPer100g * grams) / 100.0;
  double fatFor(double grams) => (fatPer100g * grams) / 100.0;

  FoodItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? imageUrl,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    double? sugarPer100g,
    double? saturatedFatPer100g,
    double? sodiumPer100g,
    String? servingSize,
    double? servingGrams,
    String? nutriScore,
    int? novaGroup,
    Map<String, double>? micronutrients,
    bool? isGeneric,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      sugarPer100g: sugarPer100g ?? this.sugarPer100g,
      saturatedFatPer100g: saturatedFatPer100g ?? this.saturatedFatPer100g,
      sodiumPer100g: sodiumPer100g ?? this.sodiumPer100g,
      servingSize: servingSize ?? this.servingSize,
      servingGrams: servingGrams ?? this.servingGrams,
      nutriScore: nutriScore ?? this.nutriScore,
      novaGroup: novaGroup ?? this.novaGroup,
      micronutrients: micronutrients ?? this.micronutrients,
      isGeneric: isGeneric ?? this.isGeneric,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'caloriesPer100g': caloriesPer100g,
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatPer100g': fatPer100g,
    'fiberPer100g': fiberPer100g,
    'sugarPer100g': sugarPer100g,
    'saturatedFatPer100g': saturatedFatPer100g,
    'sodiumPer100g': sodiumPer100g,
    'servingSize': servingSize,
    'servingGrams': servingGrams,
    'nutriScore': nutriScore,
    'novaGroup': novaGroup,
    'micronutrients': micronutrients,
    'isGeneric': isGeneric,
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String?,
    imageUrl: json['imageUrl'] as String?,
    caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
    proteinPer100g: (json['proteinPer100g'] as num).toDouble(),
    carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
    fatPer100g: (json['fatPer100g'] as num).toDouble(),
    fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
    sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
    saturatedFatPer100g: (json['saturatedFatPer100g'] as num?)?.toDouble(),
    sodiumPer100g: (json['sodiumPer100g'] as num?)?.toDouble(),
    servingSize: json['servingSize'] as String?,
    servingGrams: (json['servingGrams'] as num?)?.toDouble(),
    nutriScore: json['nutriScore'] as String?,
    novaGroup: json['novaGroup'] as int?,
    isGeneric: json['isGeneric'] as bool? ?? false,
    micronutrients: json['micronutrients'] != null
        ? Map<String, double>.from(
            (json['micronutrients'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            ),
          )
        : null,
  );
}
