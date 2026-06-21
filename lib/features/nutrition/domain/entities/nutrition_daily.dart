import 'meal_log.dart';

class NutritionDailyEntity {
  final DateTime date;
  final List<MealLogEntity> logs;
  final int calorieGoal;
  final double proteinGoalG;
  final double carbsGoalG;
  final double fatGoalG;
  final int waterGoalMl;
  final int waterLoggedMl;
  final List<int> waterMlPerHour;

  const NutritionDailyEntity({
    required this.date,
    required this.logs,
    required this.calorieGoal,
    required this.proteinGoalG,
    required this.carbsGoalG,
    required this.fatGoalG,
    required this.waterGoalMl,
    required this.waterLoggedMl,
    required this.waterMlPerHour,
  });

  double get totalCalories => logs.fold(0.0, (sum, log) => sum + log.loggedCalories);
  double get totalProtein => logs.fold(0.0, (sum, log) => sum + log.loggedProtein);
  double get totalCarbs => logs.fold(0.0, (sum, log) => sum + log.loggedCarbs);
  double get totalFat => logs.fold(0.0, (sum, log) => sum + log.loggedFat);

  double get caloriesRemaining => calorieGoal - totalCalories;

  NutritionDailyEntity copyWith({
    List<MealLogEntity>? logs,
    int? waterLoggedMl,
    List<int>? waterMlPerHour,
  }) {
    return NutritionDailyEntity(
      date: date,
      logs: logs ?? this.logs,
      calorieGoal: calorieGoal,
      proteinGoalG: proteinGoalG,
      carbsGoalG: carbsGoalG,
      fatGoalG: fatGoalG,
      waterGoalMl: waterGoalMl,
      waterLoggedMl: waterLoggedMl ?? this.waterLoggedMl,
      waterMlPerHour: waterMlPerHour ?? this.waterMlPerHour,
    );
  }
}
