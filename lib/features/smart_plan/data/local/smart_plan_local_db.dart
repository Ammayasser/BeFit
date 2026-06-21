// lib/features/smart_plan/data/local/smart_plan_local_db.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/smart_meal_plan.dart';
import '../models/smart_workout_plan.dart';

/// Persists the smart plans using SharedPreferences (JSON encoded).
/// Lightweight — no extra tables needed, plans are small JSON blobs.
class SmartPlanLocalDb {
  SmartPlanLocalDb._();
  static final SmartPlanLocalDb instance = SmartPlanLocalDb._();

  static String _mealKey(String userId) => 'smart_meal_plan_$userId';
  static String _workoutKey(String userId) => 'smart_workout_plan_$userId';

  // ── Meal Plan ─────────────────────────────────────────────────

  Future<void> saveMealPlan(String userId, SmartMealPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mealKey(userId), jsonEncode(plan.toJson()));
    } catch (e) {
      debugPrint('SmartPlanLocalDb: saveMealPlan error: $e');
    }
  }

  Future<SmartMealPlan?> loadMealPlan(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_mealKey(userId));
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SmartMealPlan.fromJson(json);
    } catch (e) {
      debugPrint('SmartPlanLocalDb: loadMealPlan error: $e');
      return null;
    }
  }

  Future<void> deleteMealPlan(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mealKey(userId));
    } catch (e) {
      debugPrint('SmartPlanLocalDb: deleteMealPlan error: $e');
    }
  }

  // ── Workout Plan ──────────────────────────────────────────────

  Future<void> saveWorkoutPlan(
      String userId, List<SmartWorkoutDay> days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(days.map((d) => d.toJson()).toList());
      await prefs.setString(_workoutKey(userId), encoded);
    } catch (e) {
      debugPrint('SmartPlanLocalDb: saveWorkoutPlan error: $e');
    }
  }

  Future<List<SmartWorkoutDay>?> loadWorkoutPlan(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_workoutKey(userId));
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((d) => SmartWorkoutDay.fromJson(d))
          .toList();
    } catch (e) {
      debugPrint('SmartPlanLocalDb: loadWorkoutPlan error: $e');
      return null;
    }
  }

  Future<void> deleteWorkoutPlan(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_workoutKey(userId));
    } catch (e) {
      debugPrint('SmartPlanLocalDb: deleteWorkoutPlan error: $e');
    }
  }

  Future<void> clearAll(String userId) async {
    await deleteMealPlan(userId);
    await deleteWorkoutPlan(userId);
  }
}
