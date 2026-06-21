// lib/features/workout/data/services/exercise_analyzer_service.dart
//
// Core exercise analysis engine — runs entirely on-device.
//
// This service is the "brain" of the AI Vision feature. It takes detected
// pose landmarks and produces:
//   • Exercise phase detection (which phase of the movement the user is in)
//   • Rep counting (state-machine based, angle-threshold driven)
//   • Form quality scoring (0-100, based on configurable rules)
//   • Real-time coaching tips (based on which form rules are violated)
//   • Automatic exercise detection (in discovery mode, by matching angle patterns)
//
// The state machine follows this flow:
//   IDLE → DESCENDING → BOTTOM → ASCENDING → TOP (= 1 rep) → DESCENDING → ...
//
// Angle smoothing uses exponential moving average to prevent jitter.

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/exercise_definitions.dart';
import 'pose_detector_service.dart';

// ─── Data Classes ─────────────────────────────────────────────────────────────

/// The phase of the exercise movement.
enum ExercisePhase {
  idle, // No movement detected / waiting
  descending, // Eccentric phase (lowering weight / going down)
  bottom, // Reached the bottom position
  ascending, // Concentric phase (raising weight / going up)
  top, // Returned to start position (rep complete!)
}

/// Complete analysis result for a single frame.
class ExerciseFrameAnalysis {
  final ExercisePhase phase;
  final double primaryAngle; // Current angle of the primary joint (degrees)
  final int reps; // Cumulative rep count
  final int quality; // Current form quality score (0-100)
  final double sessionAvgQuality; // Session average quality
  final bool repJustCounted; // True on the exact frame a rep was completed
  final List<String> tips; // Active coaching tips
  final List<FormViolation> violations; // Current form violations
  final String? detectedExerciseKey; // Auto-detected exercise (discovery mode)
  final double exerciseConfidence; // Confidence of detection (0-1)
  final double holdDuration; // For hold-based exercises, seconds held

  const ExerciseFrameAnalysis({
    required this.phase,
    required this.primaryAngle,
    required this.reps,
    required this.quality,
    this.sessionAvgQuality = 0,
    this.repJustCounted = false,
    this.tips = const [],
    this.violations = const [],
    this.detectedExerciseKey,
    this.exerciseConfidence = 0,
    this.holdDuration = 0,
  });
}

/// A form rule violation detected in the current frame.
class FormViolation {
  final String ruleId;
  final String name;
  final String tip;
  final double severity; // 0-1, how badly the rule is violated

  const FormViolation({
    required this.ruleId,
    required this.name,
    required this.tip,
    required this.severity,
  });
}

// ─── Exercise Analyzer Service ────────────────────────────────────────────────

class ExerciseAnalyzerService {
  // ── State ──────────────────────────────────────────────────────────────────

  ExercisePhase _phase = ExercisePhase.idle;
  int _reps = 0;
  double _smoothedAngle = 0;
  bool _isFirstFrame = true;

  // Quality tracking
  double _sessionQualitySum = 0;
  int _validFramesAnalyzed = 0;

  // Hold-based exercise tracking
  DateTime? _holdStartTime;
  double _currentHoldSeconds = 0;

  // Angle smoothing factor (0-1). Higher = more responsive, lower = smoother.
  static const double _smoothingFactor = 0.4;

  // Hysteresis threshold: how far past the threshold angle the joint must
  // go before we transition phases. Prevents oscillation at boundaries.
  static const double _hysteresisDeg = 8.0;

  // Minimum time between counted reps (ms). Prevents double-counting.
  static const int _minRepIntervalMs = 400;

  DateTime? _lastRepTime;

