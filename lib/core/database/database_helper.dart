import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'schema_manager.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;
  static Completer<Database>? _dbCompleter;

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (_dbCompleter != null) return _dbCompleter!.future;

    _dbCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _dbCompleter!.complete(_database);
      return _database!;
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    String path;

    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI for Desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final Directory appDocumentsDir =
          await getApplicationDocumentsDirectory();
      final String dbFolder = join(appDocumentsDir.path, "befit", "databases");
      await Directory(dbFolder).create(recursive: true);
      path = join(dbFolder, 'befit.db');
    } else {
      final databasePath = await getDatabasesPath();
      path = join(databasePath, 'befit.db');
    }

    debugPrint('──────────────────────────────────────────────────');
    debugPrint('DATABASE INITIALIZED:');
    debugPrint('  Path: $path');
    debugPrint('  Platform: ${Platform.operatingSystem}');
    debugPrint('  Factory: ${databaseFactory.runtimeType}');

    return await openDatabase(
      path,
      version: SchemaManager.databaseVersion,
      onCreate: SchemaManager.onCreate,
      onUpgrade: SchemaManager.onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Database Management
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    final tables = [
      'chat_messages',
      'nutrition_meal_logs',
      'nutrition_daily',
      'set_logs',
      'workout_logs',
      'saved_exercises',
      'workout_routines',
      'routine_exercises',
      'exercises_library',
      'fitbod_workouts',
      'fitbod_workout_exercises',
      'weight_logs',
      'progress_photos',
    ];
    for (final table in tables) {
      await db.delete(table);
    }

    // Clear progress photos physical directory on disk
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${docDir.path}/progress_photos');
      if (await photosDir.exists()) {
        await photosDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('DatabaseHelper: Error deleting progress photos physical directory: $e');
    }
  }

  Future<bool> databaseExists() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'befit.db');
    return await databaseFactory.databaseExists(path);
  }
}
