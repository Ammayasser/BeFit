import '../models/workout_history_entry.dart';
import '../models/workout_hub_stats.dart';
import '../models/workout_models.dart';
import 'workout_log_repository.dart';
import 'muscle_engagement_repository.dart';
import '../services/recovery_engine.dart';

/// Computes hub / progress / recovery metrics from [workout_logs] and [set_logs].
class WorkoutStatsRepository {
  final WorkoutLogRepository _logs;
  final MuscleEngagementRepository _engagementRepo;

  WorkoutStatsRepository({
    WorkoutLogRepository? logs,
    MuscleEngagementRepository? engagementRepo,
  }) : _logs = logs ?? WorkoutLogRepository(),
       _engagementRepo = engagementRepo ?? MuscleEngagementRepository();

  Future<void> migrateLegacyUserId(String canonicalId, String? legacyId) async {
    if (legacyId == null || legacyId.isEmpty || legacyId == canonicalId) return;
    final db = await _logs.database;
    await db.update(
      'workout_logs',
      {'user_id': canonicalId},
      where: 'user_id = ?',
      whereArgs: [legacyId],
    );
    await db.update(
      'set_logs',
      {'user_id': canonicalId},
      where: 'user_id = ?',
      whereArgs: [legacyId],
    );
  }

  Future<WorkoutHubStats> buildHubStats({
    required String userId,
    required double userWeightKg,
    required int weeklyGoalDays,
  }) async {
    final history = await _logs.getWorkoutHistory(userId);
    if (history.isEmpty) {
      return WorkoutHubStats(
        weeklyGoal: weeklyGoalDays.clamp(1, 7),
        monthlyGoal: _monthlyGoal(weeklyGoalDays),
        recoveryLabel: _recoveryLabel(85),
        recoveryScore: 85,
        bodyBattery: 85,
        trainingLoad: 'Low',
        fullBodyRecoveryState: RecoveryEngine.computeRecovery([]),
      );
    }

    final now = DateTime.now();
    final todayStr = _dateKey(now);
    final weekStart = _startOfWeek(now);
    final monthStart = DateTime(now.year, now.month, 1);
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    final streak = _computeStreak(history, todayStr);
    final longest = _computeLongestStreak(history);

    // FIX: Ensure week Start is midnight Monday for consistent filtering
    final startOfThisWeek = _startOfWeek(now);

    final thisWeek = history.where((e) {
      final d = _parseDate(e.date);
      return !d.isBefore(startOfThisWeek);
    }).toList();

    final thisMonth = history
        .where((e) => !_parseDate(e.date).isBefore(monthStart))
        .toList();

    final weeklyCompleted = thisWeek.map((e) => e.date).toSet().length;
    final trainedToday = history.any((e) => e.date == todayStr);

    var caloriesWeek = 0;
    var caloriesToday = 0;
    var totalDuration = 0;
    var volumeWeek = 0.0;
    var volumeLast = 0.0;
    var caloriesAll = 0;
    var minutesThisWeek = 0;

    final byWeekday = List<int>.filled(7, 0);
    final caloriesByWeekday = List<int>.filled(7, 0);

    for (final e in history) {
      final kcal = estimateCaloriesFromLog(e, userWeightKg);
      caloriesAll += kcal;
      totalDuration += e.durationSeconds;

      // Weekly aggregation
      final entryDate = _parseDate(e.date);
      if (!entryDate.isBefore(startOfThisWeek)) {
        caloriesWeek += kcal;
        volumeWeek += e.totalVolume;
        minutesThisWeek += (e.durationSeconds ~/ 60);

        final wd = entryDate.weekday;
        byWeekday[wd - 1]++;
        caloriesByWeekday[wd - 1] += kcal;
      } else if (!entryDate.isBefore(lastWeekStart) &&
          entryDate.isBefore(startOfThisWeek)) {
        volumeLast += e.totalVolume;
      }

      if (e.date == todayStr) {
        caloriesToday += kcal;
      }
    }

    final avgMin = history.isEmpty
        ? 0
        : (totalDuration ~/ history.length) ~/ 60;

    final muscleVolume = await _logs.getMuscleVolumeByGroup(userId, days: 28);
    final lastTrained = await _logs.getLastTrainedDatesByGroup(userId);
    final recoveryMap = <String, double>{};

    // Normalize "now" to midnight for calendar day comparison
    final today = DateTime(now.year, now.month, now.day);

    for (final group in lastTrained.keys) {
      final lastDateRaw = lastTrained[group]!;
      final lastDate = DateTime(
        lastDateRaw.year,
        lastDateRaw.month,
        lastDateRaw.day,
      );
      final daysSince = today.difference(lastDate).inDays;

      final normalizedKey = group.toLowerCase().trim();

      if (daysSince == 0) {
        recoveryMap[normalizedKey] = 0.2; // Fatigued
      } else if (daysSince == 1) {
        recoveryMap[normalizedKey] = 0.5; // Active
      } else {
        recoveryMap[normalizedKey] = 1.0; // Fresh
      }
    }

    final topMuscle = muscleVolume.entries.isEmpty
        ? 'Full Body'
        : (muscleVolume.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key);

    // Compute advanced full body recovery state
    final engagements = await _engagementRepo.getEngagementsByUser(
      userId,
      since: now.subtract(const Duration(days: 3)),
    );
    final fullBodyState = RecoveryEngine.computeRecovery(engagements);

    final recovery = _computeRecovery(
      history: history,
      trainedToday: trainedToday,
      volumeThisWeek: volumeWeek,
      weeklyGoal: weeklyGoalDays,
      weeklyCompleted: weeklyCompleted,
    );

    // Use advanced readiness score if available and meaningful (not default 1.0 without data)
    final advancedScore = fullBodyState.overallReadinessScore;
    final finalRecoveryScore = engagements.isNotEmpty
        ? (advancedScore * 100).clamp(35, 98).toDouble()
        : recovery.score;

    final load = _trainingLoad(volumeWeek, volumeLast, weeklyCompleted);
    final battery =
        (100 -
                (trainedToday ? 12 : 0) -
                (load == 'High'
                    ? 18
                    : load == 'Moderate'
                    ? 8
                    : 0))
            .clamp(40, 100)
            .toInt();

    return WorkoutHubStats(
      currentStreak: streak,
      longestStreak: longest,
      weeklyCompleted: weeklyCompleted,
      weeklyGoal: weeklyGoalDays.clamp(1, 7),
      recoveryScore: finalRecoveryScore,
      recoveryLabel: _recoveryLabel(finalRecoveryScore),
      caloriesThisWeek: caloriesWeek,
      caloriesToday: caloriesToday,
      trainingLoad: load,
      bodyBattery: battery,
      workoutsByWeekday: byWeekday,
      caloriesByWeekday: caloriesByWeekday,
      totalMinutesThisWeek: minutesThisWeek,
      muscleVolume: muscleVolume,
      muscleRecovery: recoveryMap,
      fullBodyRecoveryState: fullBodyState,
      topMuscleGroup: topMuscle,
      totalSessions: history.length,
      monthlyWorkouts: thisMonth.length,
      monthlyGoal: _monthlyGoal(weeklyGoalDays),
      avgDurationMinutes: avgMin,
      totalCaloriesAllTime: caloriesAll,
      totalVolumeThisWeek: volumeWeek,
      totalVolumeLastWeek: volumeLast,
      trainedToday: trainedToday,
      completedWeeklyGoal: weeklyCompleted >= weeklyGoalDays,
    );
  }

