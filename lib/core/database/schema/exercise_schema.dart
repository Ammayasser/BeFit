import 'package:sqflite/sqflite.dart';

class ExerciseSchema {
  static const String tableExercisesLibrary = 'exercises_library';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableExercisesLibrary (
        id                TEXT PRIMARY KEY,
        name              TEXT NOT NULL,
        body_part         TEXT,
        target            TEXT,
        primary_muscles   TEXT,
        secondary_muscles TEXT,
        equipment         TEXT,
        primary_equipment TEXT,
        difficulty        TEXT,
        category          TEXT,
        mechanic          TEXT,
        force_type        TEXT,
        met               REAL,
        calories_per_min  REAL,
        description       TEXT,
        instructions      TEXT,
        gif_url           TEXT,
        images            TEXT,
        video_url         TEXT,
        video_url_mobile  TEXT,
        pro_tips          TEXT,
        is_bodyweight     INTEGER DEFAULT 0,
        author            TEXT,
        popularity_rank   INTEGER,
        efficacy_rank     INTEGER,
        synced_at         INTEGER
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_ex_body_part ON $tableExercisesLibrary(body_part)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ex_target ON $tableExercisesLibrary(target)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ex_equipment ON $tableExercisesLibrary(equipment)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ex_prim_equipment ON $tableExercisesLibrary(primary_equipment)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ex_difficulty ON $tableExercisesLibrary(difficulty)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ex_name ON $tableExercisesLibrary(name COLLATE NOCASE)');
  }
}
