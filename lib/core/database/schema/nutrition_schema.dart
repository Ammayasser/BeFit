import 'package:sqflite/sqflite.dart';

class NutritionSchema {
  static const String tableDaily = 'nutrition_daily';
  static const String tableMealLogs = 'nutrition_meal_logs';
  static const String tableFoodSearches = 'recent_food_searches';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableDaily (
        user_id           TEXT    NOT NULL,
        date_key          TEXT    NOT NULL,
        calorie_goal      INTEGER NOT NULL DEFAULT 2000,
        protein_goal      REAL    NOT NULL DEFAULT 150.0,
        carbs_goal        REAL    NOT NULL DEFAULT 250.0,
        fat_goal          REAL    NOT NULL DEFAULT 65.0,
        water_goal        INTEGER NOT NULL DEFAULT 2000,
        water_logged_ml   INTEGER NOT NULL DEFAULT 0,
        water_hourly_json TEXT    NOT NULL,
        updated_at        INTEGER NOT NULL,
        PRIMARY KEY (user_id, date_key)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableMealLogs (
        id            TEXT PRIMARY KEY,
        user_id       TEXT    NOT NULL,
        date_key      TEXT    NOT NULL,
        meal_type     INTEGER NOT NULL,
        logged_at     TEXT    NOT NULL,
        payload_json  TEXT    NOT NULL,
        updated_at    INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nutrition_meals_user_date ON $tableMealLogs(user_id, date_key)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nutrition_meals_logged_at ON $tableMealLogs(logged_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nutrition_daily_user_date ON $tableDaily(user_id, date_key)',
    );

    await createFoodSearches(db);
  }

  static Future<void> createFoodSearches(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFoodSearches (
        user_id    TEXT NOT NULL,
        query      TEXT NOT NULL,
        searched_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, query)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recent_food_searches_user ON $tableFoodSearches(user_id)',
    );
  }
}
