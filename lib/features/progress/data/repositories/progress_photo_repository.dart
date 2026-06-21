// lib/features/progress/data/repositories/progress_photo_repository.dart

import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/schema/progress_photo_schema.dart';
import '../models/progress_photo.dart';

class ProgressPhotoRepository {
  final DatabaseHelper _dbHelper;

  ProgressPhotoRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  // Insert a progress photo
  Future<int> insertPhoto(ProgressPhoto photo) async {
    final db = await _db;
    return await db.insert(
      ProgressPhotoSchema.tableProgressPhotos,
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update a progress photo
  Future<int> updatePhoto(ProgressPhoto photo) async {
    final db = await _db;
    return await db.update(
      ProgressPhotoSchema.tableProgressPhotos,
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  // Delete a progress photo by ID
  Future<int> deletePhoto(String id) async {
    final db = await _db;
    return await db.delete(
      ProgressPhotoSchema.tableProgressPhotos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all photos for a user, sorted newest first
  Future<List<ProgressPhoto>> getPhotosForUser(String userId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      ProgressPhotoSchema.tableProgressPhotos,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) => ProgressPhoto.fromMap(maps[i]));
  }

  // Get photos filtered by category
  Future<List<ProgressPhoto>> getPhotosByCategory(
    String userId,
    String category,
  ) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      ProgressPhotoSchema.tableProgressPhotos,
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'logged_at DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) => ProgressPhoto.fromMap(maps[i]));
  }

  // Get photos within a date range
  Future<List<ProgressPhoto>> getPhotosForDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      ProgressPhotoSchema.tableProgressPhotos,
      where: 'user_id = ? AND logged_at BETWEEN ? AND ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'logged_at DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) => ProgressPhoto.fromMap(maps[i]));
  }
}
