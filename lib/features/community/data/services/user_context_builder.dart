import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/user_context.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../../nutrition/presentation/providers/nutrition_provider.dart';
import '../../../workout/data/repositories/workout_log_repository.dart';
import '../../../workout/data/models/workout_history_entry.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserContextBuilder {
  static Future<UserContext> build(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    final authProvider = context.read<AuthProvider>();
    final profile = userProvider.profile;

    // ── Profile fields ────────────────────────────────────────
    final name = profile?.name ?? 'Athlete';
    final age = profile?.age ?? 25;
    final gender = profile?.gender ?? 'Male';
    final heightCm = profile?.height ?? 175.0;
    final weightKg = profile?.weight ?? 75.0;
    final fitnessGoal = _mapGoal(profile?.fitnessGoal ?? 'BuildMuscle');
    final activityLevel = _mapActivity(profile?.activityLevel ?? 'Moderate');
    final experienceLevel = _mapExperience(profile?.experienceLevel ?? 'Intermediate');
    final workoutLocation = profile?.workoutLocation ?? 'gym';
    final workoutDays = profile?.workoutDays ?? 4;
    final primaryEquipment = _mapEquipment(workoutLocation);

    // ── BMI & TDEE ────────────────────────────────────────────
    final heightM = heightCm / 100;
    final bmi = heightM > 0 ? weightKg / (heightM * heightM) : 0.0;
    final tdee = _estimateTDEE(weightKg, heightCm, age, gender, activityLevel);
    final proteinTarget = weightKg * 2.0; // 2g per kg body weight

    // ── Today's nutrition ─────────────────────────────────────
    final daily = nutritionProvider.dailyNutrition;
    final caloriesToday = daily.totalCalories.round();
    final calorieGoal = daily.calorieGoal > 0 ? daily.calorieGoal : tdee.round();
    final proteinToday = daily.totalProtein;
    final carbsToday = daily.totalCarbs;
    final fatToday = daily.totalFat;
    final waterToday = daily.waterLoggedMl;
    final waterGoal = daily.waterGoalMl;

    // ── Workout history ───────────────────────────────────────
    final userId = authProvider.userId ?? '';
    final logRepo = WorkoutLogRepository();
    List<WorkoutHistoryEntry> history = [];
    try {
      history = await logRepo.getWorkoutHistory(userId);
    } catch (_) {}

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final workoutsThisWeek = history.where((e) {
      final d = DateTime.tryParse(e.date) ?? DateTime(2000);
      return !d.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day));
    }).length;

    int streak = 0;
    final dayKeys = <String>{};
    for (final e in history) { dayKeys.add(e.date); }
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      if (dayKeys.contains(key)) { streak++; } else if (i > 0) { break; }
    }

    final recentFocuses = history.take(5).map((e) => e.focus ?? '').where((f) => f.isNotEmpty).toList();
    final lastEntry = history.isNotEmpty ? history.first : null;

    return UserContext(
      name: name,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      fitnessGoal: fitnessGoal,
      activityLevel: activityLevel,
      experienceLevel: experienceLevel,
      workoutLocation: workoutLocation,
      workoutDaysPerWeek: workoutDays,
      bmi: bmi,
      tdee: tdee,
      proteinTargetG: proteinTarget,
      caloriesToday: caloriesToday,
      calorieGoal: calorieGoal,
      proteinTodayG: proteinToday,
      carbsTodayG: carbsToday,
      fatTodayG: fatToday,
      waterTodayMl: waterToday,
      waterGoalMl: waterGoal,
      totalWorkoutsAllTime: history.length,
      workoutsThisWeek: workoutsThisWeek,
      currentStreakDays: streak,
      lastWorkoutDate: lastEntry?.date,
      lastWorkoutFocus: lastEntry?.focus,
      recentWorkoutFocuses: recentFocuses,
      primaryEquipment: primaryEquipment,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  static double _estimateTDEE(double weight, double height, int age, String gender, String activity) {
    // Mifflin-St Jeor BMR
    double bmr = gender.toLowerCase() == 'male'
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    const multipliers = {
      'Sedentary': 1.2,
      'Lightly Active': 1.375,
      'Moderate': 1.55,
      'Active': 1.725,
      'Very Active': 1.9,
    };
    return bmr * (multipliers[activity] ?? 1.55);
  }

  static String _mapGoal(String raw) => switch (raw.toLowerCase()) {
    'buildmuscle' || 'muscle' => 'Build Muscle & Gain Mass',
    'losefat' || 'weightloss' || 'lose_fat' => 'Lose Fat & Get Lean',
    'strength' => 'Build Pure Strength',
    'endurance' => 'Improve Endurance',
    'recomposition' || 'recomp' => 'Body Recomposition',
    _ => raw,
  };

  static String _mapActivity(String raw) => switch (raw.toLowerCase()) {
    'sedentary' => 'Sedentary',
    'light' || 'lightly_active' => 'Lightly Active',
    'moderate' || 'moderately_active' => 'Moderate',
    'active' || 'very_active' => 'Active',
    _ => 'Moderate',
  };

  static String _mapExperience(String raw) => switch (raw.toLowerCase()) {
    'beginner' || 'novice' => 'Beginner',
    'intermediate' => 'Intermediate',
    'advanced' || 'expert' => 'Advanced',
    _ => 'Intermediate',
  };

  static String _mapEquipment(String location) => switch (location.toLowerCase()) {
    'gym' => 'barbell, dumbbells, cables, machines',
    'home' => 'dumbbells, resistance bands',
    'outdoor' || 'bodyweight' => 'bodyweight only',
    _ => 'dumbbells, barbell',
  };
}
