import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack }

class MealLogEntity {
  final String id;
  final String userId;
  final DateTime date;
  final MealType mealType;
  final FoodItemEntity food;
  final double quantity; // in units defined by food (e.g., servings, grams)
  final DateTime loggedAt;

  const MealLogEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.food,
    required this.quantity,
    required this.loggedAt,
  });

  double get loggedCalories => food.calories * quantity;
  double get loggedProtein => food.protein * quantity;
  double get loggedCarbs => food.carbs * quantity;
  double get loggedFat => food.fat * quantity;

  MealLogEntity copyWith({
    double? quantity,
    MealType? mealType,
  }) {
    return MealLogEntity(
      id: id,
      userId: userId,
      date: date,
      mealType: mealType ?? this.mealType,
      food: food,
      quantity: quantity ?? this.quantity,
      loggedAt: loggedAt,
    );
  }
}
