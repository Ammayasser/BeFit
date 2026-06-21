import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/workout_models.dart';
import '../models/fitbod_workout_model.dart';

class FitbodDataLoader {
  final DatabaseHelper _dbHelper;
  static const String _prefKey = 'fitbod_data_loaded_v1';

  FitbodDataLoader({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<bool> isLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLoaded = prefs.getBool(_prefKey) ?? false;
    if (!hasLoaded) return false;
    
    // Safety check: ensure we actually have records
    try {
      final db = await _dbHelper.database;
      final exerciseCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM exercises_library'),
      ) ?? 0;
      final workoutCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM fitbod_workouts'),
      ) ?? 0;
      
      return exerciseCount > 0 && workoutCount > 0;
    } catch (e) {
      debugPrint('[FitbodDataLoader] Safety check failed, forcing re-load: $e');
      return false;
    }
  }

  Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
  }

  // Isolate entry point
  static Map<String, dynamic> _decodeJson(String source) {
    return jsonDecode(source) as Map<String, dynamic>;
  }

  Future<bool> loadFromAssets(void Function(double progress) onProgress) async {
    try {
      debugPrint('[FitbodDataLoader] Starting data loading from assets...');
      onProgress(0.05);

      final String jsonStr = await rootBundle.loadString('assets/data/fitbod_data_for_app.json');
      onProgress(0.15);

      debugPrint('[FitbodDataLoader] JSON loaded, parsing on background thread...');
      final Map<String, dynamic> parsed = await compute(_decodeJson, jsonStr);
      onProgress(0.30);

      final List<dynamic> rawExercises = parsed['exercises'] as List? ?? [];
      final List<dynamic> rawWorkouts = parsed['workouts'] as List? ?? [];

      debugPrint('[FitbodDataLoader] Parsed ${rawExercises.length} exercises & ${rawWorkouts.length} workouts.');
      final db = await _dbHelper.database;

      // Batch insert exercises (730)
      onProgress(0.35);
      if (rawExercises.isNotEmpty) {
        await db.transaction((txn) async {
          final batch = txn.batch();
          int count = 0;
          for (final raw in rawExercises) {
            final item = ExerciseLibraryItem.fromJson(raw as Map<String, dynamic>);
            batch.insert(
              'exercises_library',
              item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            count++;
            if (count % 100 == 0) {
              onProgress(0.35 + (0.35 * (count / rawExercises.length)));
            }
          }
          await batch.commit(noResult: true);
        });
      }

      // Batch insert workouts (1794)
      onProgress(0.70);
      if (rawWorkouts.isNotEmpty) {
        await db.transaction((txn) async {
          final batch = txn.batch();
          int count = 0;
          for (final raw in rawWorkouts) {
            final item = FitbodWorkout.fromJson(raw as Map<String, dynamic>);
            batch.insert(
              'fitbod_workouts',
              item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            
            // Also insert workout exercises
            for (final we in item.exercises) {
              batch.insert(
                'fitbod_workout_exercises',
                we.toMap(item.id),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            count++;
            if (count % 200 == 0) {
              onProgress(0.70 + (0.25 * (count / rawWorkouts.length)));
            }
          }
          await batch.commit(noResult: true);
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      
      onProgress(1.0);
      debugPrint('[FitbodDataLoader] Loading complete!');
      return true;
    } catch (e, stack) {
      debugPrint('[FitbodDataLoader] Error loading data: $e\n$stack');
      return false;
    }
  }
}