  List<DynamicChallenge> buildChallenges(WorkoutHubStats stats) {
    return [
      DynamicChallenge(
        id: 'monthly_workouts',
        title: 'Monthly Workouts',
        subtitle: 'Complete ${stats.monthlyGoal} sessions this month',
        progress: stats.monthlyWorkouts.toDouble(),
        target: stats.monthlyGoal.toDouble(),
        isMonthly: true,
      ),
      DynamicChallenge(
        id: 'streak_14',
        title:
            '${stats.longestStreak > 0 ? stats.longestStreak : 14}-Day Streak',
        subtitle: 'Work out on consecutive days',
        progress: stats.currentStreak.toDouble(),
        target: 14,
      ),
      DynamicChallenge(
        id: 'weekly_goal',
        title: 'Weekly Goal',
        subtitle: '${stats.weeklyGoal} workouts per week',
        progress: stats.weeklyCompleted.toDouble(),
        target: stats.weeklyGoal.toDouble(),
      ),
    ];
  }

  List<RecoveryFactor> buildRecoveryFactors(WorkoutHubStats stats) {
    final sleepHours = 6.5 + (stats.recoveryScore / 100) * 2;
    final soreness = stats.trainingLoad == 'High'
        ? 'Elevated'
        : stats.trainingLoad == 'Moderate'
        ? 'Moderate'
        : 'Low';
    String label(String status) => switch (status) {
      'Low' || 'Good' => 'Good',
      'Moderate' || 'Fair' => 'Fair',
      _ => 'Low',
    };

    return [
      RecoveryFactor(
        name: 'Sleep',
        value: '${sleepHours.toStringAsFixed(1)}h est.',
        status: stats.recoveryScore >= 75 ? 'Good' : 'Fair',
        statusLabel: label(stats.recoveryScore >= 75 ? 'Good' : 'Fair'),
      ),
      RecoveryFactor(
        name: 'Training load',
        value: stats.trainingLoad,
        status: stats.trainingLoad == 'High' ? 'Fair' : 'Good',
        statusLabel: label(stats.trainingLoad == 'High' ? 'Fair' : 'Good'),
      ),
      RecoveryFactor(
        name: 'Soreness',
        value: soreness,
        status: soreness == 'Low' ? 'Good' : 'Fair',
        statusLabel: label(soreness == 'Low' ? 'Good' : 'Fair'),
      ),
      RecoveryFactor(
        name: 'Readiness',
        value: '${stats.bodyBattery}/100',
        status: stats.bodyBattery >= 70 ? 'Good' : 'Fair',
        statusLabel: label(stats.bodyBattery >= 70 ? 'Good' : 'Fair'),
      ),
    ];
  }

