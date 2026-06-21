// lib/core/database/schema/progress_photo_schema.dart

import 'package:sqflite/sqflite.dart';

class ProgressPhotoSchema {
  static const String tableProgressPhotos = 'progress_photos';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProgressPhotos (
        id                      TEXT PRIMARY KEY,
        user_id                 TEXT NOT NULL,
        photo_path              TEXT NOT NULL,
        category                TEXT NOT NULL,
        logged_at               TEXT NOT NULL,
        notes                   TEXT,
        weight_log_id           TEXT,
        created_at              TEXT NOT NULL,
        updated_at              TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_photos_user ON $tableProgressPhotos(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_photos_logged_at ON $tableProgressPhotos(logged_at)',
    );
  }
}
