import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../domain/entities/workout_session.dart';
import '../../domain/usecases/start_workout_session_usecase.dart';
import '../../domain/usecases/finish_workout_session_usecase.dart';
import '../../data/models/workout_models.dart' show ExerciseLibraryItem;
import '../../data/repositories/workout_log_repository.dart';
import '../../data/repositories/muscle_engagement_repository.dart';
import '../../data/services/workout_api_service.dart';
import '../../data/services/workout_api_service_adapter.dart';
import '../../data/services/achievement_service_adapter.dart';
import '../../core/exercise_media.dart';
import '../../../../features/smart_plan/data/models/smart_workout_plan.dart'
    show SmartWorkoutExercise;
import '../../data/models/fitbod_workout_model.dart';
import '../../data/repositories/exercise_repository.dart';
import 'workout_history_provider.dart';

enum SessionState { idle, active, resting, exerciseComplete, finished }

class WorkoutSessionProvider extends ChangeNotifier {
  // Use Cases
  final StartWorkoutSessionUseCase _startUseCase;
  final FinishWorkoutSessionUseCase _finishUseCase;

  // Legacy dependencies (to be refactored further)
  final WorkoutLogRepository _repository;

  bool _disposed = false;

  WorkoutSessionEntity? _session;
  SessionState _state = SessionState.idle;
  int _restSecondsRemaining = 0;
  int _defaultRestSeconds = 60;
  bool _keepScreenAwake = true;
  bool _restTimerEnabled = true;
  bool _useKg = true;

  Timer? _restTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _sessionSaveKey = 'active_workout_session_v1';

  WorkoutSessionProvider({
    WorkoutLogRepository? repository,
    WorkoutApiService? apiService,
  }) : _repository = repository ?? WorkoutLogRepository(),
       _startUseCase = StartWorkoutSessionUseCase(
         repository ?? WorkoutLogRepository(),
       ),
       _finishUseCase = FinishWorkoutSessionUseCase(
         repository ?? WorkoutLogRepository(),
         WorkoutApiServiceAdapter(apiService ?? WorkoutApiService()),
         AchievementServiceAdapter(),
         MuscleEngagementRepository(),
         ExerciseRepository(),
       );

  WorkoutSessionEntity? get session => _session;
  SessionState get state => _state;
  int get restSecondsRemaining => _restSecondsRemaining;
  int get defaultRestSeconds => _defaultRestSeconds;
  bool get keepScreenAwake => _keepScreenAwake;
  bool get restTimerEnabled => _restTimerEnabled;
  bool get useKg => _useKg;

  // Configuration
  void setRestTimerEnabled(bool value) {
    _restTimerEnabled = value;
    _notify();
  }

  void setKeepScreenAwake(bool value) {
    _keepScreenAwake = value;
    if (_state == SessionState.active || _state == SessionState.resting) {
      if (_keepScreenAwake) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    }
    _notify();
  }

  void setUseKg(bool value) {
    _useKg = value;
    _notify();
  }

  void setDefaultRestSeconds(int seconds) {
    _defaultRestSeconds = seconds.clamp(5, 600);
    _notify();
  }

  // Session Management
  Future<void> startSession(
    String name,
    String userId,
    List<WorkoutExercise> exercises,
  ) async {
    _session = await _startUseCase.execute(
      name: name,
      userId: userId,
      exercises: exercises,
    );
    _state = SessionState.active;

    if (_keepScreenAwake) {
      WakelockPlus.enable();
    }
    _saveToLocalStorage();
    _notify();
  }

  /// Starts a session from a SmartWorkoutDay's exercises.
  /// Converts [SmartWorkoutExercise] → [WorkoutExercise] domain entities.
  Future<void> startSessionFromSmartPlan(
    String dayName,
    String userId,
    List<SmartWorkoutExercise> smartExercises,
  ) async {
    final uuid = const Uuid();
    final workoutExercises = smartExercises.map((ex) {
      final parsedReps = RegExp(r'\d+').firstMatch(ex.reps)?.group(0) ?? '10';
      final initialSets = List<WorkoutSet>.generate(
        ex.sets,
        (i) => WorkoutSet(
          setNumber: i + 1,
          weightKg: 0.0,
          reps: int.tryParse(parsedReps) ?? 10,
          loggedAt: DateTime.now(),
          isCompleted: false,
        ),
      );

      return WorkoutExercise(
        id: uuid.v4(),
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        gifUrl: ex.gifUrl != null ? normalizeExerciseMediaUrl(ex.gifUrl!) : null,
        targetSets: ex.sets,
        targetReps: ex.reps,
        targetWeight: 0.0,
        met: 5.0,
        loggedSets: initialSets,
      );
    }).toList();

    await startSession(dayName, userId, workoutExercises);
  }

