import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/muscle_engagement_model.dart';

class MuscleEngagementRepository {
  final DatabaseHelper _dbHelper;

  MuscleEngagementRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get database => _dbHelper.database;

  Future<int> insertEngagement(MuscleEngagementEntry entry) async {
    final db = await database;
    return await db.insert('muscle_engagement_logs', entry.toMap());
  }
  
  Future<void> insertEngagements(List<MuscleEngagementEntry> entries) async {
    if (entries.isEmpty) return;
    
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in entries) {
        await txn.insert('muscle_engagement_logs', entry.toMap());
      }
    });
  }

  Future<List<MuscleEngagementEntry>> getEngagementsByUser(String userId, {DateTime? since}) async {
    final db = await database;
    String where = 'user_id = ?';
    List<Object?> whereArgs = [userId];
    
    if (since != null) {
      where += ' AND trained_at >= ?';
      whereArgs.add(since.toIso8601String());
    }
    
    final results = await db.query(
      'muscle_engagement_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'trained_at ASC',
    );
    
    return results.map((e) => MuscleEngagementEntry.fromMap(e)).toList();
  }

  Future<List<MuscleEngagementEntry>> getEngagementsByMuscle(String userId, String muscleName, {int limit = 5}) async {
    final db = await database;
    final results = await db.query(
      'muscle_engagement_logs',
      where: 'user_id = ? AND muscle_name = ?',
      whereArgs: [userId, muscleName],
      orderBy: 'trained_at DESC',
      limit: limit,
    );
    
    return results.map((e) => MuscleEngagementEntry.fromMap(e)).toList();
  }
}