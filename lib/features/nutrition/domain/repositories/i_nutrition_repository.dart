import '../entities/nutrition_daily.dart';
import '../entities/meal_log.dart';
import '../entities/calorie_history_item.dart';

abstract class INutritionRepository {
  Future<NutritionDailyEntity> getDailyNutrition(String userId, DateTime date);
  Future<void> saveMealLog(MealLogEntity log);
  Future<void> deleteMealLog(String logId);
  Future<void> updateWaterIntake(String userId, DateTime date, int totalMl, List<int> hourly);
  Future<List<CalorieHistoryItem>> getCalorieHistory(String userId, DateTime start, DateTime end);
}