  // Track when the last valid angle was computed (for stale angle detection)
  DateTime? _lastAngleTime;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Analyze a single frame of pose data against the selected exercise.
  ///
  /// [poseResult] - The detected pose landmarks from PoseDetectorService
  /// [exercise] - The exercise definition to analyze against (null = discovery mode)
  ExerciseFrameAnalysis analyze(
    PoseDetectionResult poseResult,
    ExerciseDefinition? exercise,
  ) {
    if (!poseResult.poseDetected || exercise == null) {
      return ExerciseFrameAnalysis(
        phase: ExercisePhase.idle,
        primaryAngle: _smoothedAngle,
        reps: _reps,
        quality: 0,
        sessionAvgQuality: _sessionAverage,
        tips: exercise != null
            ? ['Position yourself so your full body is visible']
            : ['Select an exercise to begin'],
      );
    }

    // ── Step 1: Calculate primary angle ─────────────────────────────────────
    final angle = _calculateAngle(
      poseResult,
      exercise.primaryAngle.startJoint,
      exercise.primaryAngle.midJoint,
      exercise.primaryAngle.endJoint,
    );

    if (angle == null) {
      return ExerciseFrameAnalysis(
        phase: _phase,
        primaryAngle: _smoothedAngle,
        reps: _reps,
        quality: _sessionQualitySum > 0 ? _currentQuality.round() : 0,
        sessionAvgQuality: _sessionAverage,
        tips: ['Make sure your full body is in the camera frame'],
      );
    }

    // ── Step 2: Smooth the angle (exponential moving average) ────────────────
    // BUG #7 FIX: If too much time has passed since the last valid angle
    // (e.g. user left frame), treat this as a fresh start to avoid
    // blending with a stale _smoothedAngle.
    final now = DateTime.now();
    final bool isStale = _lastAngleTime != null &&
        now.difference(_lastAngleTime!).inMilliseconds > 500;

    if (_isFirstFrame || isStale) {
      _smoothedAngle = angle;
      _isFirstFrame = false;
    } else {
      _smoothedAngle =
          _smoothedAngle * (1 - _smoothingFactor) + angle * _smoothingFactor;
    }
    _lastAngleTime = now;

    // ── Step 3: Detect phase transitions ─────────────────────────────
    final prevPhase = _phase;

    _detectPhaseTransition(exercise);

    // ── Step 4: Rep counting ─────────────────────────────────────────────────
    bool repJustCounted = false;

    if (exercise.type == ExerciseType.reps) {
      repJustCounted = _checkRepCounted(exercise, prevPhase);
    } else if (exercise.type == ExerciseType.hold) {
      _updateHoldTimer();
    }

    // ── Step 5: Form quality analysis ────────────────────────────────────────
    final violations = _evaluateFormRules(poseResult, exercise);
    final quality = _computeQualityScore(violations, exercise);

    // ── Step 6: Update session quality stats ─────────────────────────────────
    if (poseResult.poseDetected && _phase != ExercisePhase.idle) {
      _sessionQualitySum += quality;
      _validFramesAnalyzed++;
    }

    // ── Step 7: Generate coaching tips ───────────────────────────────────────
    final tips = _generateTips(violations, exercise);

    return ExerciseFrameAnalysis(
      phase: _phase,
      primaryAngle: _smoothedAngle,
      reps: _reps,
      quality: quality,
      sessionAvgQuality: _sessionAverage,
      repJustCounted: repJustCounted,
      tips: tips,
      violations: violations,
      holdDuration: _currentHoldSeconds,
    );
  }

