import 'package:sqflite/sqflite.dart';

class WorkoutSchema {
  static const String tableWorkoutLogs = 'workout_logs';
  static const String tableSetLogs = 'set_logs';
  static const String tableSavedExercises = 'saved_exercises';
  static const String tableFitbodWorkouts = 'fitbod_workouts';
  static const String tableFitbodWorkoutExercises = 'fitbod_workout_exercises';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableWorkoutLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        day_index INTEGER,
        focus TEXT,
        duration_seconds INTEGER,
        total_sets INTEGER,
        total_reps INTEGER,
        total_volume REAL,
        completed_at TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_workout_logs_user_date ON $tableWorkoutLogs(user_id, date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_workout_logs_user_completed_at ON $tableWorkoutLogs(user_id, completed_at)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSetLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        workout_log_id INTEGER,
        exercise_name TEXT NOT NULL,
        muscle_group TEXT,
        primary_muscles TEXT DEFAULT '[]',
        secondary_muscles TEXT DEFAULT '[]',
        set_number INTEGER,
        weight_kg REAL,
        reps INTEGER,
        logged_at TEXT,
        FOREIGN KEY (workout_log_id) REFERENCES $tableWorkoutLogs(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_set_logs_workout_log_id ON $tableSetLogs(workout_log_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_set_logs_user_exercise ON $tableSetLogs(user_id, exercise_name)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSavedExercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT,
        saved_at TEXT
      )
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_saved_exercises_user_exercise_id ON $tableSavedExercises(user_id, exercise_id)',
    );

    await createFitbodWorkouts(db);
    await createFitbodWorkoutExercises(db);
  }

  static Future<void> createFitbodWorkouts(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFitbodWorkouts (
        id              TEXT PRIMARY KEY,
        name            TEXT NOT NULL,
        difficulty      TEXT,
        goal            TEXT,
        category        TEXT,
        gender          TEXT,
        image_urls      TEXT,
        primary_muscles TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_difficulty ON $tableFitbodWorkouts(difficulty)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_category ON $tableFitbodWorkouts(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender ON $tableFitbodWorkouts(gender)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender_category ON $tableFitbodWorkouts(gender, category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender_difficulty ON $tableFitbodWorkouts(gender, difficulty)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender_goal ON $tableFitbodWorkouts(gender, goal)');
  }

  static Future<void> createFitbodWorkoutExercises(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFitbodWorkoutExercises (
        workout_id   TEXT,
        exercise_id  TEXT,
        sets         INTEGER NOT NULL DEFAULT 3,
        reps         TEXT NOT NULL DEFAULT '8-12',
        weight       REAL NOT NULL DEFAULT 0.0,
        rest_seconds INTEGER NOT NULL DEFAULT 60,
        equipment    TEXT DEFAULT '',
        PRIMARY KEY (workout_id, exercise_id)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_we_workout_id ON $tableFitbodWorkoutExercises(workout_id)');
  }
}
