import 'package:sqflite/sqflite.dart';

class MuscleEngagementSchema {
  static const String tableMuscleEngagementLogs = 'muscle_engagement_logs';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableMuscleEngagementLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        workout_log_id INTEGER NOT NULL,
        muscle_name TEXT NOT NULL,
        total_volume REAL DEFAULT 0.0,
        set_count INTEGER DEFAULT 0,
        exercise_count INTEGER DEFAULT 0,
        is_primary INTEGER DEFAULT 1,
        intensity_score REAL DEFAULT 0.0,
        trained_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_muscle_engagement_user_muscle ON $tableMuscleEngagementLogs(user_id, muscle_name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_muscle_engagement_user_trained ON $tableMuscleEngagementLogs(user_id, trained_at)',
    );
  }
}
