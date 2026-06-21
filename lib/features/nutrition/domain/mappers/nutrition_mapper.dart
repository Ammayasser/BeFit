import '../../data/models/daily_nutrition.dart' as models;
import '../../data/models/meal_log.dart' as models;
import '../../data/models/food_item.dart' as models;
import '../entities/nutrition_daily.dart';
import '../entities/meal_log.dart';
import '../entities/food_item.dart';

class NutritionMapper {
  static FoodItemEntity toEntityFood(models.FoodItem model) {
    return FoodItemEntity(
      id: model.id,
      name: model.name,
      brand: model.brand ?? '',
      calories: model.caloriesPer100g,
      protein: model.proteinPer100g,
      carbs: model.carbsPer100g,
      fat: model.fatPer100g,
      servingSize: model.servingGrams ?? 100.0,
      servingUnit: 'g',
      imageUrl: model.imageUrl,
    );
  }

  static models.FoodItem toModelFood(FoodItemEntity entity) {
    return models.FoodItem(
      id: entity.id,
      name: entity.name,
      brand: entity.brand,
      caloriesPer100g: entity.calories,
      proteinPer100g: entity.protein,
      carbsPer100g: entity.carbs,
      fatPer100g: entity.fat,
      servingGrams: entity.servingSize,
      servingSize: '${entity.servingSize}${entity.servingUnit}',
      imageUrl: entity.imageUrl,
    );
  }

  static MealType toEntityMealType(models.MealType model) {
    switch (model) {
      case models.MealType.breakfast: return MealType.breakfast;
      case models.MealType.lunch: return MealType.lunch;
      case models.MealType.dinner: return MealType.dinner;
      case models.MealType.snacks: return MealType.snack;
    }
  }

  static models.MealType toModelMealType(MealType entity) {
    switch (entity) {
      case MealType.breakfast: return models.MealType.breakfast;
      case MealType.lunch: return models.MealType.lunch;
      case MealType.dinner: return models.MealType.dinner;
      case MealType.snack: return models.MealType.snacks;
    }
  }

  static MealLogEntity toEntityMeal(models.MealLog model, String userId, DateTime date) {
    return MealLogEntity(
      id: model.id,
      userId: userId,
      date: date,
      mealType: toEntityMealType(model.mealType),
      food: toEntityFood(model.foodItem),
      quantity: model.quantityGrams / (model.foodItem.servingGrams ?? 100.0),
      loggedAt: model.loggedAt,
    );
  }

  static models.MealLog toModelMeal(MealLogEntity entity) {
    final foodModel = toModelFood(entity.food);
    final quantityGrams = entity.quantity * entity.food.servingSize;
    return models.MealLog(
      id: entity.id,
      mealType: toModelMealType(entity.mealType),
      foodItem: foodModel,
      quantityGrams: quantityGrams,
      loggedAt: entity.loggedAt,
      loggedCalories: foodModel.caloriesFor(quantityGrams),
      loggedProtein: foodModel.proteinFor(quantityGrams),
      loggedCarbs: foodModel.carbsFor(quantityGrams),
      loggedFat: foodModel.fatFor(quantityGrams),
    );
  }

  static NutritionDailyEntity toEntityDaily(models.DailyNutrition model, String userId) {
    return NutritionDailyEntity(
      date: model.date,
      logs: model.logs.map((l) => toEntityMeal(l, userId, model.date)).toList(),
      calorieGoal: model.calorieGoal,
      proteinGoalG: model.proteinGoalG,
      carbsGoalG: model.carbsGoalG,
      fatGoalG: model.fatGoalG,
      waterGoalMl: model.waterGoalMl,
      waterLoggedMl: model.waterLoggedMl,
      waterMlPerHour: model.hourlyWaterMl,
    );
  }

  static models.DailyNutrition toModelDaily(NutritionDailyEntity entity) {
    return models.DailyNutrition(
      date: entity.date,
      logs: entity.logs.map(toModelMeal).toList(),
      calorieGoal: entity.calorieGoal,
      proteinGoalG: entity.proteinGoalG,
      carbsGoalG: entity.carbsGoalG,
      fatGoalG: entity.fatGoalG,
      waterGoalMl: entity.waterGoalMl,
      waterLoggedMl: entity.waterLoggedMl,
      waterMlPerHour: entity.waterMlPerHour,
    );
  }
}
