// lib/features/workout/presentation/providers/ai_workout_provider.dart
//
// COMPLETELY REWRITTEN: On-device AI workout tracking using Google ML Kit.
//
// Previous version: Sent every camera frame to a remote API (2 FPS max,
// unreliable, no offline support, privacy concerns).
//
// New version: On-device pose detection + local exercise analysis.
//   • Zero latency (ML Kit runs at 30+ FPS on modern phones)
//   • Works offline
//   • Free (no API costs)
//   • Private (no images leave the device)
//   • Accurate (custom angle-based rep counting & form analysis)
//
// Architecture:
//   CameraImage → PoseDetectorService → ExerciseAnalyzerService → UI
//                 (ML Kit Pose)          (Angle math / state machine)

import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/exercise_definitions.dart';
import '../../data/services/exercise_analyzer_service.dart';
import '../../data/services/pose_detector_service.dart';

// ─── State Enum ───────────────────────────────────────────────────────────────

enum AiWorkoutState { idle, initializing, active, paused, finished, error }

// ─── Provider ─────────────────────────────────────────────────────────────────

class AiWorkoutProvider extends ChangeNotifier {
  // ── Services ─────────────────────────────────────────────────────────────
  final PoseDetectorService _poseService = PoseDetectorService();
  final ExerciseAnalyzerService _analyzer = ExerciseAnalyzerService();

  // ── Camera ───────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  int _sensorOrientation = 0;
  bool _isFrontCamera = true;

  // ── Session State ────────────────────────────────────────────────────────
  AiWorkoutState _state = AiWorkoutState.idle;
  String? _errorMessage;

  // ── Exercise Selection ───────────────────────────────────────────────────
  ExerciseDefinition? _selectedExercise;
  final List<ExerciseDefinition> _availableExercises = ExerciseRegistry.all;

  // ── Analysis State ───────────────────────────────────────────────────────
  ExerciseFrameAnalysis? _lastAnalysis;
  PoseDetectionResult? _lastPoseResult;
  bool _isProcessingFrame = false;

  // ── Stats ────────────────────────────────────────────────────────────────
  int _totalReps = 0;
  int _currentQuality = 0;
  double _sessionAvgQuality = 0;
  DateTime? _sessionStartTime;
  Duration _sessionDuration = Duration.zero;

  // ── Frame Rate Control ───────────────────────────────────────────────────
  // On-device ML Kit is MUCH faster than the old API approach.
  // We can process every frame (30fps) but throttle to ~15fps to save battery.
  static const Duration _analysisInterval = Duration(
    milliseconds: 33,
  ); // ~30 FPS
  DateTime? _lastFrameTime;

  // ── Rep History (for summary) ────────────────────────────────────────────
  final List<DateTime> _repTimestamps = [];

  // ── Quality History (for sparkline in summary) ──────────────────────────
  final List<int> _qualityHistory = [];

  // ══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════════════════════

  CameraController? get cameraController => _cameraController;
  AiWorkoutState get state => _state;
  String? get errorMessage => _errorMessage;
  ExerciseDefinition? get selectedExercise => _selectedExercise;
  List<ExerciseDefinition> get availableExercises => _availableExercises;
  ExerciseFrameAnalysis? get lastAnalysis => _lastAnalysis;
  PoseDetectionResult? get lastPoseResult => _lastPoseResult;
  int get totalReps => _totalReps;
  int get currentQuality => _currentQuality;
  double get sessionAvgQuality => _sessionAvgQuality;
  Duration get sessionDuration => _sessionDuration;
  List<DateTime> get repTimestamps => List.unmodifiable(_repTimestamps);
  List<int> get qualityHistory => List.unmodifiable(_qualityHistory);
  bool get isProcessingFrame => _isProcessingFrame;

  /// Current exercise phase as human-readable string.
  String get phaseLabel {
    switch (_lastAnalysis?.phase) {
      case ExercisePhase.idle:
        return 'Ready';
      case ExercisePhase.descending:
        return 'Lowering';
      case ExercisePhase.bottom:
        return 'Bottom';
      case ExercisePhase.ascending:
        return 'Raising';
      case ExercisePhase.top:
        return 'Top';
      default:
        return 'Ready';
    }
  }