  Future<void> startFitbodWorkout(FitbodWorkout workout, String userId) async {
    final uuid = const Uuid();
    final repo = ExerciseRepository();
    
    final workoutExercises = <WorkoutExercise>[];
    for (final ex in workout.exercises) {
      final details = await repo.getExerciseById(ex.exerciseId);
      final parsedReps = RegExp(r'\d+').firstMatch(ex.reps)?.group(0) ?? '10';
      final initialSets = List<WorkoutSet>.generate(
        ex.sets,
        (i) => WorkoutSet(
          setNumber: i + 1,
          weightKg: ex.weight,
          reps: int.tryParse(parsedReps) ?? 10,
          loggedAt: DateTime.now(),
          isCompleted: false,
        ),
      );

      workoutExercises.add(WorkoutExercise(
        id: uuid.v4(),
        name: details?.name ?? 'Unknown Exercise',
        muscleGroup: details?.bodyPart ?? 'Other',
        gifUrl: details?.gifUrl,
        targetSets: ex.sets,
        targetReps: ex.reps,
        targetWeight: ex.weight,
        met: details?.met ?? 4.0,
        loggedSets: initialSets,
      ));
    }

    await startSession(workout.name, userId, workoutExercises);
  }

  void logSet(double weight, int reps) {
    if (_session == null) return;
    final exerciseIdx = _session!.currentExerciseIndex;
    final exercise = _session!.exercises[exerciseIdx];

    final newSet = WorkoutSet(
      setNumber: exercise.loggedSets.length + 1,
      weightKg: _useKg ? weight : weight * 0.45359237,
      reps: reps,
      loggedAt: DateTime.now(),
      isCompleted: true,
    );

    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises[exerciseIdx] = exercise.copyWith(
      loggedSets: [...exercise.loggedSets, newSet],
    );

    _session = _session!.copyWith(exercises: updatedExercises);

    HapticFeedback.mediumImpact();

    if (_restTimerEnabled) {
      _startRestTimer();
    } else {
      _checkExerciseCompletion();
    }

    _saveToLocalStorage();
    _notify();
  }

  void toggleSetCompleted(
    int exerciseIdx,
    int setIdx,
    double weight,
    int reps,
    bool completed,
  ) {
    if (_session == null || _session!.exercises.length <= exerciseIdx) return;
    final exercise = _session!.exercises[exerciseIdx];
    if (exercise.loggedSets.length <= setIdx) return;

    final updatedSets = List<WorkoutSet>.from(exercise.loggedSets);
    updatedSets[setIdx] = updatedSets[setIdx].copyWith(
      weightKg: _useKg ? weight : weight * 0.45359237,
      reps: reps,
      isCompleted: completed,
    );

    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises[exerciseIdx] = exercise.copyWith(loggedSets: updatedSets);
    _session = _session!.copyWith(exercises: updatedExercises);

    if (completed) {
      HapticFeedback.mediumImpact();
      if (_restTimerEnabled) {
        _startRestTimer();
      }
    } else {
      if (_state == SessionState.resting) {
        _restTimer?.cancel();
        _state = SessionState.active;
      }
    }

    _saveToLocalStorage();
    _notify();
  }

  void editSet(int exerciseIdx, int setIdx, double weight, int reps) {
    if (_session == null || _session!.exercises.length <= exerciseIdx) return;
    final exercise = _session!.exercises[exerciseIdx];
    if (exercise.loggedSets.length <= setIdx) return;

    final updatedSets = List<WorkoutSet>.from(exercise.loggedSets);
    updatedSets[setIdx] = updatedSets[setIdx].copyWith(
      weightKg: _useKg ? weight : weight * 0.45359237,
      reps: reps,
      isEdited: true,
    );

    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises[exerciseIdx] = exercise.copyWith(loggedSets: updatedSets);
    _session = _session!.copyWith(exercises: updatedExercises);

    _saveToLocalStorage();
    _notify();
  }