  /// Analyze a frame in discovery mode (no exercise pre-selected).
  /// Attempts to auto-detect which exercise the user is doing by matching
  /// angle patterns across all known exercises.
  ExerciseFrameAnalysis analyzeDiscovery(PoseDetectionResult poseResult) {
    if (!poseResult.poseDetected) {
      return const ExerciseFrameAnalysis(
        phase: ExercisePhase.idle,
        primaryAngle: 0,
        reps: 0,
        quality: 0,
        tips: ['Stand in front of the camera so I can detect your exercise'],
      );
    }

    String? bestMatch;
    double bestConfidence = 0;

    // Calculate angles for all exercises and see which one matches best
    for (final exercise in ExerciseRegistry.all) {
      final angle = _calculateAngle(
        poseResult,
        exercise.primaryAngle.startJoint,
        exercise.primaryAngle.midJoint,
        exercise.primaryAngle.endJoint,
      );

      if (angle == null) continue;

      // Check if the current angle is within the exercise's expected range
      final minAngle = min(
        exercise.primaryAngle.topAngle,
        exercise.primaryAngle.bottomAngle,
      );
      final maxAngle = max(
        exercise.primaryAngle.topAngle,
        exercise.primaryAngle.bottomAngle,
      );

      if (angle >= minAngle - 20 && angle <= maxAngle + 20) {
        // Calculate confidence based on how well it fits
        final rangeCenter = (minAngle + maxAngle) / 2;
        final rangeHalf = (maxAngle - minAngle) / 2;
        final deviation = (angle - rangeCenter).abs() / rangeHalf;
        final confidence = (1.0 - deviation.clamp(0.0, 1.0));

        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestMatch = exercise.key;
        }
      }
    }

