import 'full_body_recovery_model.dart';

/// Aggregated metrics for workout hub, progress, recovery, and challenges.
class WorkoutHubStats {
  final int currentStreak;
  final int longestStreak;
  final int weeklyCompleted;
  final int weeklyGoal;
  final double recoveryScore;
  final String recoveryLabel;
  final int caloriesThisWeek;
  final int caloriesToday;
  final String trainingLoad;
  final int bodyBattery;
  final List<int> workoutsByWeekday;
  final List<int> caloriesByWeekday;
  final int totalMinutesThisWeek;
  final Map<String, double> muscleVolume;
  final Map<String, double> muscleRecovery; // recovery % (0.0 to 1.0)
  final FullBodyRecoveryState? fullBodyRecoveryState;
  final String topMuscleGroup;
  final int totalSessions;
  final int monthlyWorkouts;
  final int monthlyGoal;
  final int avgDurationMinutes;
  final int totalCaloriesAllTime;
  final double totalVolumeThisWeek;
  final double totalVolumeLastWeek;
  final bool trainedToday;
  final bool completedWeeklyGoal;

  const WorkoutHubStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weeklyCompleted = 0,
    this.weeklyGoal = 3,
    this.recoveryScore = 70,
    this.recoveryLabel = 'Fair',
    this.caloriesThisWeek = 0,
    this.caloriesToday = 0,
    this.trainingLoad = 'Low',
    this.bodyBattery = 70,
    this.workoutsByWeekday = const [0, 0, 0, 0, 0, 0, 0],
    this.caloriesByWeekday = const [0, 0, 0, 0, 0, 0, 0],
    this.totalMinutesThisWeek = 0,
    this.muscleVolume = const {},
    this.muscleRecovery = const {},
    this.fullBodyRecoveryState,
    this.topMuscleGroup = 'Full Body',
    this.totalSessions = 0,
    this.monthlyWorkouts = 0,
    this.monthlyGoal = 12,
    this.avgDurationMinutes = 0,
    this.totalCaloriesAllTime = 0,
    this.totalVolumeThisWeek = 0,
    this.totalVolumeLastWeek = 0,
    this.trainedToday = false,
    this.completedWeeklyGoal = false,
  });

  static const empty = WorkoutHubStats();
}

/// What to show on the hub featured card.
class FeaturedWorkoutSuggestion {
  final String title;
  final String subtitle;
  final String routeId;
  final int durationMin;
  final int estimatedKcal;
  final String difficulty;
  final bool isFromPlan;
  final List<int> gradientArgb;

  const FeaturedWorkoutSuggestion({
    required this.title,
    required this.subtitle,
    required this.routeId,
    required this.durationMin,
    required this.estimatedKcal,
    required this.difficulty,
    this.isFromPlan = false,
    this.gradientArgb = const [0xFF1F2937, 0xFF374151],
  });
}

class DynamicChallenge {
  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final double target;
  final bool isMonthly;

  const DynamicChallenge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.target,
    this.isMonthly = false,
  });

  double get percent => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0;
}

class DynamicProgram {
  final String id;
  final String title;
  final String durationLabel;
  final String difficulty;
  final String goal;
  final int workoutsPerWeek;
  final int totalWeeks;
  final double progress;
  final List<int> gradientArgb;

  const DynamicProgram({
    required this.id,
    required this.title,
    required this.durationLabel,
    required this.difficulty,
    required this.goal,
    required this.workoutsPerWeek,
    required this.totalWeeks,
    required this.progress,
    this.gradientArgb = const [0xFF1E3A5F, 0xFF0F172A],
  });
}

class RecoveryFactor {
  final String name;
  final String value;
  final String status;
  final String statusLabel;

  const RecoveryFactor({
    required this.name,
    required this.value,
    required this.status,
    required this.statusLabel,
  });
}
