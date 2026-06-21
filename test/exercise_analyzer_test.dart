import 'package:flutter_test/flutter_test.dart';
import 'package:befit/features/workout/data/services/exercise_analyzer_service.dart';
import 'package:befit/features/workout/data/services/pose_detector_service.dart';
import 'package:befit/features/workout/data/models/exercise_definitions.dart';
import 'dart:ui';

void main() {
  late ExerciseAnalyzerService analyzer;

  setUp(() {
    analyzer = ExerciseAnalyzerService();
  });

  // Helper helper to create a mock PoseDetectionResult
  PoseDetectionResult createMockPose(Map<PoseLandmarkType, _Point> landmarkPoints) {
    final List<DetectedLandmark> landmarks = [];
    landmarkPoints.forEach((type, point) {
      landmarks.add(DetectedLandmark(
        type: type,
        x: point.x,
        y: point.y,
        likelihood: point.likelihood,
      ));
    });
    return PoseDetectionResult(
      landmarks: landmarks,
      poseDetected: true,
      imageSize: const Size(640, 480),
    );
  }

  group('ExerciseAnalyzerService - Angle Calculations', () {
    test('Calculates correct 90 degree angle between vertical and horizontal line segment', () {
      final pose = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2), // start
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),    // mid (vertex)
        PoseLandmarkType.leftWrist: const _Point(0.8, 0.5),    // end
      });

      // Bicep curl is leftShoulder -> leftElbow -> leftWrist
      final bicepCurl = ExerciseRegistry.findByKey('bicep_curl')!;
      final result = analyzer.analyze(pose, bicepCurl);

      // Angle should be exactly 90 degrees
      expect(result.primaryAngle, closeTo(90.0, 0.01));
    });

    test('Calculates 180 degree angle for a straight line', () {
      final pose = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2), // start
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),    // mid (vertex)
        PoseLandmarkType.leftWrist: const _Point(0.5, 0.8),    // end
      });

      final bicepCurl = ExerciseRegistry.findByKey('bicep_curl')!;
      final result = analyzer.analyze(pose, bicepCurl);

      expect(result.primaryAngle, closeTo(180.0, 0.01));
    });

    test('Returns null angle and handles it if a landmark is missing or has low confidence', () {
      // 1. Missing landmark
      final poseMissing = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        // wrist missing
      });

      final bicepCurl = ExerciseRegistry.findByKey('bicep_curl')!;
      final resultMissing = analyzer.analyze(poseMissing, bicepCurl);
      expect(resultMissing.primaryAngle, equals(0.0)); // _smoothedAngle default when start is null

      // 2. Low confidence landmark
      final poseLowConfidence = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.8, 0.5, likelihood: 0.4), // low confidence
      });

      final resultLowConf = analyzer.analyze(poseLowConfidence, bicepCurl);
      expect(resultLowConf.primaryAngle, equals(0.0));
    });
  });

  group('ExerciseAnalyzerService - State Transitions & Rep Counting', () {
    test('Normal curl cycle: Idle -> Top -> Descending -> Bottom -> Ascending -> Top (increments rep)', () {
      final bicepCurl = ExerciseRegistry.findByKey('bicep_curl')!;

      // Bicep curl: closing direction, top=165, bottom=40
      // 1. Initial position: arms straight (180 deg) -> enters Top (or remains top)
      var pose = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.5, 0.8), // 180 deg
      });
      var result = analyzer.analyze(pose, bicepCurl);
      expect(result.phase, equals(ExercisePhase.top));
      expect(result.reps, equals(0));

      // 2. Start curling: angle decreases to 120 (descending phase)
      pose = createMockPose({
        // approx 120 deg
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.67, 0.7),
      });
      // Run multiple times to let EMA catch up to the value or simulate step-by-step
      for (int i = 0; i < 15; i++) {
        result = analyzer.analyze(pose, bicepCurl);
      }
      expect(result.phase, equals(ExercisePhase.descending));
      expect(result.reps, equals(0));

      // 3. Fully curled: angle close to bottomThreshold (40 deg)
      pose = createMockPose({
        // approx 40 deg
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.4, 0.25),
      });
      for (int i = 0; i < 15; i++) {
        result = analyzer.analyze(pose, bicepCurl);
      }
      expect(result.phase, equals(ExercisePhase.bottom));
      expect(result.reps, equals(0));

      // 4. Start lowering: angle increases to 100 (ascending phase)
      pose = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.6, 0.65),
      });
      for (int i = 0; i < 15; i++) {
        result = analyzer.analyze(pose, bicepCurl);
      }
      expect(result.phase, equals(ExercisePhase.ascending));
      expect(result.reps, equals(0));

      // 5. Back to top: angle is back to ~180 deg
      pose = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.5, 0.8),
      });
      bool repCounted = false;
      for (int i = 0; i < 15; i++) {
        result = analyzer.analyze(pose, bicepCurl);
        if (result.repJustCounted) {
          repCounted = true;
        }
      }
      expect(result.phase, equals(ExercisePhase.top));
      expect(result.reps, equals(1));
      expect(repCounted, isTrue);
    });

    test('Bug #4 Fix - Loosened Entry Logic: Starts at closest phase when in-range from Idle', () {
      final bicepCurl = ExerciseRegistry.findByKey('bicep_curl')!;

      // Curl range is 40 to 165. Start at angle ~50 (very close to bottom)
      // Angle is in range, should start directly at bottom instead of being stuck in idle
      final poseNearBottom = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.42, 0.26), // ~45 deg
      });

      final result = analyzer.analyze(poseNearBottom, bicepCurl);
      expect(result.phase, equals(ExercisePhase.bottom));
    });
  });

  group('ExerciseAnalyzerService - Form Rules & Quality Score', () {
    test('Bug #5 Fix - Phase-aware form rules: squat_depth ONLY evaluated in descending or bottom', () {
      final squat = ExerciseRegistry.findByKey('squat')!;

      // 1. Standing upright at top (170 deg). Torso is upright (~175 deg).
      // Squat depth is NOT evaluated here, so even though angle (~170) is out of squat_depth's range (70-110),
      // we get no violation and high score (100).
      var poseTop = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.1),
        PoseLandmarkType.leftHip: const _Point(0.5, 0.4),
        PoseLandmarkType.leftKnee: const _Point(0.5, 0.7),
        PoseLandmarkType.leftAnkle: const _Point(0.5, 0.95),
      });

      // Let analyzer settle on top phase
      analyzer.reset();
      var result = analyzer.analyze(poseTop, squat);
      expect(result.phase, equals(ExercisePhase.top));
      expect(result.violations.any((v) => v.ruleId == 'squat_depth'), isFalse);
      expect(result.quality, equals(100));

      // 2. Go to descending phase (knees bent to ~120 degrees, which is out of squat_depth range 70-110).
      // Knee = (0.5, 0.7), Hip = (0.5, 0.4), Ankle = (0.76, 0.85) -> exactly 120 deg.
      // The squat_depth rule should fire now because phase is descending.
      var posePartialSquat = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.1),
        PoseLandmarkType.leftHip: const _Point(0.5, 0.4),
        PoseLandmarkType.leftKnee: const _Point(0.5, 0.7),
        PoseLandmarkType.leftAnkle: const _Point(0.76, 0.85),
      });

      // Transition state machine to descending
      for (int i = 0; i < 15; i++) {
        result = analyzer.analyze(posePartialSquat, squat);
      }
      expect(result.phase, equals(ExercisePhase.descending));
      // Squat depth violation should now be triggered because we are in descending phase and depth is insufficient (> 110 deg)
      expect(result.violations.any((v) => v.ruleId == 'squat_depth'), isTrue);
      expect(result.quality, lessThan(100));
    });

    test('Bug #6 Fix - Alignment rule: uses vertical angle comparison', () {
      final bicepCurl = ExerciseRegistry.findByKey('bicep_curl')!;
      
      // curl_upper_arm_still requires shoulder (jointA) and elbow (jointB) alignment.
      // Case A: Perfectly aligned vertically: Shoulder = (0.5, 0.2), Elbow = (0.5, 0.5)
      final poseAligned = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.5, 0.8),
      });

      analyzer.reset();
      // Go to top phase
      var result = analyzer.analyze(poseAligned, bicepCurl);
      expect(result.violations.any((v) => v.ruleId == 'curl_upper_arm_still'), isFalse);

      // Case B: Tilted upper arm by 45 degrees: Shoulder = (0.5, 0.2), Elbow = (0.8, 0.5)
      // dx = 0.3, dy = 0.3. atan2(dx, dy) = 45 degrees.
      // 45 degrees > 15 degree tolerance -> violation severity should be around (45-15)/30 = 1.0.
      final poseTilted = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.8, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.8, 0.8),
      });

      result = analyzer.analyze(poseTilted, bicepCurl);
      final alignmentViolation = result.violations.firstWhere((v) => v.ruleId == 'curl_upper_arm_still');
      expect(alignmentViolation, isNotNull);
      expect(alignmentViolation.severity, closeTo(1.0, 0.05));
    });

    test('Bug #6 Fix - Symmetry rule: uses 10% height tolerance', () {
      final bicepCurl = ExerciseRegistry.findByKey('bicep_curl')!;
      
      // curl_symmetry compares leftElbow and rightElbow y-coordinates.
      // Case A: Within 10% tolerance (e.g. leftElbow.y = 0.50, rightElbow.y = 0.55 -> diff 5%)
      final poseSymmetric = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.4, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.4, 0.50),
        PoseLandmarkType.leftWrist: const _Point(0.4, 0.8),
        PoseLandmarkType.rightShoulder: const _Point(0.6, 0.2),
        PoseLandmarkType.rightElbow: const _Point(0.6, 0.55),
        PoseLandmarkType.rightWrist: const _Point(0.6, 0.8),
      });

      analyzer.reset();
      var result = analyzer.analyze(poseSymmetric, bicepCurl);
      expect(result.violations.any((v) => v.ruleId == 'curl_symmetry'), isFalse);

      // Case B: Outside 10% tolerance (e.g. leftElbow.y = 0.50, rightElbow.y = 0.70 -> diff 20%)
      // Severity is ((0.20 - 0.10) / 0.20) = 0.5.
      final poseAsymmetric = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.4, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.4, 0.50),
        PoseLandmarkType.leftWrist: const _Point(0.4, 0.8),
        PoseLandmarkType.rightShoulder: const _Point(0.6, 0.2),
        PoseLandmarkType.rightElbow: const _Point(0.6, 0.70),
        PoseLandmarkType.rightWrist: const _Point(0.6, 0.95),
      });

      result = analyzer.analyze(poseAsymmetric, bicepCurl);
      final symmetryViolation = result.violations.firstWhere((v) => v.ruleId == 'curl_symmetry');
      expect(symmetryViolation, isNotNull);
      expect(symmetryViolation.severity, closeTo(0.5, 0.05));
    });
  });

  group('ExerciseAnalyzerService - Auto Detection (Discovery Mode)', () {
    test('Detects exercise matching angle configuration', () {
      // Create pose with a bicep-curl-like angle (e.g. 90 degrees)
      final pose = createMockPose({
        PoseLandmarkType.leftShoulder: const _Point(0.5, 0.2),
        PoseLandmarkType.leftElbow: const _Point(0.5, 0.5),
        PoseLandmarkType.leftWrist: const _Point(0.8, 0.5),
      });

      final result = analyzer.analyzeDiscovery(pose);
      expect(result.detectedExerciseKey, equals('bicep_curl'));
      expect(result.exerciseConfidence, greaterThan(0.5));
    });
  });
}

// Simple point helper for pose definitions
class _Point {
  final double x;
  final double y;
  final double likelihood;

  const _Point(this.x, this.y, {this.likelihood = 0.99});
}
