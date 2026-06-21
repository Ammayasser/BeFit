// lib/features/nutrition/data/models/daily_nutrition.dart

import 'meal_log.dart';

class DailyNutrition {
  final DateTime date;
  final List<MealLog> logs;
  final int calorieGoal;
  final double proteinGoalG;
  final double carbsGoalG;
  final double fatGoalG;
  final int waterGoalMl;
  final int waterLoggedMl;

  /// Milliliters logged per clock hour (index 0 = midnight … 23 = 11 PM).
  /// May be null or wrong length for legacy saves; use [hourlyWaterMl].
  final List<int>? waterMlPerHour;

  const DailyNutrition({
    required this.date,
    required this.logs,
    this.calorieGoal = 0,
    this.proteinGoalG = 0,
    this.carbsGoalG = 0,
    this.fatGoalG = 0,
    this.waterGoalMl = 2000,
    this.waterLoggedMl = 0,
    this.waterMlPerHour,
  });

  /// Normalized 24-element hourly breakdown for charts.
  List<int> get hourlyWaterMl {
    final raw = waterMlPerHour;
    if (raw != null && raw.length == 24) {
      return List<int>.from(raw);
    }
    return List<int>.filled(24, 0);
  }

  // ── Computed Getters ────────────────────────────────────────

  double get totalCalories =>
      logs.fold(0.0, (sum, log) => sum + log.loggedCalories);

  double get totalProtein =>
      logs.fold(0.0, (sum, log) => sum + log.loggedProtein);

  double get totalCarbs =>
      logs.fold(0.0, (sum, log) => sum + log.loggedCarbs);

  double get totalFat =>
      logs.fold(0.0, (sum, log) => sum + log.loggedFat);

  double get caloriesRemaining => calorieGoal - totalCalories;

  double get calorieProgress =>
      calorieGoal > 0 ? (totalCalories / calorieGoal).clamp(0.0, 2.0) : 0.0;

  double get proteinProgress =>
      proteinGoalG > 0 ? (totalProtein / proteinGoalG).clamp(0.0, 2.0) : 0.0;

  double get carbsProgress =>
      carbsGoalG > 0 ? (totalCarbs / carbsGoalG).clamp(0.0, 2.0) : 0.0;

  double get fatProgress =>
      fatGoalG > 0 ? (totalFat / fatGoalG).clamp(0.0, 2.0) : 0.0;

  bool get isOverGoal => totalCalories > calorieGoal;

  /// Calories for a specific meal type
  double mealCalories(MealType type) =>
      logs.where((l) => l.mealType == type).fold(0.0, (s, l) => s + l.loggedCalories);

  /// Logs for a specific meal type
  List<MealLog> logsForMeal(MealType type) =>
      logs.where((l) => l.mealType == type).toList();

  /// Water glasses (each glass = 250ml)
  int get waterGlasses => (waterLoggedMl / 250).floor();
  int get waterGoalGlasses => (waterGoalMl / 250).ceil();

  DailyNutrition copyWith({
    DateTime? date,
    List<MealLog>? logs,
    int? calorieGoal,
    double? proteinGoalG,
    double? carbsGoalG,
    double? fatGoalG,
    int? waterGoalMl,
    int? waterLoggedMl,
    List<int>? waterMlPerHour,
  }) {
    return DailyNutrition(
      date: date ?? this.date,
      logs: logs ?? this.logs,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoalG: proteinGoalG ?? this.proteinGoalG,
      carbsGoalG: carbsGoalG ?? this.carbsGoalG,
      fatGoalG: fatGoalG ?? this.fatGoalG,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      waterLoggedMl: waterLoggedMl ?? this.waterLoggedMl,
      waterMlPerHour: waterMlPerHour ?? this.waterMlPerHour,
    );
  }
}
