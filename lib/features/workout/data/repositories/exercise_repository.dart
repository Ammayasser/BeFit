import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/workout_models.dart';

class ExerciseRepository {
  final DatabaseHelper _dbHelper;

  ExerciseRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> getExercisesCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM exercises_library');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearLibrary() async {
    final db = await _dbHelper.database;
    await db.delete('exercises_library');
  }

  Future<void> insertExercisesBatch(List<Map<String, dynamic>> rawList) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in rawList) {
        final parsed = ExerciseLibraryItem.fromJson(item);
        batch.insert(
          'exercises_library',
          parsed.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<ExerciseLibraryItem>> searchAndFilterExercises({
    String query = '',
    String? bodyPart,
    String? equipment,
    String? difficulty,
  }) async {
    final db = await _dbHelper.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (query.isNotEmpty) {
      whereClauses.add('name LIKE ?');
      whereArgs.add('%$query%');
    }
    if (bodyPart != null && bodyPart != 'All') {
      whereClauses.add('body_part = ? COLLATE NOCASE');
      whereArgs.add(bodyPart);
    }
    if (equipment != null && equipment != 'All') {
      whereClauses.add('primary_equipment = ? COLLATE NOCASE');
      whereArgs.add(equipment);
    }
    if (difficulty != null && difficulty != 'All') {
      whereClauses.add('difficulty = ? COLLATE NOCASE');
      whereArgs.add(difficulty);
    }


    final results = await db.query(
      'exercises_library',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereClauses.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return results.map((e) => ExerciseLibraryItem.fromJson(e)).toList();
  }

  Future<List<ExerciseLibraryItem>> getExercisesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await _dbHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final results = await db.query(
      'exercises_library',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return results.map((e) => ExerciseLibraryItem.fromJson(e)).toList();
  }

  Future<ExerciseLibraryItem?> getExerciseById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'exercises_library',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return ExerciseLibraryItem.fromJson(results.first);
  }

  Future<ExerciseLibraryItem?> getExerciseByName(String name) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'exercises_library',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [name],
    );
    if (results.isEmpty) return null;
    return ExerciseLibraryItem.fromJson(results.first);
  }

  /// Partial name match when exact [getExerciseByName] finds nothing.
  Future<ExerciseLibraryItem?> findExerciseByFuzzyName(String name) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'exercises_library',
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ExerciseLibraryItem.fromJson(results.first);
  }

  // Saved Exercises (Favorites)
  Future<void> toggleSaveExercise(String userId, String exerciseId, String name) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'saved_exercises',
      where: 'user_id = ? AND exercise_id = ?',
      whereArgs: [userId, exerciseId],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'saved_exercises',
        where: 'user_id = ? AND exercise_id = ?',
        whereArgs: [userId, exerciseId],
      );
    } else {
      await db.insert('saved_exercises', {
        'user_id': userId,
        'exercise_id': exerciseId,
        'exercise_name': name,
        'saved_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<bool> isSaved(String userId, String exerciseId) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'saved_exercises',
      where: 'user_id = ? AND exercise_id = ?',
      whereArgs: [userId, exerciseId],
    );
    return existing.isNotEmpty;
  }

  Future<List<ExerciseLibraryItem>> getSavedExercises(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'saved_exercises',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return [];

    final ids = results.map((e) => e['exercise_id'] as String).toList();
    if (ids.isEmpty) return [];

    // Query details for all bookmarked exercises
    final placeholders = List.filled(ids.length, '?').join(',');
    final exerciseResults = await db.rawQuery(
      'SELECT * FROM exercises_library WHERE id IN ($placeholders)',
      ids,
    );

    return exerciseResults.map((e) => ExerciseLibraryItem.fromJson(e)).toList();
  }

  /// Retrieves a list of available exercise details to feed into the AI prompt constraints.
  Future<List<Map<String, String>>> getAvailableExercisesForAI(String location) async {
    final db = await _dbHelper.database;
    String? whereClause;
    
    final loc = location.toLowerCase();
    if (loc.contains('home') || loc.contains('no equipment') || loc == 'home') {
      whereClause = "primary_equipment = 'Body Weight' OR is_bodyweight = 1";
    } else if (loc.contains('outdoor') || loc.contains('minimal') || loc == 'outdoor') {
      whereClause = "primary_equipment IN ('Body Weight', 'Bands') OR is_bodyweight = 1";
    }
    
    final List<Map<String, dynamic>> results = await db.query(
      'exercises_library',
      columns: ['name', 'target', 'body_part', 'equipment'],
      where: whereClause,
      orderBy: 'name ASC',
    );
    
    return results.map((e) => {
      'name': e['name']?.toString() ?? '',
      'target': e['target']?.toString() ?? e['body_part']?.toString() ?? '',
      'equipment': e['equipment']?.toString() ?? '',
    }).toList();
  }
}
