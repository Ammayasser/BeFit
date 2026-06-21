import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'schema/chat_schema.dart';
import 'schema/nutrition_schema.dart';
import 'schema/workout_schema.dart';
import 'schema/exercise_schema.dart';
import 'schema/routine_schema.dart';
import 'schema/weight_schema.dart';
import 'schema/progress_photo_schema.dart';
import 'schema/muscle_engagement_schema.dart';
import 'schema/custom_program_schema.dart';

class SchemaManager {
  static const int databaseVersion = 18;

  static Future<void> onCreate(Database db, int version) async {
    await ChatSchema.create(db);
    await NutritionSchema.create(db);
    await WorkoutSchema.create(db);
    await ExerciseSchema.create(db);
    await RoutineSchema.create(db);
    await WeightSchema.create(db);
    await ProgressPhotoSchema.create(db);
    await MuscleEngagementSchema.create(db);
    await CustomProgramSchema.create(db);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await NutritionSchema.create(db);
    }
    if (oldVersion < 3) {
      await WorkoutSchema.create(db);
    }
    if (oldVersion < 4) {
      await ExerciseSchema.create(db);
    }
    if (oldVersion < 5) {
      await RoutineSchema.create(db);
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE ${ExerciseSchema.tableExercisesLibrary} ADD COLUMN images TEXT');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      await NutritionSchema.createFoodSearches(db);
    }
    
    if (oldVersion < 9) {
      try {
        final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(nutrition_daily)');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        if (!columnNames.contains('calorie_goal')) {
          await db.execute('ALTER TABLE nutrition_daily ADD COLUMN calorie_goal INTEGER DEFAULT 2000');
        }
        if (!columnNames.contains('protein_goal')) {
          await db.execute('ALTER TABLE nutrition_daily ADD COLUMN protein_goal REAL DEFAULT 150.0');
        }
        if (!columnNames.contains('carbs_goal')) {
          await db.execute('ALTER TABLE nutrition_daily ADD COLUMN carbs_goal REAL DEFAULT 250.0');
        }
        if (!columnNames.contains('fat_goal')) {
          await db.execute('ALTER TABLE nutrition_daily ADD COLUMN fat_goal REAL DEFAULT 65.0');
        }
        if (!columnNames.contains('water_goal')) {
          await db.execute('ALTER TABLE nutrition_daily ADD COLUMN water_goal INTEGER DEFAULT 2000');
        }
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v9: $e');
      }
    }

    if (oldVersion < 10) {
      try {
        debugPrint('SchemaManager: Upgrading database from v$oldVersion to v10...');
        final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(exercises_library)');
        final columnNames = columns.map((c) => c['name'] as String).toList();

        if (!columnNames.contains('primary_muscles')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN primary_muscles TEXT');
        }
        if (!columnNames.contains('primary_equipment')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN primary_equipment TEXT');
        }
        if (!columnNames.contains('video_url')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN video_url TEXT');
        }
        if (!columnNames.contains('video_url_mobile')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN video_url_mobile TEXT');
        }
        if (!columnNames.contains('pro_tips')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN pro_tips TEXT');
        }
        if (!columnNames.contains('is_bodyweight')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN is_bodyweight INTEGER DEFAULT 0');
        }
        if (!columnNames.contains('author')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN author TEXT');
        }
        if (!columnNames.contains('popularity_rank')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN popularity_rank INTEGER');
        }
        if (!columnNames.contains('efficacy_rank')) {
          await db.execute('ALTER TABLE exercises_library ADD COLUMN efficacy_rank INTEGER');
        }

        await db.execute('CREATE INDEX IF NOT EXISTS idx_ex_prim_equipment ON exercises_library(primary_equipment)');
        
        await WorkoutSchema.createFitbodWorkouts(db);
        await WorkoutSchema.createFitbodWorkoutExercises(db);

        await db.execute('DELETE FROM exercises_library');
        debugPrint('SchemaManager: Database successfully upgraded to v10!');
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v10: $e');
      }
    }
    
    if (oldVersion < 11) {
      try {
        debugPrint('SchemaManager: Applying new indexes for performance (v11)...');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender ON fitbod_workouts(gender)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender_category ON fitbod_workouts(gender, category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender_difficulty ON fitbod_workouts(gender, difficulty)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_gender_goal ON fitbod_workouts(gender, goal)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_we_workout_id ON fitbod_workout_exercises(workout_id)');
        debugPrint('SchemaManager: Performance indexes applied.');
      } catch (e) {
        debugPrint('SchemaManager: Error applying v11 indexes: $e');
      }
    }

    if (oldVersion < 12) {
      try {
        // Ensure the workout_exercises index exists for the JOIN
        await db.execute('CREATE INDEX IF NOT EXISTS idx_fitbod_we_workout_id ON fitbod_workout_exercises(workout_id)');
      } catch (e) {
        debugPrint('SchemaManager: Error applying v12 indexes: $e');
      }
    }

    if (oldVersion < 13) {
      try {
        debugPrint('SchemaManager: Creating weight_logs table (v13)...');
        await WeightSchema.create(db);
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v13: $e');
      }
    }

    if (oldVersion < 14) {
      try {
        debugPrint('SchemaManager: Creating progress_photos table (v14)...');
        await ProgressPhotoSchema.create(db);
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v14: $e');
      }
    }

    if (oldVersion < 15) {
      try {
        debugPrint('SchemaManager: Creating muscle_engagement_logs table and updating set_logs (v15)...');
        await MuscleEngagementSchema.create(db);
        
        final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(${WorkoutSchema.tableSetLogs})');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        if (!columnNames.contains('primary_muscles')) {
          await db.execute("ALTER TABLE ${WorkoutSchema.tableSetLogs} ADD COLUMN primary_muscles TEXT DEFAULT '[]'");
        }
        if (!columnNames.contains('secondary_muscles')) {
          await db.execute("ALTER TABLE ${WorkoutSchema.tableSetLogs} ADD COLUMN secondary_muscles TEXT DEFAULT '[]'");
        }
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v15: $e');
      }
    }

    if (oldVersion < 16) {
      try {
        debugPrint('SchemaManager: Adding equipment column to fitbod_workout_exercises (v16)...');
        final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(${WorkoutSchema.tableFitbodWorkoutExercises})');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        if (!columnNames.contains('equipment')) {
          await db.execute("ALTER TABLE ${WorkoutSchema.tableFitbodWorkoutExercises} ADD COLUMN equipment TEXT DEFAULT ''");
        }
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v16: $e');
      }
    }

    if (oldVersion < 17) {
      try {
        debugPrint('SchemaManager: Creating custom_programs tables (v17)...');
        await CustomProgramSchema.create(db);
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v17: $e');
      }
    }

    if (oldVersion < 18) {
      try {
        debugPrint('SchemaManager: Adding sessionId to chat_messages (v18)...');
        final List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(${ChatSchema.tableMessages})');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        if (!columnNames.contains('sessionId')) {
          await db.execute("ALTER TABLE ${ChatSchema.tableMessages} ADD COLUMN sessionId TEXT");
          await db.execute("CREATE INDEX IF NOT EXISTS idx_chat_messages_sessionId ON ${ChatSchema.tableMessages}(sessionId)");
        }
      } catch (e) {
        debugPrint('SchemaManager: Error upgrading to v18: $e');
      }
    }
  }
}

