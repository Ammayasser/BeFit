// lib/features/nutrition/data/models/meal_log.dart

import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snacks }

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snacks:
        return 'Snacks';
    }
  }
}

class MealLog {
  final String id;
  final MealType mealType;
  final FoodItem foodItem;
  final double quantityGrams;
  final DateTime loggedAt;
  final double loggedCalories;
  final double loggedProtein;
  final double loggedCarbs;
  final double loggedFat;

  const MealLog({
    required this.id,
    required this.mealType,
    required this.foodItem,
    required this.quantityGrams,
    required this.loggedAt,
    required this.loggedCalories,
    required this.loggedProtein,
    required this.loggedCarbs,
    required this.loggedFat,
  });

  /// Factory that auto-computes macros from food item + grams
  factory MealLog.create({
    required String id,
    required MealType mealType,
    required FoodItem foodItem,
    required double quantityGrams,
    DateTime? loggedAt,
  }) {
    return MealLog(
      id: id,
      mealType: mealType,
      foodItem: foodItem,
      quantityGrams: quantityGrams,
      loggedAt: loggedAt ?? DateTime.now(),
      loggedCalories: foodItem.caloriesFor(quantityGrams),
      loggedProtein: foodItem.proteinFor(quantityGrams),
      loggedCarbs: foodItem.carbsFor(quantityGrams),
      loggedFat: foodItem.fatFor(quantityGrams),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealType': mealType.index,
    'foodItem': foodItem.toJson(),
    'quantityGrams': quantityGrams,
    'loggedAt': loggedAt.toIso8601String(),
    'loggedCalories': loggedCalories,
    'loggedProtein': loggedProtein,
    'loggedCarbs': loggedCarbs,
    'loggedFat': loggedFat,
  };

  factory MealLog.fromJson(Map<String, dynamic> json) => MealLog(
    id: json['id'] as String,
    mealType: MealType.values[json['mealType'] as int],
    foodItem: FoodItem.fromJson(json['foodItem'] as Map<String, dynamic>),
    quantityGrams: (json['quantityGrams'] as num).toDouble(),
    loggedAt: DateTime.parse(json['loggedAt'] as String),
    loggedCalories: (json['loggedCalories'] as num).toDouble(),
    loggedProtein: (json['loggedProtein'] as num).toDouble(),
    loggedCarbs: (json['loggedCarbs'] as num).toDouble(),
    loggedFat: (json['loggedFat'] as num).toDouble(),
  );
}
