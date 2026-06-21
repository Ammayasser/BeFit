// lib/features/progress/data/repositories/weight_log_repository.dart

import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/schema/weight_schema.dart';
import '../models/weight_log.dart';

class WeightLogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insertLog(WeightLog log) async {
    final db = await _dbHelper.database;
    await db.insert(
      WeightSchema.tableWeightLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLog(WeightLog log) async {
    final db = await _dbHelper.database;
    await db.update(
      WeightSchema.tableWeightLogs,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> deleteLog(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      WeightSchema.tableWeightLogs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<WeightLog>> getLogsForDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      WeightSchema.tableWeightLogs,
      where: 'user_id = ? AND logged_at >= ? AND logged_at <= ?',
      whereArgs: [userId, startStr, endStr],
      orderBy: 'logged_at ASC',
    );

    return maps.map((m) => WeightLog.fromMap(m)).toList();
  }

  Future<WeightLog?> getLatestLog(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      WeightSchema.tableWeightLogs,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WeightLog.fromMap(maps.first);
  }

  Future<WeightLog?> getFirstLog(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      WeightSchema.tableWeightLogs,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WeightLog.fromMap(maps.first);
  }

  Future<WeightLog?> getLogForDate(String userId, DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.query(
      WeightSchema.tableWeightLogs,
      where: 'user_id = ? AND logged_at >= ? AND logged_at <= ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WeightLog.fromMap(maps.first);
  }

  Future<int> getLogCount(String userId) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${WeightSchema.tableWeightLogs} WHERE user_id = ?',
        [userId],
      ),
    );
    return count ?? 0;
  }

  Future<List<WeightLog>> getAllLogs(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      WeightSchema.tableWeightLogs,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC',
    );
    return maps.map((m) => WeightLog.fromMap(m)).toList();
  }
}
