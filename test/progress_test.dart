// test/progress_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:befit/features/progress/data/models/weight_log.dart';
import 'package:befit/features/progress/presentation/providers/progress_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WeightLog Model Tests', () {
    test('fromJson and toMap should parse correctly', () {
      final json = {
        'id': 'log_1',
        'user_id': 'user_123',
        'weight_kg': 78.5,
        'body_fat_percentage': 18.2,
        'muscle_mass_kg': 60.1,
        'waist_cm': 85.0,
        'chest_cm': 100.0,
        'hips_cm': 95.0,
        'neck_cm': 38.0,
        'notes': 'Felt great',
        'logged_at': '2026-06-07T10:00:00.000',
        'created_at': '2026-06-07T10:00:00.000',
        'updated_at': '2026-06-07T10:00:00.000',
      };

      final log = WeightLog.fromJson(json);

      expect(log.id, 'log_1');
      expect(log.userId, 'user_123');
      expect(log.weightKg, 78.5);
      expect(log.bodyFatPercentage, 18.2);
      expect(log.muscleMassKg, 60.1);
      expect(log.waistCm, 85.0);
      expect(log.chestCm, 100.0);
      expect(log.hipsCm, 95.0);
      expect(log.neckCm, 38.0);
      expect(log.notes, 'Felt great');
      expect(log.loggedAt, DateTime.parse('2026-06-07T10:00:00.000'));
    });

    test('toJson/toMap roundtrip correctly', () {
      final log = WeightLog(
        id: 'log_2',
        userId: 'user_123',
        weightKg: 82.3,
        bodyFatPercentage: null,
        muscleMassKg: null,
        waistCm: null,
        chestCm: null,
        hipsCm: null,
        neckCm: null,
        notes: null,
        loggedAt: DateTime.parse('2026-06-07T12:00:00.000'),
        createdAt: DateTime.parse('2026-06-07T12:00:00.000'),
        updatedAt: DateTime.parse('2026-06-07T12:00:00.000'),
      );

      final map = log.toMap();
      final roundtripLog = WeightLog.fromMap(map);

      expect(roundtripLog.id, 'log_2');
      expect(roundtripLog.weightKg, 82.3);
      expect(roundtripLog.bodyFatPercentage, isNull);
      expect(roundtripLog.waistCm, isNull);
      expect(roundtripLog.loggedAt, log.loggedAt);
    });
  });

  group('ProgressProvider Calculations Tests', () {
    test('toDisplayWeight converts kg to lbs correctly', () async {
      final provider = ProgressProvider();
      
      // Default unit is kg
      expect(provider.weightUnit, 'kg');
      expect(provider.toDisplayWeight(10.0), 10.0);

      // Change unit to lbs
      await provider.setWeightUnit('lbs');
      expect(provider.weightUnit, 'lbs');
      expect(provider.toDisplayWeight(10.0), closeTo(22.0462, 0.0001));
    });

    test('toStoredWeight converts lbs to kg correctly', () async {
      final provider = ProgressProvider();
      
      // Default unit is kg
      expect(provider.toStoredWeight(10.0), 10.0);

      // Change unit to lbs
      await provider.setWeightUnit('lbs');
      expect(provider.toStoredWeight(22.0462), closeTo(10.0, 0.0001));
    });

    test('calculateBmi and getBmiCategory calculate accurately', () {
      final provider = ProgressProvider();
      
      final bmiNormal = provider.calculateBmi(0); // Height zero should return null
      expect(bmiNormal, isNull);

      final bmiCategoryUnderweight = provider.getBmiCategory(17.5);
      expect(bmiCategoryUnderweight, 'Underweight');

      final bmiCategoryNormal = provider.getBmiCategory(22.0);
      expect(bmiCategoryNormal, 'Normal');

      final bmiCategoryOverweight = provider.getBmiCategory(27.0);
      expect(bmiCategoryOverweight, 'Overweight');

      final bmiCategoryObese = provider.getBmiCategory(32.0);
      expect(bmiCategoryObese, 'Obese');
    });
  });
}
