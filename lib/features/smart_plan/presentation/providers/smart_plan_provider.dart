// lib/features/smart_plan/presentation/providers/smart_plan_provider.dart

import 'package:flutter/foundation.dart';

import '../../../../features/setup/presentation/providers/setup_provider.dart';
import '../../data/local/smart_plan_local_db.dart';
import '../../data/models/smart_meal_plan.dart';
import '../../data/models/smart_workout_plan.dart';
import '../../data/services/smart_plan_service.dart';

enum SmartPlanStatus { idle, generating, success, error }

class SmartPlanProvider extends ChangeNotifier {
  bool _disposed = false;

  final SmartPlanService _service = SmartPlanService();
  final SmartPlanLocalDb _local = SmartPlanLocalDb.instance;

  SmartMealPlan? _mealPlan;
  List<SmartWorkoutDay>? _workoutDays;

  SmartPlanStatus _status = SmartPlanStatus.idle;
  String? _errorMessage;
  bool _isInitialized = false;

  // ── Getters ───────────────────────────────────────────────────
  SmartMealPlan? get mealPlan => _mealPlan;
  List<SmartWorkoutDay>? get workoutDays => _workoutDays;
  SmartPlanStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  bool get isGenerating => _status == SmartPlanStatus.generating;
  bool get hasWorkoutPlan =>
      _workoutDays != null && _workoutDays!.isNotEmpty;
  bool get hasMealPlan => _mealPlan != null;
  bool get hasPlan => hasWorkoutPlan || hasMealPlan;

  Future<void> loadPlans(String userId) async {
    final meal = await _local.loadMealPlan(userId);
    final workout = await _local.loadWorkoutPlan(userId);

    _mealPlan = meal;
    _workoutDays = workout;

    if (hasPlan) _status = SmartPlanStatus.success;
    _isInitialized = true;
    _notify();
  }

  // ── Generate plans after setup ────────────────────────────────
  /// Generates both plans in parallel and saves them locally.
  /// Returns true if at least one plan was generated successfully.
  Future<bool> generatePlans({
    required SetupProvider setup,
    required String userId,
    void Function(String stage)? onStageChange,
  }) async {
    _status = SmartPlanStatus.generating;
    _errorMessage = null;
    _notify();

    try {
      onStageChange?.call('Analyzing your profile...');

      // Run both in parallel
      final results = await Future.wait([
        _service.generateMealPlan(setup, onStatusUpdate: onStageChange),
        _service.generateWorkoutPlan(setup, onStatusUpdate: onStageChange),
      ]);

      final mealResult = results[0] as SmartMealPlan?;
      final workoutResult = results[1] as List<SmartWorkoutDay>?;

      onStageChange?.call('Saving your personalized plans...');

      if (mealResult != null) {
        _mealPlan = mealResult;
        await _local.saveMealPlan(userId, mealResult);
      }

      if (workoutResult != null && workoutResult.isNotEmpty) {
        _workoutDays = workoutResult;
        await _local.saveWorkoutPlan(userId, workoutResult);
      }

      if (hasPlan) {
        _status = SmartPlanStatus.success;
        _notify();
        return true;
      } else {
        _status = SmartPlanStatus.error;
        _errorMessage = 'Could not generate plans. Please try again.';
        _notify();
        return false;
      }
    } catch (e) {
      _status = SmartPlanStatus.error;
      _errorMessage = 'An error occurred: $e';
      _notify();
      return false;
    }
  }

  /// Clears plans and re-generates — useful for "Regenerate" button.
  Future<bool> regeneratePlans({
    required SetupProvider setup,
    required String userId,
    void Function(String stage)? onStageChange,
  }) async {
    await _local.clearAll(userId);
    _mealPlan = null;
    _workoutDays = null;
    return generatePlans(
        setup: setup, userId: userId, onStageChange: onStageChange);
  }

  // ── Custom Workout Plan Generation ───────────────────────────
  
  /// Generates a specific workout plan with provided configuration.
  /// This is used by the SmartWorkoutGeneratorScreen.
  Future<List<SmartWorkoutDay>?> generateCustomWorkoutPlan({
    required String goal,
    required String experience,
    required String location,
    required int daysPerWeek,
    required int durationMinutes,
    void Function(String status)? onStatusUpdate,
  }) async {
    _status = SmartPlanStatus.generating;
    _errorMessage = null;
    _notify();

    int retries = 0;
    const int maxProviderRetries = 2;
    while (retries < maxProviderRetries) {
      try {
        if (retries > 0) {
          onStatusUpdate?.call('Crafting your workout plan...');
        }

        final workoutResult = await _service.generateWorkoutPlanWithConfig(
          goal: goal,
          experience: experience,
          location: location,
          daysPerWeek: daysPerWeek,
          durationMinutes: durationMinutes,
        );

        if (workoutResult != null && workoutResult.isNotEmpty) {
          _status = SmartPlanStatus.success;
          _notify();
          return workoutResult;
        }

        // If we got null, it might be a transient error that the service didn't catch
        // or it reached its internal retry limit. We'll wait and try again here.
        retries++;
        if (retries < maxProviderRetries) {
          final delay = (retries * 5).clamp(5, 30);
          onStatusUpdate?.call('Crafting your workout plan...');
          await Future.delayed(Duration(seconds: delay));
        }
      } catch (e) {
        retries++;
        if (retries < maxProviderRetries) {
          final delay = (retries * 5).clamp(5, 30);
          debugPrint('SmartPlanProvider: Custom generation exception: $e. Retrying...');
          await Future.delayed(Duration(seconds: delay));
        }
      }
    }

    // Ultimate fallback if service call failed completely (or threw)
    debugPrint('SmartPlanProvider: Direct provider fallback path triggered.');
    final parsedDays = await _service.fallbackParsedDays();
    if (parsedDays.isNotEmpty) {
      _status = SmartPlanStatus.success;
      _notify();
      return parsedDays;
    }

    _status = SmartPlanStatus.error;
    _errorMessage = 'Could not generate plan after multiple attempts.';
    _notify();
    return null;
  }

  /// Update only the workout plan portion
  Future<void> updateWorkoutPlan(String userId, List<SmartWorkoutDay> newDays) async {
    _workoutDays = newDays;
    await _local.saveWorkoutPlan(userId, newDays);
    _status = SmartPlanStatus.success;
    _notify();
  }

  /// Clear plans on logout
  void reset() {
    _mealPlan = null;
    _workoutDays = null;
    _status = SmartPlanStatus.idle;
    _errorMessage = null;
    _isInitialized = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
