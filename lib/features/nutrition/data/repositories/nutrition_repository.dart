import '../../domain/entities/nutrition_daily.dart';
import '../../domain/entities/meal_log.dart';
import '../../domain/repositories/i_nutrition_repository.dart';
import '../../domain/mappers/nutrition_mapper.dart';
import '../../domain/entities/calorie_history_item.dart';
import '../local/nutrition_local_database.dart';
import '../models/daily_nutrition.dart' as models;
import '../models/meal_log.dart' as models;

class NutritionRepository implements INutritionRepository {
  final NutritionLocalDatabase _local;

  NutritionRepository({NutritionLocalDatabase? local})
      : _local = local ?? NutritionLocalDatabase.instance;

  @override
  Future<NutritionDailyEntity> getDailyNutrition(String userId, DateTime date) async {
    final model = await _local.loadDay(userId, date);
    if (model == null) {
      return NutritionDailyEntity(
        date: date,
        logs: [],
        calorieGoal: 2000,
        proteinGoalG: 150.0,
        carbsGoalG: 250.0,
        fatGoalG: 65.0,
        waterGoalMl: 2000,
        waterLoggedMl: 0,
        waterMlPerHour: List<int>.filled(24, 0),
      );
    }
    return NutritionMapper.toEntityDaily(model, userId);
  }

  @override
  Future<void> saveMealLog(MealLogEntity log) async {
    final currentModel = await _local.loadDay(log.userId, log.date);
    final daily = currentModel ?? models.DailyNutrition(
      date: log.date, 
      logs: [],
      calorieGoal: 2000,
      proteinGoalG: 150.0,
      carbsGoalG: 250.0,
      fatGoalG: 65.0,
      waterGoalMl: 2000,
    );
    
    // Check if it's an update or a new log
    final logs = List<models.MealLog>.from(daily.logs);
    final index = logs.indexWhere((l) => l.id == log.id);
    
    final newLogModel = NutritionMapper.toModelMeal(log);
    if (index >= 0) {
      logs[index] = newLogModel;
    } else {
      logs.add(newLogModel);
    }
    
    await _local.saveDay(log.userId, log.date, daily.copyWith(logs: logs));
  }

  @override
  Future<void> deleteMealLog(String logId) async {
    await _local.deleteMealLog(logId);
  }

  @override
  Future<void> updateWaterIntake(String userId, DateTime date, int totalMl, List<int> hourly) async {
    final currentModel = await _local.loadDay(userId, date);
    final daily = currentModel ?? models.DailyNutrition(date: date, logs: []);
    
    await _local.saveDay(userId, date, daily.copyWith(
      waterLoggedMl: totalMl,
      waterMlPerHour: hourly,
    ));
  }

  @override
  Future<List<CalorieHistoryItem>> getCalorieHistory(String userId, DateTime start, DateTime end) async {
    final data = await _local.loadCalorieHistory(userId, start, end);
    return data.map((map) => CalorieHistoryItem(
      date: map['date'] as DateTime,
      caloriesEaten: map['eaten'] as double,
      calorieGoal: map['goal'] as int,
    )).toList();
  }
}