  /// Whether a pose was detected in the last frame.
  bool get poseDetected => _lastPoseResult?.poseDetected ?? false;

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  /// Initialize camera + ML Kit pose detector.
  Future<void> initialize() async {
    if (_state == AiWorkoutState.initializing) return;

    _state = AiWorkoutState.initializing;
    notifyListeners();

    try {
      // 1. Initialize ML Kit Pose Detector
      await _poseService.initialize();

      // 2. Setup Camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras found on this device');
      }

      // Prefer front camera for training (user faces the phone)
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _sensorOrientation = frontCamera.sensorOrientation;
      _isFrontCamera = frontCamera.lensDirection == CameraLensDirection.front;

      _cameraController = CameraController(
        frontCamera,
        // Use medium resolution — ML Kit is accurate even at 640x480,
        // and this keeps CPU/battery usage reasonable.
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      _state = AiWorkoutState.idle;
      _errorMessage = null;

      debugPrint('[AiWorkoutProvider] Initialized: ML Kit + Camera ready');
    } catch (e) {
      _state = AiWorkoutState.error;
      _errorMessage = 'Initialization failed: $e';
      debugPrint('[AiWorkoutProvider] initialize error: $e');
    }

    notifyListeners();
  }

  /// Start the AI analysis session.
  Future<void> startSession(ExerciseDefinition? exercise) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _selectedExercise = exercise;
    _state = AiWorkoutState.active;

    // Reset all state
    _totalReps = 0;
    _currentQuality = 0;
    _sessionAvgQuality = 0;
    _lastAnalysis = null;
    _lastPoseResult = null;
    _isProcessingFrame = false;
    _lastFrameTime = null;
    _sessionStartTime = DateTime.now();
    _sessionDuration = Duration.zero;
    _repTimestamps.clear();
    _qualityHistory.clear();
    _analyzer.reset();

    // Start streaming camera images
    if (!_cameraController!.value.isStreamingImages) {
      await _cameraController!.startImageStream(_processCameraImage);
    }

