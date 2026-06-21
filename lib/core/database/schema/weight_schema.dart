import 'package:sqflite/sqflite.dart';

class WeightSchema {
  static const String tableWeightLogs = 'weight_logs';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableWeightLogs (
        id                      TEXT PRIMARY KEY,
        user_id                 TEXT NOT NULL,
        weight_kg               REAL NOT NULL,
        body_fat_percentage     REAL,
        muscle_mass_kg          REAL,
        waist_cm                REAL,
        chest_cm                REAL,
        hips_cm                 REAL,
        neck_cm                 REAL,
        notes                   TEXT,
        logged_at               TEXT NOT NULL,
        created_at              TEXT NOT NULL,
        updated_at              TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_weight_logs_user ON $tableWeightLogs(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_weight_logs_logged_at ON $tableWeightLogs(logged_at)',
    );
  }
}
