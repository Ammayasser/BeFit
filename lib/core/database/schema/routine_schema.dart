import 'package:sqflite/sqflite.dart';

class RoutineSchema {
  static const String tableRoutines = 'workout_routines';
  static const String tableRoutineExercises = 'routine_exercises';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRoutines (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRoutineExercises (
        id             TEXT PRIMARY KEY,
        routine_id     TEXT NOT NULL,
        exercise_id    TEXT NOT NULL,
        exercise_name  TEXT NOT NULL,
        muscle_group   TEXT,
        gif_url        TEXT,
        default_sets   INTEGER NOT NULL DEFAULT 3,
        default_reps   TEXT    NOT NULL DEFAULT '8-12',
        default_weight REAL,
        sort_order     INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (routine_id) REFERENCES $tableRoutines(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine_id ON $tableRoutineExercises(routine_id)',
    );
  }
}