  static int estimateCaloriesFromLog(
    WorkoutHistoryEntry entry,
    double weightKg,
  ) {
    final hours = entry.durationSeconds / 3600.0;
    if (hours <= 0) return (entry.totalVolume * 0.05).round().clamp(50, 800);
    final met = 5.0 + (entry.totalVolume / 2000).clamp(0.0, 3.0);
    return (met * weightKg.clamp(40, 150) * hours).round().clamp(80, 1200);
  }

  static int estimateCaloriesForSession(
    WorkoutSession session,
    double weightKg,
  ) {
    final hours = session.duration.inSeconds / 3600.0;
    if (hours <= 0) return (session.totalVolume * 0.05).round().clamp(50, 800);
    final mets = session.exercises.map((e) => e.met ?? 3.5).toList();
    final avgMet = mets.isEmpty
        ? 5.0
        : mets.reduce((a, b) => a + b) / mets.length;
    return (avgMet * weightKg.clamp(40, 150) * hours).round().clamp(80, 1200);
  }

  static int _monthlyGoal(int weeklyDays) =>
      (weeklyDays.clamp(2, 6) * 4).clamp(8, 24);

  static String _recoveryLabel(double score) {
    if (score >= 80) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Low';
  }

  static ({double score, String label}) _computeRecovery({
    required List<WorkoutHistoryEntry> history,
    required bool trainedToday,
    required double volumeThisWeek,
    required int weeklyGoal,
    required int weeklyCompleted,
  }) {
    var score = 88.0;
    if (trainedToday) score -= 14;
    if (volumeThisWeek > 15000) {
      score -= 12;
    } else if (volumeThisWeek > 8000)
      score -= 6;
    if (weeklyCompleted >= weeklyGoal) score -= 4;
    final last = history.isNotEmpty ? _parseDate(history.first.date) : null;
    if (last != null && !trainedToday) {
      final daysSince = DateTime.now().difference(last).inDays;
      if (daysSince >= 2) score += 6;
    }
    score = score.clamp(35, 98);
    return (score: score, label: _recoveryLabel(score));
  }

  static String _trainingLoad(double volWeek, double volLast, int sessions) {
    if (sessions >= 6 || volWeek > 12000) return 'High';
    if (sessions >= 3 || volWeek > 5000 || volWeek > volLast * 1.25)
      return 'Moderate';
    return 'Low';
  }

  static int _computeStreak(
    List<WorkoutHistoryEntry> history,
    String todayStr,
  ) {
    final dates = history.map((e) => e.date).toSet().toList()..sort();
    if (dates.isEmpty) return 0;

    var streak = 0;
    var cursor = _parseDate(todayStr);
    final dateSet = dates.toSet();

    if (!dateSet.contains(todayStr)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (dateSet.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _computeLongestStreak(List<WorkoutHistoryEntry> history) {
    final dates = history.map((e) => _parseDate(e.date)).toSet().toList()
      ..sort();
    if (dates.isEmpty) return 0;
    var best = 1;
    var current = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  static DateTime _parseDate(String d) =>
      DateTime.parse(d.length >= 10 ? d.substring(0, 10) : d);
  static String _dateKey(DateTime d) => d.toIso8601String().substring(0, 10);
  static DateTime _startOfWeek(DateTime now) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
