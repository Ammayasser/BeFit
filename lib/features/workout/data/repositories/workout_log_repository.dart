import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/i_workout_repository.dart';
import '../models/workout_history_entry.dart';

class WorkoutLogRepository implements IWorkoutRepository {
  final DatabaseHelper _dbHelper;

  WorkoutLogRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get database => _dbHelper.database;

  @override
  Future<int> insertWorkoutSession(WorkoutSessionEntity session) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // 1. Insert WorkoutSession details
      final logId = await txn.insert('workout_logs', {
        'user_id': session.userId,
        'date': session.startedAt.toIso8601String().substring(0, 10),
        'day_index': session.currentExerciseIndex,
        'focus': session.exercises.isNotEmpty
            ? session.exercises
                  .take(2)
                  .map((e) => e.muscleGroup ?? '')
                  .where((e) => e.isNotEmpty)
                  .join(' & ')
            : 'General Workout',
        'duration_seconds': session.duration.inSeconds,
        'total_sets': session.totalSets,
        'total_reps': session.totalReps,
        'total_volume': session.totalVolume,
        'completed_at': (session.finishedAt ?? DateTime.now())
            .toIso8601String(),
      });

      // 2. Insert set logs
      for (final exercise in session.exercises) {
        if (exercise.isSkipped) continue;
        for (final set in exercise.loggedSets) {
          await txn.insert('set_logs', {
            'user_id': session.userId,
            'workout_log_id': logId,
            'exercise_name': exercise.name,
            'muscle_group': exercise.muscleGroup,
            'set_number': set.setNumber,
            'weight_kg': set.weightKg,
            'reps': set.reps,
            'logged_at': set.loggedAt.toIso8601String(),
          });
        }
      }

      return logId;
    });
  }

  Future<List<WorkoutHistoryEntry>> getWorkoutHistory(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'workout_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
    );
    return results.map((e) => WorkoutHistoryEntry.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getSetsForWorkoutLog(int logId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'set_logs',
      where: 'workout_log_id = ?',
      whereArgs: [logId],
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, double>> getPersonalRecords(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      '''
      SELECT exercise_name, MAX(weight_kg) as max_weight 
      FROM set_logs 
      WHERE user_id = ? 
      GROUP BY exercise_name
    ''',
      [userId],
    );

    final Map<String, double> prMap = {};
    for (final row in results) {
      final name = row['exercise_name'] as String;
      final maxWeight = double.tryParse(row['max_weight'].toString()) ?? 0.0;
      prMap[name] = maxWeight;
    }
    return prMap;
  }

  Future<bool> isPersonalRecord(
    String userId,
    String exerciseName,
    double weightKg,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT MAX(weight_kg) as max_weight 
      FROM set_logs 
      WHERE user_id = ? AND exercise_name = ?
    ''',
      [userId, exerciseName],
    );

    if (result.isEmpty || result.first['max_weight'] == null) {
      return true;
    }

    final currentMax =
        double.tryParse(result.first['max_weight'].toString()) ?? 0.0;
    return weightKg > currentMax;
  }

  Future<List<WorkoutSet>> getExerciseHistory(
    String userId,
    String exerciseName,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'set_logs',
      where: 'user_id = ? AND exercise_name = ?',
      whereArgs: [userId, exerciseName],
      orderBy: 'logged_at ASC',
    );

    return results.map((e) {
      return WorkoutSet(
        setNumber: e['set_number'] as int? ?? 1,
        weightKg: double.tryParse(e['weight_kg'].toString()) ?? 0.0,
        reps: e['reps'] as int? ?? 0,
        loggedAt: DateTime.parse(e['logged_at'] as String),
      );
    }).toList();
  }

  @override
  Future<List<WorkoutSet>> getLastWorkoutSets(
    String userId,
    String exerciseName,
  ) async {
    final db = await _dbHelper.database;
    final lastLogResult = await db.rawQuery(
      '''
      SELECT MAX(workout_log_id) as last_log_id 
      FROM set_logs 
      WHERE user_id = ? AND exercise_name = ?
    ''',
      [userId, exerciseName],
    );

    if (lastLogResult.isEmpty || lastLogResult.first['last_log_id'] == null) {
      return [];
    }

    final lastLogId = lastLogResult.first['last_log_id'] as int;
    final results = await db.query(
      'set_logs',
      where: 'user_id = ? AND exercise_name = ? AND workout_log_id = ?',
      whereArgs: [userId, exerciseName, lastLogId],
      orderBy: 'set_number ASC',
    );

    return results.map((e) {
      return WorkoutSet(
        setNumber: e['set_number'] as int? ?? 1,
        weightKg: double.tryParse(e['weight_kg'].toString()) ?? 0.0,
        reps: e['reps'] as int? ?? 0,
        loggedAt: DateTime.parse(e['logged_at'] as String),
        isCompleted: true,
      );
    }).toList();
  }

  Future<Map<String, double>> getMuscleVolumeByGroup(
    String userId, {
    int days = 28,
  }) async {
    final db = await _dbHelper.database;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    final results = await db.rawQuery(
      '''
      SELECT muscle_group, SUM(weight_kg * reps) as vol
      FROM set_logs
      WHERE user_id = ? AND logged_at >= ?
      GROUP BY muscle_group
    ''',
      [userId, since],
    );

    final map = <String, double>{};
    for (final row in results) {
      final group = (row['muscle_group'] as String?)?.trim();
      if (group == null || group.isEmpty) continue;
      map[group] = double.tryParse(row['vol'].toString()) ?? 0;
    }
    return map;
  }

  Future<Map<String, DateTime>> getLastTrainedDatesByGroup(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      '''
      SELECT muscle_group, MAX(logged_at) as last_date
      FROM set_logs
      WHERE user_id = ?
      GROUP BY muscle_group
    ''',
      [userId],
    );

    final map = <String, DateTime>{};
    for (final row in results) {
      final group = (row['muscle_group'] as String?)?.trim();
      final dateStr = row['last_date'] as String?;
      if (group == null || group.isEmpty || dateStr == null) continue;
      
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        map[group] = dt;
      }
    }
    return map;
  }

  Future<double> getVolumeRecord(String userId, String exerciseName) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      '''
      SELECT MAX(vol) as max_vol 
      FROM (
        SELECT workout_log_id, SUM(weight_kg * reps) as vol 
        FROM set_logs 
        WHERE user_id = ? AND exercise_name = ? 
        GROUP BY workout_log_id
      )
    ''',
      [userId, exerciseName],
    );

    if (results.isEmpty || results.first['max_vol'] == null) {
      return 0.0;
    }
    return double.tryParse(results.first['max_vol'].toString()) ?? 0.0;
  }

  Future<void> deleteWorkoutLog(int logId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'set_logs',
        where: 'workout_log_id = ?',
        whereArgs: [logId],
      );
      await txn.delete('workout_logs', where: 'id = ?', whereArgs: [logId]);
    });
  }
}
