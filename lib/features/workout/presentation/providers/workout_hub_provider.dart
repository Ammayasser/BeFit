import 'package:befit/core/achievements/engine/achievement_event_bus.dart';
import 'package:befit/core/achievements/models/achievement_event.dart';
import 'package:flutter/material.dart';

import '../../../profile/presentation/providers/user_provider.dart';

import '../../data/models/workout_hub_stats.dart';
import '../../data/repositories/workout_stats_repository.dart';
import '../../data/models/fitbod_workout_model.dart';
import '../../data/models/muscle_recovery_model.dart';
import '../../data/models/should_block_result.dart';
import 'workout_history_provider.dart';

class WorkoutHubProvider extends ChangeNotifier {
  final WorkoutStatsRepository _statsRepo;

  WorkoutHubProvider({WorkoutStatsRepository? statsRepo})
    : _statsRepo = statsRepo ?? WorkoutStatsRepository();

  WorkoutHubStats _stats = WorkoutHubStats.empty;
  FeaturedWorkoutSuggestion? _featured;
  List<DynamicChallenge> _challenges = [];
  List<DynamicProgram> _programs = [];
  List<RecoveryFactor> _recoveryFactors = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  WorkoutHubStats get stats => _stats;
  FeaturedWorkoutSuggestion? get featured => _featured;
  List<DynamicChallenge> get challenges => _challenges;
  List<DynamicProgram> get programs => _programs;
  List<RecoveryFactor> get recoveryFactors => _recoveryFactors;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  bool get suggestRecovery =>
      _stats.recoveryScore < 65 ||
      (_stats.trainedToday && _stats.trainingLoad == 'High');

  ShouldBlockResult shouldBlockWorkout(FitbodWorkout workout) {
    if (_stats.fullBodyRecoveryState == null) {
      return const ShouldBlockResult(shouldBlock: false);
    }
    
    final fatigued = <MuscleRecoveryState>[];
    for (final muscle in workout.primaryMuscles) {
      final key = muscle.toLowerCase().trim();
      final state = _stats.fullBodyRecoveryState!.muscles[key];
      if (state != null && state.recoveryTier == RecoveryTier.fatigued) {
        fatigued.add(state);
      }
    }
    
    return ShouldBlockResult(
      shouldBlock: fatigued.isNotEmpty,
      fatiguedMuscles: fatigued,
    );
  }

  Future<void> refresh({
    required String userId,
    String? legacyUserId,
    required UserProvider user,
    WorkoutHistoryProvider? historyProvider,
    bool forceHistoryRefresh = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _statsRepo.migrateLegacyUserId(userId, legacyUserId);

      final weight = user.weight > 0 ? user.weight : 70.0;
      final weeklyGoal = user.workoutDays >= 2 && user.workoutDays <= 7
          ? user.workoutDays
          : 4;

      _stats = await _statsRepo.buildHubStats(
        userId: userId,
        userWeightKg: weight,
        weeklyGoalDays: weeklyGoal,
      );

      _challenges = _statsRepo.buildChallenges(_stats);
      _recoveryFactors = _statsRepo.buildRecoveryFactors(_stats);
      _featured = _resolveFeatured(stats: _stats, user: user);
      _programs = _resolvePrograms(stats: _stats);
      _isInitialized = true;

      // 🏆 Broadcast achievement event
      AchievementEventBus().fire(
        AchievementEvent(
          type: AchievementEventType.streakUpdated,
          userId: userId,
          data: {'streak_count': _stats.currentStreak},
        ),
      );

      if (historyProvider != null && forceHistoryRefresh) {
        await historyProvider.loadHistory(userId);
      }
    } catch (e, st) {
      debugPrint('[WorkoutHubProvider] refresh error: $e\n$st');
      _error = 'Could not load workout stats';
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _stats = WorkoutHubStats.empty;
    _featured = null;
    _challenges = [];
    _programs = [];
    _recoveryFactors = [];
    _error = null;
    _isInitialized = false;
    notifyListeners();
  }

  FeaturedWorkoutSuggestion _resolveFeatured({
    required WorkoutHubStats stats,
    required UserProvider user,
  }) {
    if (suggestRecovery) {
      return FeaturedWorkoutSuggestion(
        title: 'Active Recovery',
        subtitle: 'Recommended after ${stats.trainingLoad.toLowerCase()} load',
        routeId: 'recovery',
        durationMin: 15,
        estimatedKcal: 100,
        difficulty: 'Beginner',
        gradientArgb: const [0xFF2A2A1A, 0xFF1B1B0D],
      );
    }

    return FeaturedWorkoutSuggestion(
      title: 'Full Body',
      subtitle: 'Strength',
      routeId: 'featured',
      durationMin: 45,
      estimatedKcal: 350,
      difficulty: 'Intermediate',
      gradientArgb: const [0xFF1E3A5F, 0xFF0F172A],
    );
  }

  List<DynamicProgram> _resolvePrograms({
    required WorkoutHubStats stats,
  }) {
    final list = <DynamicProgram>[];
    // Plan based programs removed
    return list;
  }
}