    return ExerciseFrameAnalysis(
      phase: ExercisePhase.idle,
      primaryAngle: _smoothedAngle,
      reps: 0,
      quality: 0,
      detectedExerciseKey: bestMatch,
      exerciseConfidence: bestConfidence,
      tips: bestMatch != null
          ? [
              'Detected: ${ExerciseRegistry.findByKey(bestMatch)?.displayName ?? bestMatch}',
            ]
          : ['Perform an exercise and I\'ll detect it automatically'],
    );
  }

  /// Reset all state for a new exercise or session.
  void reset() {
    _phase = ExercisePhase.idle;
    _reps = 0;
    _smoothedAngle = 0;
    _isFirstFrame = true;
    _sessionQualitySum = 0;
    _validFramesAnalyzed = 0;
    _holdStartTime = null;
    _currentHoldSeconds = 0;
    _lastRepTime = null;
    _lastAngleTime = null;
  }

  // ── Private: Angle Calculation ──────────────────────────────────────────────

  /// Calculate the angle (in degrees) formed by three joints.
  /// The angle is measured at [midJoint] between [startJoint] and [endJoint].
  double? _calculateAngle(
    PoseDetectionResult pose,
    PoseLandmarkType startJoint,
    PoseLandmarkType midJoint,
    PoseLandmarkType endJoint,
  ) {
    final start = pose.getLandmark(startJoint);
    final mid = pose.getLandmark(midJoint);
    final end = pose.getLandmark(endJoint);

    if (start == null || mid == null || end == null) return null;

    // Skip if any landmark has low confidence
    if (start.likelihood < 0.5 ||
        mid.likelihood < 0.5 ||
        end.likelihood < 0.5) {
      return null;
    }

    // Vector from mid to start
    final vectorAX = start.x - mid.x;
    final vectorAY = start.y - mid.y;

    // Vector from mid to end
    final vectorBX = end.x - mid.x;
    final vectorBY = end.y - mid.y;

    // Dot product and magnitudes
    final dotProduct = vectorAX * vectorBX + vectorAY * vectorBY;
    final magnitudeA = sqrt(vectorAX * vectorAX + vectorAY * vectorAY);
    final magnitudeB = sqrt(vectorBX * vectorBX + vectorBY * vectorBY);

    if (magnitudeA < 1e-6 || magnitudeB < 1e-6) return null;

    // Cosine of the angle
    final cosAngle = (dotProduct / (magnitudeA * magnitudeB)).clamp(-1.0, 1.0);

    // Convert to degrees
    return acos(cosAngle) * (180 / pi);
  }

  // ── Private: Phase Detection ────────────────────────────────────────────────

  /// Detect phase transitions using the current smoothed angle and thresholds.
  void _detectPhaseTransition(ExerciseDefinition exercise) {
    final config = exercise.primaryAngle;
    final angle = _smoothedAngle;

    // Determine which angle value represents "top" and "bottom"
    // In "closing" direction: topAngle > bottomAngle (e.g., bicep curl: 170° → 40°)
    // In "opening" direction: bottomAngle > topAngle (e.g., lateral raise: 15° → 85°)
    final topThreshold = config.topAngle;
    final bottomThreshold = config.bottomAngle;

    // Add hysteresis to prevent oscillation
    final topHyst =
        topThreshold +
        (config.direction == AngleDirection.closing
            ? -_hysteresisDeg
            : _hysteresisDeg);
    final bottomHyst =
        bottomThreshold +
        (config.direction == AngleDirection.closing
            ? _hysteresisDeg
            : -_hysteresisDeg);

    switch (_phase) {
      case ExercisePhase.idle:
        // BUG #4 FIX: Allow entry from a wider range of positions.
        // Original code required _isNearTop which was too strict — users
        // had to start in a perfect start position or reps never counted.
        if (_isNearTop(angle, config)) {
          _phase = ExercisePhase.top;
        } else if (_isNearBottom(angle, config)) {
          _phase = ExercisePhase.bottom;
        } else {
          // Check if the angle is within the exercise's operating range
          final minA = min(config.topAngle, config.bottomAngle);
          final maxA = max(config.topAngle, config.bottomAngle);
          if (angle >= minA - 20 && angle <= maxA + 20) {
            // User is in range — start at the closest phase
            final distToTop = (angle - config.topAngle).abs();
            final distToBottom = (angle - config.bottomAngle).abs();
            _phase = distToTop <= distToBottom
                ? ExercisePhase.top
                : ExercisePhase.bottom;
          }
        }
        break;

      case ExercisePhase.top:
        // User starts descending
        if (config.direction == AngleDirection.closing) {
          if (angle < topHyst) _phase = ExercisePhase.descending;
        } else {
          if (angle > topHyst) _phase = ExercisePhase.descending;
        }
        break;

      case ExercisePhase.descending:
        // Check if reached bottom
        if (_isNearBottom(angle, config)) {
          _phase = ExercisePhase.bottom;
        } else if (_returnedToTop(angle, config)) {
          // Returned to top without reaching bottom = partial rep, reset
          _phase = ExercisePhase.top;
        }
        break;

      case ExercisePhase.bottom:
        // User starts ascending
        if (config.direction == AngleDirection.closing) {
          if (angle > bottomHyst) _phase = ExercisePhase.ascending;
        } else {
          if (angle < bottomHyst) _phase = ExercisePhase.ascending;
        }
        break;

      case ExercisePhase.ascending:
        // Check if returned to top = rep complete!
        if (_isNearTop(angle, config)) {
          _phase = ExercisePhase.top;
        } else if (_returnedToBottom(angle, config)) {
          // Went back down without reaching top = partial, go back to bottom
          _phase = ExercisePhase.bottom;
        }
        break;
    }
  }

  bool _isNearTop(double angle, AngleConfig config) {
    if (config.direction == AngleDirection.closing) {
      return angle >= config.topAngle - 15;
    } else {
      return angle <= config.topAngle + 15;
    }
  }

  bool _isNearBottom(double angle, AngleConfig config) {
    if (config.direction == AngleDirection.closing) {
      return angle <= config.bottomAngle + 15;
    } else {
      return angle >= config.bottomAngle - 15;
    }
  }

  bool _returnedToTop(double angle, AngleConfig config) {
    if (config.direction == AngleDirection.closing) {
      return angle > config.topAngle - 10;
    } else {
      return angle < config.topAngle + 10;
    }
  }

  bool _returnedToBottom(double angle, AngleConfig config) {
    if (config.direction == AngleDirection.closing) {
      return angle < config.bottomAngle + 10;
    } else {
      return angle > config.bottomAngle - 10;
    }
  }

  // ── Private: Rep Counting ───────────────────────────────────────────────────

  /// Check if a rep was just completed (transition: ascending → top).
  bool _checkRepCounted(ExerciseDefinition exercise, ExercisePhase prevPhase) {
    if (prevPhase == ExercisePhase.ascending && _phase == ExercisePhase.top) {
      // Debounce: minimum time between reps
      final now = DateTime.now();
      if (_lastRepTime != null &&
          now.difference(_lastRepTime!).inMilliseconds < _minRepIntervalMs) {
        return false;
      }

      _reps++;
      _lastRepTime = now;
      return true;
    }
    return false;
  }

  /// Update hold timer for hold-based exercises.
  void _updateHoldTimer() {
    if (_phase == ExercisePhase.top || _phase == ExercisePhase.idle) {
      // In a "hold" position (e.g., plank — body straight is "top")
      _holdStartTime ??= DateTime.now();
      _currentHoldSeconds =
          DateTime.now().difference(_holdStartTime!).inMilliseconds / 1000.0;
    } else {
      // Lost the hold position
      _holdStartTime = null;
      _currentHoldSeconds = 0;
    }
  }

  // ── Private: Form Quality ───────────────────────────────────────────────────

  /// Evaluate all form rules for the exercise and return violations.
  List<FormViolation> _evaluateFormRules(
    PoseDetectionResult pose,
    ExerciseDefinition exercise,
  ) {
    final violations = <FormViolation>[];

    for (final rule in exercise.formRules) {
      // BUG #5 FIX: Skip rules that don't apply to the current phase.
      // This prevents false-positive violations (e.g. squat_depth firing
      // when standing upright at the top of the squat).
      if (rule.activePhases != null &&
          !rule.activePhases!.contains(_phase.name)) {
        continue;
      }

      double severity = 0;

      switch (rule.type) {
        case RuleType.angle:
          severity = _evaluateAngleRule(pose, rule);
          break;
        case RuleType.alignment:
          severity = _evaluateAlignmentRule(pose, rule);
          break;
        case RuleType.symmetry:
          severity = _evaluateSymmetryRule(pose, rule);
          break;
      }

      // Only report violations above a small threshold (avoid noise)
      if (severity > 0.15) {
        violations.add(
          FormViolation(
            ruleId: rule.id,
            name: rule.name,
            tip: rule.tipWhenViolated,
            severity: severity,
          ),
        );
      }
    }

    return violations;
  }

  /// Evaluate an angle-based form rule.
  /// Returns severity 0 (perfect) to 1 (very bad).
  double _evaluateAngleRule(PoseDetectionResult pose, FormRule rule) {
    if (rule.jointC == null) return 0;

    final angle = _calculateAngle(pose, rule.jointA, rule.jointB, rule.jointC!);
    if (angle == null) return 0;

    final idealMin = rule.idealMin ?? 0;
    final idealMax = rule.idealMax ?? 180;

    if (angle >= idealMin && angle <= idealMax) {
      return 0; // Within ideal range
    }

    // Calculate how far outside the ideal range
    final rangeSize = idealMax - idealMin;
    if (rangeSize <= 0) return 0;

    double deviation;
    if (angle < idealMin) {
      deviation = idealMin - angle;
    } else {
      deviation = angle - idealMax;
    }

    // Normalize deviation relative to the range size
    return (deviation / rangeSize).clamp(0.0, 1.0);
  }

  /// Evaluate an alignment-based form rule.
  /// BUG #6 FIX: Use angle-from-vertical instead of raw pixel diffs.
  /// This is scale-invariant and eliminates the dead-code else branch.
  double _evaluateAlignmentRule(PoseDetectionResult pose, FormRule rule) {
    final lmA = pose.getLandmark(rule.jointA);
    final lmB = pose.getLandmark(rule.jointB);

    if (lmA == null || lmB == null) return 0;
    if (lmA.likelihood < 0.5 || lmB.likelihood < 0.5) return 0;

    // Compute the angle of the vector A→B from vertical (Y-axis).
    // For "shoulder over hip" type alignment, this angle should be small.
    final dx = (lmA.x - lmB.x).abs();
    final dy = (lmA.y - lmB.y).abs();

    if (dx < 1e-6 && dy < 1e-6) return 0; // Same point

    // Angle from vertical in degrees (0 = perfectly vertical)
    final angleFromVertical = atan2(dx, dy) * (180 / pi);

    // Tolerance: 15° from vertical is acceptable
    const toleranceDeg = 15.0;
    if (angleFromVertical <= toleranceDeg) return 0;

    // Severity scales from 0 at 15° to 1 at 45°
    return ((angleFromVertical - toleranceDeg) / 30.0).clamp(0.0, 1.0);
  }

  /// Evaluate a symmetry-based form rule.
  /// BUG #6 FIX: Increased tolerance from 5% to 10% and removed dead xDiff.
  /// The tight 5% threshold caused constant false positives, especially
  /// in profile view where one side is naturally occluded.
  double _evaluateSymmetryRule(PoseDetectionResult pose, FormRule rule) {
    final lmA = pose.getLandmark(rule.jointA);
    final lmB = pose.getLandmark(rule.jointB);

    if (lmA == null || lmB == null) return 0;
    if (lmA.likelihood < 0.5 || lmB.likelihood < 0.5) return 0;

    // Compare Y positions (height) — symmetric joints should be at similar heights.
    // Use a generous tolerance (10% of image height) to account for
    // camera angle, profile view occlusion, and natural asymmetry.
    final yDiff = (lmA.y - lmB.y).abs();

    const tolerance = 0.10; // 10% of normalized height
    if (yDiff <= tolerance) return 0;

    // Severity scales from 0 at 10% to 1 at 30%
    return ((yDiff - tolerance) / 0.20).clamp(0.0, 1.0);
  }

  /// Compute overall quality score (0-100) from violations.
  int _computeQualityScore(
    List<FormViolation> violations,
    ExerciseDefinition exercise,
  ) {
    if (exercise.formRules.isEmpty) {
      // No rules defined — give a default score based on pose confidence
      return 75;
    }

    // Start at 100, subtract for each violation weighted by its rule weight
    double score = 100;

    for (final violation in violations) {
      // BUG #16 FIX: Use try/catch instead of orElse with a fake rule.
      // Skip violations whose rule can't be found (should never happen).
      FormRule? rule;
      try {
        rule = exercise.formRules.firstWhere(
          (r) => r.id == violation.ruleId,
        );
      } catch (_) {
        debugPrint(
          '[ExerciseAnalyzer] Warning: violation "${violation.ruleId}" '
          'has no matching form rule — skipping',
        );
        continue;
      }

      // Deduction = weight * severity * maxPenalty
      score -= rule.weight * violation.severity * 100;
    }

    return score.round().clamp(0, 100);
  }

  int get _currentQuality {
    if (_validFramesAnalyzed == 0) return 0;
    return (_sessionQualitySum / _validFramesAnalyzed).round().clamp(0, 100);
  }

  double get _sessionAverage {
    if (_validFramesAnalyzed == 0) return 0;
    return _sessionQualitySum / _validFramesAnalyzed;
  }

  // ── Private: Coaching Tips ──────────────────────────────────────────────────

  /// Generate prioritized coaching tips from current violations.
  List<String> _generateTips(
    List<FormViolation> violations,
    ExerciseDefinition exercise,
  ) {
    final tips = <String>[];

    // Sort violations by severity (worst first)
    final sorted = List<FormViolation>.from(violations)
      ..sort((a, b) => b.severity.compareTo(a.severity));

    // Take top 2 most severe violations
    for (final v in sorted.take(2)) {
      tips.add(v.tip);
    }

    // If no violations, add a positive tip from the exercise definition
    if (tips.isEmpty && exercise.tips.isNotEmpty) {
      // Rotate through tips
      final tipIndex = (_reps % exercise.tips.length);
      tips.add(exercise.tips[tipIndex]);
    }

    return tips;
  }
}