    // Start a timer to track session duration
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStartTime != null && _state == AiWorkoutState.active) {
        _sessionDuration = DateTime.now().difference(_sessionStartTime!);
        // Don't notifyListeners on every tick — only when we have analysis updates
      }
    });

    notifyListeners();
  }

  Timer? _durationTimer;

  /// Pause the session (stops processing frames but camera stays live).
  void pauseSession() {
    _state = AiWorkoutState.paused;
    _durationTimer?.cancel();
    notifyListeners();
  }

  /// Resume the session.
  void resumeSession() {
    _state = AiWorkoutState.active;
    _sessionStartTime = DateTime.now().subtract(_sessionDuration);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStartTime != null && _state == AiWorkoutState.active) {
        _sessionDuration = DateTime.now().difference(_sessionStartTime!);
      }
    });
    notifyListeners();
  }

  /// Stop the session and clean up resources.
  Future<void> stopSession() async {
    _durationTimer?.cancel();

    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (e) {
        debugPrint('[AiWorkoutProvider] stopImageStream error: $e');
      }
    }

    _state = AiWorkoutState.finished;
    notifyListeners();
  }

  /// Release camera and pose detector resources.
  /// Call when leaving the recognition screen to free hardware.
  Future<void> releaseCamera() async {
    _durationTimer?.cancel();

    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        try {
          await _cameraController!.stopImageStream();
        } catch (e) {
          debugPrint('[AiWorkoutProvider] stopImageStream error: $e');
        }
      }
      try {
        await _cameraController!.dispose();
      } catch (e) {
        debugPrint('[AiWorkoutProvider] camera dispose error: $e');
      }
      _cameraController = null;
    }

    _poseService.dispose();
    _state = AiWorkoutState.idle;
    _isProcessingFrame = false;
    notifyListeners();
  }

  /// Select an exercise at any time (resets rep counting).
  void selectExercise(ExerciseDefinition exercise) {
    _selectedExercise = exercise;
    _totalReps = 0;
    _currentQuality = 0;
    _sessionAvgQuality = 0;
    _lastAnalysis = null;
    _lastPoseResult = null;
    _repTimestamps.clear();
    _qualityHistory.clear();
    _analyzer.reset();
    notifyListeners();
  }

  /// Switch camera (front ↔ back).
  Future<void> switchCamera() async {
    if (_cameraController == null) return;

    final wasStreaming = _cameraController!.value.isStreamingImages;
    if (wasStreaming) {
      await _cameraController!.stopImageStream();
    }

    final cameras = await availableCameras();
    final newCamera = _isFrontCamera
        ? cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          )
        : cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

    await _cameraController!.dispose();

    _sensorOrientation = newCamera.sensorOrientation;
    _isFrontCamera = newCamera.lensDirection == CameraLensDirection.front;

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();

    if (wasStreaming && _state == AiWorkoutState.active) {
      await _cameraController!.startImageStream(_processCameraImage);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CAMERA FRAME PROCESSING PIPELINE
  // ══════════════════════════════════════════════════════════════════════════

  void _processCameraImage(CameraImage image) async {
    // Only process in active state
    if (_state != AiWorkoutState.active) return;

    // Drop frame if still processing the previous one
    if (_isProcessingFrame) return;

    // Throttle to target FPS
    final now = DateTime.now();
    if (_lastFrameTime != null &&
        now.difference(_lastFrameTime!) < _analysisInterval) {
      return;
    }

    _isProcessingFrame = true;
    _lastFrameTime = now;

    try {
      // ── Step 1: Run ML Kit Pose Detection (on-device, fast) ───────────────
      final poseResult = await _poseService.processFrame(
        image,
        sensorOrientation: _sensorOrientation,
        imageWidth: image.width,
        imageHeight: image.height,
      );

      _lastPoseResult = poseResult;

      // ── Step 2: Run Exercise Analysis (local math, instant) ───────────────
      ExerciseFrameAnalysis analysis;

      if (_selectedExercise != null) {
        analysis = _analyzer.analyze(poseResult, _selectedExercise);
      } else {
        analysis = _analyzer.analyzeDiscovery(poseResult);
      }

      _lastAnalysis = analysis;

      // ── Step 3: Update stats from analysis ────────────────────────────────
      _totalReps = analysis.reps;
      _currentQuality = analysis.quality;
      _sessionAvgQuality = analysis.sessionAvgQuality;

      // Track rep timestamps
      if (analysis.repJustCounted) {
        _repTimestamps.add(now);
        HapticFeedback.mediumImpact();
      }

      // Track quality history using a sliding window.
      // Keep the most recent 300 samples (~20 seconds at 15fps).
      _qualityHistory.add(analysis.quality);
      if (_qualityHistory.length > 300) {
        _qualityHistory.removeAt(0);
      }

      // BUG #13 FIX: Guard with state check to prevent calling
      // notifyListeners after the screen is disposed.
      if (_state == AiWorkoutState.active) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AiWorkoutProvider] frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SESSION SUMMARY
  // ══════════════════════════════════════════════════════════════════════════

  /// Generate a summary of the completed session.
  AiSessionSummary getSummary() {
    return AiSessionSummary(
      exerciseName: _selectedExercise?.displayName ?? 'Workout',
      exerciseKey: _selectedExercise?.key ?? 'unknown',
      totalReps: _totalReps,
      averageQuality: _sessionAvgQuality.round(),
      duration: _sessionDuration,
      qualityHistory: List.from(_qualityHistory),
      repTimestamps: List.from(_repTimestamps),
      bestStreak: _calculateBestRepStreak(),
      peakQuality: _qualityHistory.isNotEmpty
          ? _qualityHistory.reduce((a, b) => a > b ? a : b)
          : 0,
    );
  }

  int _calculateBestRepStreak() {
    if (_repTimestamps.length < 2) return _repTimestamps.length;

    int bestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < _repTimestamps.length; i++) {
      final gap = _repTimestamps[i].difference(_repTimestamps[i - 1]);
      // Reps within 5 seconds of each other count as a streak
      if (gap.inSeconds <= 5) {
        currentStreak++;
        bestStreak = max(bestStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }

    return bestStreak;
  }
}

// ─── Session Summary ──────────────────────────────────────────────────────────

class AiSessionSummary {
  final String exerciseName;
  final String exerciseKey;
  final int totalReps;
  final int averageQuality;
  final Duration duration;
  final List<int> qualityHistory;
  final List<DateTime> repTimestamps;
  final int bestStreak;
  final int peakQuality;

  const AiSessionSummary({
    required this.exerciseName,
    required this.exerciseKey,
    required this.totalReps,
    required this.averageQuality,
    required this.duration,
    required this.qualityHistory,
    required this.repTimestamps,
    required this.bestStreak,
    required this.peakQuality,
  });

  String get formattedDuration {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Average reps per minute.
  double get repsPerMinute {
    if (duration.inMinutes == 0) return 0;
    return totalReps / duration.inMinutes;
  }
}
