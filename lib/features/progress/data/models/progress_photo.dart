// lib/features/progress/data/models/progress_photo.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProgressPhoto {
  final String id;
  final String userId;
  final String
  photoPath; // Stored as filename relative to progress_photos directory
  final String category; // 'front', 'side', 'back', 'other'
  final DateTime loggedAt;
  final String? notes;
  final String? weightLogId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProgressPhoto({
    required this.id,
    required this.userId,
    required this.photoPath,
    required this.category,
    required this.loggedAt,
    this.notes,
    this.weightLogId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Resolve absolute path from local documents directory
  Future<String> resolveAbsolutePath() async {
    final docDir = await getApplicationDocumentsDirectory();
    return '${docDir.path}/progress_photos/$photoPath';
  }

  // Check if file physically exists
  Future<bool> fileExists() async {
    try {
      final absolutePath = await resolveAbsolutePath();
      return await File(absolutePath).exists();
    } catch (_) {
      return false;
    }
  }

  // manual map serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'photo_path': photoPath,
      'category': category,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
      'weight_log_id': weightLogId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      photoPath: map['photo_path'] as String,
      category: map['category'] as String,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      notes: map['notes'] as String?,
      weightLogId: map['weight_log_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) =>
      ProgressPhoto.fromMap(json);

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    String? photoPath,
    String? category,
    DateTime? loggedAt,
    String? notes,
    String? weightLogId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      photoPath: photoPath ?? this.photoPath,
      category: category ?? this.category,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
      weightLogId: weightLogId ?? this.weightLogId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