  void addEmptySet(int exerciseIdx) {
    if (_session == null || _session!.exercises.length <= exerciseIdx) return;
    final exercise = _session!.exercises[exerciseIdx];

    double lastWeight = 0.0;
    int lastReps = 10;
    if (exercise.loggedSets.isNotEmpty) {
      final lastSet = exercise.loggedSets.last;
      lastWeight = lastSet.weightKg;
      lastReps = lastSet.reps;
    } else if (exercise.targetWeight != null) {
      lastWeight = exercise.targetWeight!;
      final match = RegExp(r'\d+').firstMatch(exercise.targetReps);
      if (match != null) {
        lastReps = int.tryParse(match.group(0)!) ?? 10;
      }
    }

    final newSet = WorkoutSet(
      setNumber: exercise.loggedSets.length + 1,
      weightKg: lastWeight,
      reps: lastReps,
      loggedAt: DateTime.now(),
      isCompleted: false,
      isEdited: false,
    );

    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises[exerciseIdx] = exercise.copyWith(
      loggedSets: [...exercise.loggedSets, newSet],
    );
    _session = _session!.copyWith(exercises: updatedExercises);

    _saveToLocalStorage();
    _notify();
  }

  void deleteSet(int exerciseIdx, int setIdx) {
    if (_session == null || _session!.exercises.length <= exerciseIdx) return;
    final exercise = _session!.exercises[exerciseIdx];
    if (exercise.loggedSets.length <= setIdx) return;

    final updatedSets = List<WorkoutSet>.from(exercise.loggedSets);
    updatedSets.removeAt(setIdx);

    // Renumber
    for (int i = 0; i < updatedSets.length; i++) {
      updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
    }

    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises[exerciseIdx] = exercise.copyWith(loggedSets: updatedSets);
    _session = _session!.copyWith(exercises: updatedExercises);

    _saveToLocalStorage();
    _notify();
  }

  void updateSetType(int exerciseIdx, int setIdx, SetType newType) {
    if (_session == null || _session!.exercises.length <= exerciseIdx) return;
    final exercise = _session!.exercises[exerciseIdx];
    if (exercise.loggedSets.length <= setIdx) return;

    final updatedSets = List<WorkoutSet>.from(exercise.loggedSets);
    updatedSets[setIdx] = updatedSets[setIdx].copyWith(setType: newType);

    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises[exerciseIdx] = exercise.copyWith(loggedSets: updatedSets);
    _session = _session!.copyWith(exercises: updatedExercises);

    _saveToLocalStorage();
    _notify();
  }

  Future<void> addExerciseToSession(ExerciseLibraryItem item) async {
    if (_session == null) return;

    final lastSets = await _repository.getLastWorkoutSets(
      _session!.userId,
      item.name,
    );
    final initialSets = lastSets.isNotEmpty
        ? lastSets
              .map<WorkoutSet>(
                (s) => s.copyWith(loggedAt: DateTime.now(), isCompleted: false),
              )
              .toList()
        : List<WorkoutSet>.generate(
            3,
            (i) => WorkoutSet(
              setNumber: i + 1,
              weightKg: 0.0,
              reps: 10,
              loggedAt: DateTime.now(),
            ),
          );

    final exercise = WorkoutExercise(
      id: '${DateTime.now().millisecondsSinceEpoch}_${item.name}',
      name: item.name,
      muscleGroup: item.bodyPart,
      gifUrl: normalizeExerciseMediaUrl(item.gifUrl),
      targetSets: 3,
      targetReps: '10',
      targetWeight: 0.0,
      met: item.met ?? 3.5,
      loggedSets: initialSets,
    );

    _session = _session!.copyWith(
      exercises: [..._session!.exercises, exercise],
    );
    _saveToLocalStorage();
    _notify();
  }

