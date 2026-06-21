import 'package:sqflite/sqflite.dart';

class CustomProgramSchema {
  static const String tablePrograms   = 'custom_programs';
  static const String tableWeeks      = 'custom_program_weeks';
  static const String tableDays       = 'custom_program_days';
  static const String tableExercises  = 'custom_program_exercises';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePrograms (
        id                   TEXT PRIMARY KEY,
        user_id              TEXT NOT NULL,
        name                 TEXT NOT NULL,
        emoji                TEXT,
        total_weeks          INTEGER NOT NULL DEFAULT 4,
        days_per_week        INTEGER NOT NULL DEFAULT 4,
        is_active            INTEGER NOT NULL DEFAULT 0,
        is_completed         INTEGER NOT NULL DEFAULT 0,
        current_week_index   INTEGER NOT NULL DEFAULT 0,
        current_day_index    INTEGER NOT NULL DEFAULT 0,
        created_at           TEXT NOT NULL,
        updated_at           TEXT NOT NULL,
        started_at           TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableWeeks (
        id           TEXT PRIMARY KEY,
        program_id   TEXT NOT NULL,
        week_number  INTEGER NOT NULL,
        label        TEXT,
        FOREIGN KEY (program_id) REFERENCES $tablePrograms(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableDays (
        id               TEXT PRIMARY KEY,
        program_week_id  TEXT NOT NULL,
        program_id       TEXT NOT NULL,
        day_number       INTEGER NOT NULL,
        name             TEXT NOT NULL,
        is_rest_day      INTEGER NOT NULL DEFAULT 0,
        is_completed     INTEGER NOT NULL DEFAULT 0,
        completed_at     TEXT,
        FOREIGN KEY (program_week_id) REFERENCES $tableWeeks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableExercises (
        id               TEXT PRIMARY KEY,
        program_day_id   TEXT NOT NULL,
        exercise_id      TEXT NOT NULL,
        exercise_name    TEXT NOT NULL,
        muscle_group     TEXT,
        gif_url          TEXT,
        sets             INTEGER NOT NULL DEFAULT 3,
        reps             TEXT NOT NULL DEFAULT '8-12',
        weight_kg        REAL,
        rest_seconds     INTEGER NOT NULL DEFAULT 90,
        notes            TEXT,
        sort_order       INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (program_day_id) REFERENCES $tableDays(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_cp_user ON $tablePrograms(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpw_program ON $tableWeeks(program_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpd_week ON $tableDays(program_week_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpe_day ON $tableExercises(program_day_id)');
  }
}
