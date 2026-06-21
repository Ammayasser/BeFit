// test/progress_photo_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:befit/features/progress/data/models/progress_photo.dart';

void main() {
  group('ProgressPhoto Model Tests', () {
    test('fromJson and toMap should parse correctly', () {
      final json = {
        'id': 'photo_1',
        'user_id': 'user_456',
        'photo_path': 'photo_1.jpg',
        'category': 'front',
        'logged_at': '2026-06-07T12:00:00.000',
        'notes': 'Looking leaner',
        'weight_log_id': 'weight_abc',
        'created_at': '2026-06-07T12:00:00.000',
        'updated_at': '2026-06-07T12:00:00.000',
      };

      final photo = ProgressPhoto.fromJson(json);

      expect(photo.id, 'photo_1');
      expect(photo.userId, 'user_456');
      expect(photo.photoPath, 'photo_1.jpg');
      expect(photo.category, 'front');
      expect(photo.loggedAt, DateTime.parse('2026-06-07T12:00:00.000'));
      expect(photo.notes, 'Looking leaner');
      expect(photo.weightLogId, 'weight_abc');
    });

    test('toJson/toMap roundtrip correctly', () {
      final photo = ProgressPhoto(
        id: 'photo_2',
        userId: 'user_456',
        photoPath: 'photo_2.jpg',
        category: 'side',
        loggedAt: DateTime.parse('2026-06-07T15:00:00.000'),
        notes: null,
        weightLogId: null,
        createdAt: DateTime.parse('2026-06-07T15:00:00.000'),
        updatedAt: DateTime.parse('2026-06-07T15:00:00.000'),
      );

      final map = photo.toMap();
      final roundtripPhoto = ProgressPhoto.fromMap(map);

      expect(roundtripPhoto.id, 'photo_2');
      expect(roundtripPhoto.category, 'side');
      expect(roundtripPhoto.notes, isNull);
      expect(roundtripPhoto.weightLogId, isNull);
      expect(roundtripPhoto.loggedAt, photo.loggedAt);
    });

    test('copyWith works correctly', () {
      final photo = ProgressPhoto(
        id: 'photo_3',
        userId: 'user_456',
        photoPath: 'photo_3.jpg',
        category: 'back',
        loggedAt: DateTime.parse('2026-06-07T16:00:00.000'),
        createdAt: DateTime.parse('2026-06-07T16:00:00.000'),
        updatedAt: DateTime.parse('2026-06-07T16:00:00.000'),
      );

      final updated = photo.copyWith(
        notes: 'Improved back definition',
        category: 'other',
      );

      expect(updated.id, 'photo_3');
      expect(updated.category, 'other');
      expect(updated.notes, 'Improved back definition');
      expect(updated.weightLogId, isNull);
    });
  });
}