  void removeExerciseFromSession(int exerciseIdx) {
    if (_session == null || _session!.exercises.length <= exerciseIdx) return;
    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises.removeAt(exerciseIdx);
    _session = _session!.copyWith(exercises: updatedExercises);
    _saveToLocalStorage();
    _notify();
  }

  void _startRestTimer() {
    _state = SessionState.resting;
    _restSecondsRemaining = _defaultRestSeconds;
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        _restSecondsRemaining--;
        _notify();
      } else {
        _endRest();
      }
    });
  }

  void skipRest() {
    _endRest();
  }

  void adjustRest(int deltaSeconds) {
    _restSecondsRemaining = (_restSecondsRemaining + deltaSeconds).clamp(
      5,
      600,
    );
    _notify();
  }

  void _endRest() {
    _restTimer?.cancel();
    _restSecondsRemaining = 0;
    _playBeepAndVibrate();
    _checkExerciseCompletion();
  }

  void _playBeepAndVibrate() {
    try {
      Vibration.hasVibrator().then((hasVib) {
        if (hasVib == true) {
          Vibration.vibrate(pattern: [0, 100, 50, 200]);
        }
      });
      _audioPlayer.play(AssetSource('audio/timer_end.mp3')).catchError((e) {
        debugPrint('[WorkoutSessionProvider] Play sound failed: $e');
      });
    } catch (e) {
      debugPrint('[WorkoutSessionProvider] Rest alerts failed: $e');
    }
  }

  void _checkExerciseCompletion() {
    if (_session == null) return;
    final exercise = _session!.exercises[_session!.currentExerciseIndex];
    if (exercise.loggedSets.length >= exercise.targetSets) {
      _state = SessionState.exerciseComplete;
    } else {
      _state = SessionState.active;
    }
    _notify();
  }

  void nextExercise() {
    if (_session == null) return;
    if (_session!.currentExerciseIndex < _session!.exercises.length - 1) {
      _session = _session!.copyWith(
        currentExerciseIndex: _session!.currentExerciseIndex + 1,
      );
      _state = SessionState.active;
    } else {
      _state = SessionState.finished;
    }
    _saveToLocalStorage();
    _notify();
  }

  void skipExercise() {
    if (_session == null) return;
    final idx = _session!.currentExerciseIndex;
    final updatedExercises = List<WorkoutExercise>.from(_session!.exercises);
    updatedExercises[idx] = updatedExercises[idx].copyWith(isSkipped: true);
    _session = _session!.copyWith(exercises: updatedExercises);
    nextExercise();
  }

  Future<WorkoutSessionEntity?> finishSession(
    String token,
    String? note,
    int? mood,
    WorkoutHistoryProvider? historyProvider,
  ) async {
    if (_session == null) return null;

    final finishedSession = await _finishUseCase.execute(
      session: _session!,
      token: token,
      note: note,
      mood: mood,
    );

    // Refresh history before clearing session so the app state is ready
    if (historyProvider != null && finishedSession != null) {
      await historyProvider.loadHistory(finishedSession.userId);
    }

    _session = null;
    _state = SessionState.idle;
    _clearLocalStorage();
    WakelockPlus.disable();
    _notify();

    return finishedSession;
  }

  void cancelWorkout() {
    WakelockPlus.disable();
    _restTimer?.cancel();
    _session = null;
    _state = SessionState.idle;
    _clearLocalStorage();
    _notify();
  }

  // Local Storage (Crash Recovery)
  Future<void> _saveToLocalStorage() async {
    if (_session == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionSaveKey, jsonEncode(_session!.toJson()));
    } catch (e) {
      debugPrint('[WorkoutSessionProvider] Save local storage failed: $e');
    }
  }

  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionSaveKey);
  }

  Future<void> initForUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionSaveKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final loadedSession = WorkoutSessionEntity.fromJson(decoded);
        if (loadedSession.userId == uid) {
          _session = loadedSession;
          _state = SessionState.active;
          if (_keepScreenAwake) {
            WakelockPlus.enable();
          }
          _notify();
        }
      }
    } catch (e) {
      debugPrint('[WorkoutSessionProvider] Restore session failed: $e');
    }
  }

  void resetForLogout() {
    cancelWorkout();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _restTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
