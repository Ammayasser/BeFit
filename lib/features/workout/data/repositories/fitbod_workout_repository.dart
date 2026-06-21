import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/fitbod_workout_model.dart';

class FitbodWorkoutRepository {
  final DatabaseHelper _dbHelper;

  FitbodWorkoutRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> getWorkoutsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM fitbod_workouts');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('SELECT DISTINCT category FROM fitbod_workouts WHERE category IS NOT NULL AND category != "" ORDER BY category ASC');
    return results.map((e) => e['category'] as String).toList();
  }

  Future<List<FitbodWorkout>> _buildWorkoutsFromRows(
      Database db, List<Map<String, dynamic>> workoutRows) async {
    if (workoutRows.isEmpty) return [];

    final rowList = workoutRows.toList();
    final allExerciseRows = <Map<String, dynamic>>[];
    const chunkSize = 500; // SQLite limit is typically 999 placeholders

    for (var i = 0; i < rowList.length; i += chunkSize) {
      final end = (i + chunkSize < rowList.length) ? i + chunkSize : rowList.length;
      final chunk = rowList.sublist(i, end);
      final ids = chunk.map((r) => r['id'] as String).toList();
      final placeholders = List.filled(ids.length, '?').join(',');

      final exerciseRows = await db.rawQuery('''
        SELECT we.workout_id, we.exercise_id, we.sets, we.reps, we.weight,
               we.rest_seconds, el.primary_equipment as equipment
        FROM fitbod_workout_exercises we
        LEFT JOIN exercises_library el ON we.exercise_id = el.id
        WHERE we.workout_id IN ($placeholders)
      ''', ids);
      
      allExerciseRows.addAll(exerciseRows);
    }

    final exercisesByWorkout = <String, List<Map<String, dynamic>>>{};
    for (final ex in allExerciseRows) {
      final wid = ex['workout_id'] as String;
      exercisesByWorkout.putIfAbsent(wid, () => []).add(ex);
    }

    return workoutRows.map((row) {
      final wid = row['id'] as String;
      return FitbodWorkout.fromJson({
        ...row,
        'exercises': exercisesByWorkout[wid] ?? [],
      });
    }).toList();
  }

  Future<List<FitbodWorkout>> filterWorkouts({
    String? category,
    String? difficulty,
    String? goal,
    String? muscle,
    String? gender,
    int limit = 200,
  }) async {
    final db = await _dbHelper.database;
    final List<String> where = [];
    final List<dynamic> args = [];

    if (category != null && category != 'All') {
      where.add('w.category = ? COLLATE NOCASE');
      args.add(category);
    }
    if (difficulty != null && difficulty != 'All') {
      where.add('w.difficulty = ? COLLATE NOCASE');
      args.add(difficulty);
    }
    if (goal != null && goal != 'All') {
      where.add('w.goal = ? COLLATE NOCASE');
      args.add(goal);
    }
    if (gender != null && gender != 'All') {
      final g = gender.toLowerCase().trim();
      if (g == 'male' || g == 'men') {
        where.add("w.gender IN ('Male', 'men', 'Unisex')");
      } else if (g == 'female' || g == 'women') {
        where.add("w.gender IN ('Female', 'women', 'Unisex')");
      } else if (g == 'unisex') {
        where.add("w.gender = 'Unisex'");
      } else {
        where.add('w.gender = ? COLLATE NOCASE');
        args.add(gender);
      }
    }
    if (muscle != null && muscle != 'All') {
      where.add("w.primary_muscles LIKE ?");
      args.add('%${muscle.toLowerCase()}%');
    }

    final whereStr = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final workoutRows = await db.rawQuery('''
      SELECT w.id, w.name, w.difficulty, w.goal, w.category, w.gender,
             w.image_urls, w.primary_muscles
      FROM fitbod_workouts w
      $whereStr
      ORDER BY w.name ASC
      LIMIT $limit
    ''', args);

    return _buildWorkoutsFromRows(db, workoutRows);
  }

  Future<List<FitbodWorkout>> getWorkoutsByCategory(String category) async {
    final db = await _dbHelper.database;
    final rows = await db.query('fitbod_workouts',
        where: 'category = ? COLLATE NOCASE', whereArgs: [category]);
    return _buildWorkoutsFromRows(db, rows);
  }

  Future<List<FitbodWorkout>> getFeaturedWorkouts(int limit) async {
    final db = await _dbHelper.database;
    final rows = await db.query('fitbod_workouts', limit: limit, orderBy: 'id DESC');
    return _buildWorkoutsFromRows(db, rows);
  }

  Future<FitbodWorkout?> getWorkoutById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('fitbod_workouts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return (await _buildWorkoutsFromRows(db, [rows.first])).first;
  }

  Future<List<FitbodWorkoutExercise>> getExercisesForWorkout(String workoutId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT we.*, el.primary_equipment as equipment
      FROM fitbod_workout_exercises we
      LEFT JOIN exercises_library el ON we.exercise_id = el.id
      WHERE we.workout_id = ?
    ''', [workoutId]);
    return results.map((e) => FitbodWorkoutExercise.fromJson(e)).toList();
  }

  Future<List<FitbodWorkout>> searchWorkouts(String query) async {
    if (query.isEmpty) return [];
    final db = await _dbHelper.database;
    final rows = await db.query('fitbod_workouts',
        where: 'name LIKE ?', whereArgs: ['%$query%'], limit: 50);
    return _buildWorkoutsFromRows(db, rows);
  }

  Future<List<FitbodWorkout>> loadAllForGender(String gender) async {
    final db = await _dbHelper.database;
    final g = gender.toLowerCase().trim();

    // Single SQL: fetch all rows for this gender OR unisex in one go
    final String genderInClause;
    if (g == 'male' || g == 'men') {
      genderInClause = "('Male', 'male', 'men', 'Unisex', 'unisex')";
    } else {
      genderInClause = "('Female', 'female', 'women', 'Unisex', 'unisex')";
    }

    // Also include null-gender rows (your data has 1488 nulls = Unisex in JSON)
    final workoutRows = await db.rawQuery('''
      SELECT id, name, difficulty, goal, category, gender,
             image_urls, primary_muscles
      FROM fitbod_workouts
      WHERE gender IN $genderInClause
         OR gender IS NULL
      ORDER BY name ASC
    ''');

    // _buildWorkoutsFromRows does the single batch JOIN for exercises
    return _buildWorkoutsFromRows(db, workoutRows);
  }
}
