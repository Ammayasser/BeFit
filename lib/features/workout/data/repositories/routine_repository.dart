// lib/features/workout/data/repositories/routine_repository.dart

import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/workout_routine.dart';

class RoutineRepository {
  final DatabaseHelper _dbHelper;

  RoutineRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ── Routines ────────────────────────────────────────────────────────────────

  Future<List<WorkoutRoutine>> getAllRoutines() async {
    final db = await _dbHelper.database;

    final routineRows = await db.query(
      'workout_routines',
      orderBy: 'updated_at DESC',
    );

    final routines = <WorkoutRoutine>[];
    for (final row in routineRows) {
      final routineId = row['id'] as String;
      final exerciseRows = await db.query(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routineId],
        orderBy: 'sort_order ASC',
      );
      final exercises =
          exerciseRows.map((e) => RoutineExercise.fromMap(e)).toList();
      routines.add(WorkoutRoutine.fromMap(row, exercises));
    }
    return routines;
  }

  Future<WorkoutRoutine?> getRoutineById(String routineId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'workout_routines',
      where: 'id = ?',
      whereArgs: [routineId],
    );
    if (rows.isEmpty) return null;

    final exerciseRows = await db.query(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'sort_order ASC',
    );
    final exercises =
        exerciseRows.map((e) => RoutineExercise.fromMap(e)).toList();
    return WorkoutRoutine.fromMap(rows.first, exercises);
  }

  /// Upserts a routine and all its exercises.
  Future<void> saveRoutine(WorkoutRoutine routine) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Upsert routine header
      await txn.insert(
        'workout_routines',
        routine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Delete existing exercises then re-insert in correct order
      await txn.delete(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routine.id],
      );

      for (int i = 0; i < routine.exercises.length; i++) {
        final ex = routine.exercises[i];
        final map = ex.toMap();
        map['sort_order'] = i;
        await txn.insert(
          'routine_exercises',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteRoutine(String routineId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routineId],
      );
      await txn.delete(
        'workout_routines',
        where: 'id = ?',
        whereArgs: [routineId],
      );
    });
  }

  // ── Routine Exercises ───────────────────────────────────────────────────────

  Future<void> addExerciseToRoutine(
      String routineId, RoutineExercise exercise) async {
    final db = await _dbHelper.database;
    // Get current max sort_order
    final result = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM routine_exercises WHERE routine_id = ?',
      [routineId],
    );
    final maxOrder = (result.first['max_order'] as int?) ?? -1;

    final map = exercise.toMap();
    map['sort_order'] = maxOrder + 1;
    await db.insert(
      'routine_exercises',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update routine's updated_at
    await db.update(
      'workout_routines',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }

  Future<void> removeExerciseFromRoutine(
      String routineId, String exerciseRowId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'routine_exercises',
      where: 'id = ? AND routine_id = ?',
      whereArgs: [exerciseRowId, routineId],
    );
    await db.update(
      'workout_routines',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }

  Future<void> reorderExercises(
      String routineId, List<String> orderedIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (int i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'routine_exercises',
          {'sort_order': i},
          where: 'id = ? AND routine_id = ?',
          whereArgs: [orderedIds[i], routineId],
        );
      }
      await txn.update(
        'workout_routines',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [routineId],
      );
    });
  }
}
