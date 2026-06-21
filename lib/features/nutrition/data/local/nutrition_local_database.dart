// lib/features/nutrition/data/local/nutrition_local_database.dart
//
// Per-user SQLite persistence for nutrition: meal logs (by meal type / day)
// and hydration (daily totals + hourly breakdown).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/daily_nutrition.dart';
import '../models/meal_log.dart';

/// SQLite access for nutrition + hydration. All operations are scoped by [userId].
class NutritionLocalDatabase {
  NutritionLocalDatabase._();
  static final NutritionLocalDatabase instance = NutritionLocalDatabase._();

  static const _importFlagPrefix = '_nutrition_sqlite_import_v1_';

  /// Stable `yyyy-MM-dd` for primary keys and queries.
  static String dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _startOfWeekMonday(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// One-time migration from legacy `nutrition_<userId>_<y>_<m>_<d>` SharedPreferences blobs.
  Future<void> importLegacySharedPreferencesForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final flag = '$_importFlagPrefix$userId';
    if (prefs.getBool(flag) == true) return;

    final prefix = 'nutrition_${userId}_';
    for (final key in List<String>.from(prefs.getKeys())) {
      if (!key.startsWith(prefix)) continue;
      final suffix = key.substring(prefix.length);
      final segs = suffix.split('_');
      if (segs.length != 3) continue;
      final y = int.tryParse(segs[0]);
      final mo = int.tryParse(segs[1]);
      final da = int.tryParse(segs[2]);
      if (y == null || mo == null || da == null) continue;

      final raw = prefs.getString(key);
      if (raw == null) continue;

      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final logsJson = data['logs'] as List? ?? [];
        final logs = logsJson
            .map((j) => MealLog.fromJson(j as Map<String, dynamic>))
            .toList();
        final water = (data['waterLoggedMl'] as num?)?.toInt() ?? 0;
        List<int>? perHour;
        final hourRaw = data['waterMlPerHour'];
        if (hourRaw is List && hourRaw.length == 24) {
          perHour = hourRaw.map((e) => (e as num).toInt()).toList();
        }
        final day = DateTime(y, mo, da);
        final nutrition = DailyNutrition(
          date: day,
          logs: logs,
          waterLoggedMl: water,
          waterMlPerHour: perHour,
        );
        await saveDay(userId, day, nutrition);
        await prefs.remove(key);
      } catch (e, st) {
        debugPrint('NutritionLocalDatabase: skip legacy key $key: $e\n$st');
      }
    }

    await prefs.setBool(flag, true);
  }

  /// Loads a single calendar day for [userId]. Returns `null` if nothing stored.
  Future<DailyNutrition?> loadDay(String userId, DateTime date) async {
    debugPrint('NutritionLocalDatabase: loadDay for user "$userId" on $date');
    if (userId.isEmpty || userId == 'null') {
      debugPrint('NutritionLocalDatabase: WARNING: userId is invalid!');
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final dk = dateKey(date);

      final dailyRows = await db.query(
        'nutrition_daily',
        columns: [
          'calorie_goal',
          'protein_goal',
          'carbs_goal',
          'fat_goal',
          'water_goal',
          'water_logged_ml',
          'water_hourly_json'
        ],
        where: 'user_id = ? AND date_key = ?',
        whereArgs: [userId, dk],
        limit: 1,
      );

      final mealRows = await db.query(
        'nutrition_meal_logs',
        where: 'user_id = ? AND date_key = ?',
        whereArgs: [userId, dk],
        orderBy: 'logged_at ASC',
      );

      if (mealRows.isEmpty && dailyRows.isEmpty) return null;

      final logs = <MealLog>[];
      for (final row in mealRows) {
        try {
          final jsonStr = row['payload_json'] as String?;
          if (jsonStr == null || jsonStr.isEmpty) continue;
          logs.add(MealLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
        } catch (e) {
          debugPrint('NutritionLocalDatabase: corrupt meal row ${row['id']}: $e');
        }
      }

      var water = 0;
      var calorieGoal = 0;
      var proteinGoal = 0.0;
      var carbsGoal = 0.0;
      var fatGoal = 0.0;
      var waterGoal = 2000;
      List<int>? hourly;

      if (dailyRows.isNotEmpty) {
        final row = dailyRows.first;
        calorieGoal = (row['calorie_goal'] as num?)?.toInt() ?? 0;
        proteinGoal = (row['protein_goal'] as num?)?.toDouble() ?? 0.0;
        carbsGoal = (row['carbs_goal'] as num?)?.toDouble() ?? 0.0;
        fatGoal = (row['fat_goal'] as num?)?.toDouble() ?? 0.0;
        waterGoal = (row['water_goal'] as num?)?.toInt() ?? 2000;
        water = (row['water_logged_ml'] as num?)?.toInt() ?? 0;
        final h = row['water_hourly_json'] as String?;
        if (h != null && h.isNotEmpty) {
          try {
            final list = jsonDecode(h) as List<dynamic>?;
            if (list != null && list.length == 24) {
              hourly = list.map((e) => (e as num).toInt()).toList();
            }
          } catch (_) {}
        }
      }

      return DailyNutrition(
        date: date,
        logs: logs,
        calorieGoal: calorieGoal,
        proteinGoalG: proteinGoal,
        carbsGoalG: carbsGoal,
        fatGoalG: fatGoal,
        waterGoalMl: waterGoal,
        waterLoggedMl: water,
        waterMlPerHour: hourly,
      );
    } catch (e, st) {
      debugPrint('NutritionLocalDatabase: Error loading day: $e\n$st');
      return null;
    }
  }

  /// Replaces all persisted data for that calendar day (meals + water) in one transaction.
  Future<void> saveDay(String userId, DateTime date, DailyNutrition nutrition) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final dk = dateKey(date);
      final hourlyJson = jsonEncode(nutrition.hourlyWaterMl);
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        await txn.delete(
          'nutrition_meal_logs',
          where: 'user_id = ? AND date_key = ?',
          whereArgs: [userId, dk],
        );

        for (final log in nutrition.logs) {
          await txn.insert(
            'nutrition_meal_logs',
            {
              'id': log.id,
              'user_id': userId,
              'date_key': dk,
              'meal_type': log.mealType.index,
              'logged_at': log.loggedAt.toIso8601String(),
              'payload_json': jsonEncode(log.toJson()),
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await txn.insert(
          'nutrition_daily',
          {
            'user_id': userId,
            'date_key': dk,
            'calorie_goal': nutrition.calorieGoal,
            'protein_goal': nutrition.proteinGoalG,
            'carbs_goal': nutrition.carbsGoalG,
            'fat_goal': nutrition.fatGoalG,
            'water_goal': nutrition.waterGoalMl,
            'water_logged_ml': nutrition.waterLoggedMl,
            'water_hourly_json': hourlyJson,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e, st) {
      debugPrint('NutritionLocalDatabase: Error saving day: $e\n$st');
    }
  }

  /// Milliliters logged for each day Mon..Sun of the week containing [anchor].
  Future<List<int>> loadWeekWaterTotals(String userId, DateTime anchor) async {
    final db = await DatabaseHelper.instance.database;
    final start = _startOfWeekMonday(anchor);
    final keys = List.generate(7, (i) => dateKey(start.add(Duration(days: i))));

    final rows = await db.query(
      'nutrition_daily',
      columns: ['date_key', 'water_logged_ml'],
      where:
          'user_id = ? AND date_key IN (?,?,?,?,?,?,?)',
      whereArgs: [userId, ...keys],
    );

    final map = <String, int>{};
    for (final r in rows) {
      map[r['date_key'] as String] = (r['water_logged_ml'] as num?)?.toInt() ?? 0;
    }

    return List.generate(7, (i) => map[keys[i]] ?? 0);
  }

  /// Loads the [limit] most recent meals across all days for [userId].
  Future<List<MealLog>> loadRecentMeals(String userId, {int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'nutrition_meal_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC',
      limit: limit,
    );

    final logs = <MealLog>[];
    for (final row in rows) {
      try {
        final jsonStr = row['payload_json'] as String?;
        if (jsonStr == null || jsonStr.isEmpty) continue;
        logs.add(MealLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('NutritionLocalDatabase: corrupt meal row ${row['id']}: $e');
      }
    }
    return logs;
  }

  /// Removes all nutrition rows for [userId] (e.g. account deletion).
  Future<void> deleteAllForUser(String userId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('nutrition_meal_logs', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('nutrition_daily', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('recent_food_searches', where: 'user_id = ?', whereArgs: [userId]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_importFlagPrefix$userId');
  }

  /// Deletes a single meal log by [logId].
  Future<void> deleteMealLog(String logId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'nutrition_meal_logs',
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  /// Updates only the goal columns for a specific day.
  Future<void> updateDailyGoals(
    String userId,
    DateTime date, {
    int? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? waterGoal,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dk = dateKey(date);
    final now = DateTime.now().millisecondsSinceEpoch;

    final values = <String, dynamic>{
      'updated_at': now,
    };
    if (calorieGoal != null) values['calorie_goal'] = calorieGoal;
    if (proteinGoal != null) values['protein_goal'] = proteinGoal;
    if (carbsGoal != null) values['carbs_goal'] = carbsGoal;
    if (fatGoal != null) values['fat_goal'] = fatGoal;
    if (waterGoal != null) values['water_goal'] = waterGoal;

    await db.insert(
      'nutrition_daily',
      {
        'user_id': userId,
        'date_key': dk,
        'water_logged_ml': 0,
        'water_hourly_json': jsonEncode(List<int>.filled(24, 0)),
        ...values,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.update(
      'nutrition_daily',
      values,
      where: 'user_id = ? AND date_key = ?',
      whereArgs: [userId, dk],
    );
  }

  /// Loads aggregated calorie data (eaten vs goal) for each day within [start] and [end].
  Future<List<Map<String, dynamic>>> loadCalorieHistory(String userId, DateTime start, DateTime end) async {
    final db = await DatabaseHelper.instance.database;
    final startDk = dateKey(start);
    final endDk = dateKey(end);

    // 1. Get daily goals
    final dailyRows = await db.query(
      'nutrition_daily',
      columns: ['date_key', 'calorie_goal'],
      where: 'user_id = ? AND date_key >= ? AND date_key <= ?',
      whereArgs: [userId, startDk, endDk],
    );

    // 2. Get all meal logs for the period to calculate total calories per day
    final mealRows = await db.query(
      'nutrition_meal_logs',
      columns: ['date_key', 'payload_json'],
      where: 'user_id = ? AND date_key >= ? AND date_key <= ?',
      whereArgs: [userId, startDk, endDk],
    );

    // Aggregate eaten calories per day
    final dailyEaten = <String, double>{};
    for (final row in mealRows) {
      final dk = row['date_key'] as String;
      try {
        final jsonStr = row['payload_json'] as String?;
        if (jsonStr == null || jsonStr.isEmpty) continue;
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        // Recalculate logged calories from payload
        final food = data['foodItem'] as Map<String, dynamic>;
        final grams = (data['quantityGrams'] as num).toDouble();
        final calPer100 = (food['caloriesPer100g'] as num).toDouble();
        final cal = (calPer100 * grams) / 100;
        
        dailyEaten[dk] = (dailyEaten[dk] ?? 0) + cal;
      } catch (_) {}
    }

    // Combine with goals
    final goalMap = <String, int>{};
    for (final row in dailyRows) {
      goalMap[row['date_key'] as String] = (row['calorie_goal'] as num?)?.toInt() ?? 0;
    }

    // Generate list for all dates in range
    final results = <Map<String, dynamic>>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
      final dk = dateKey(current);
      int goal = goalMap[dk] ?? 0;
      if (goal <= 0) goal = 2000; // Default fallback if no goal set for that day

      results.add({
        'date': current,
        'date_key': dk,
        'eaten': dailyEaten[dk] ?? 0.0,
        'goal': goal,
      });
      current = current.add(const Duration(days: 1));
    }

    return results;
  }

  // ── Recent Searches ───────────────────────────────────────

  /// Saves or updates a search query for [userId].
  Future<void> saveRecentSearch(String userId, String query) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'recent_food_searches',
      {
        'user_id': userId,
        'query': query.trim(),
        'searched_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads the [limit] most recent unique search queries for [userId].
  Future<List<String>> loadRecentSearches(String userId, {int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'recent_food_searches',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return rows.map((r) => r['query'] as String).toList();
  }
}
