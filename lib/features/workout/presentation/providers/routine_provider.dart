// lib/features/workout/presentation/providers/routine_provider.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/workout_routine.dart';
import '../../data/repositories/routine_repository.dart';

class RoutineProvider extends ChangeNotifier {
  final RoutineRepository _repository;
  final _uuid = const Uuid();
  bool _disposed = false;

  List<WorkoutRoutine> _routines = [];
  bool _isLoading = false;

  RoutineProvider({RoutineRepository? repository})
      : _repository = repository ?? RoutineRepository();

  List<WorkoutRoutine> get routines => _routines;
  bool get isLoading => _isLoading;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  Future<void> loadRoutines() async {
    _setLoading(true);
    try {
      _routines = await _repository.getAllRoutines();
      _notify();
    } catch (e) {
      debugPrint('[RoutineProvider] loadRoutines error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<WorkoutRoutine> createRoutine(String name) async {
    final now = DateTime.now();
    final routine = WorkoutRoutine(
      id: _uuid.v4(),
      name: name.isEmpty ? 'New Routine' : name,
      exercises: [],
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveRoutine(routine);
    await loadRoutines();
    return routine;
  }

  Future<void> saveRoutine(WorkoutRoutine routine) async {
    routine.updatedAt = DateTime.now();
    await _repository.saveRoutine(routine);
    await loadRoutines();
  }

  Future<void> saveRoutines(List<WorkoutRoutine> routines) async {
    for (var routine in routines) {
      routine.updatedAt = DateTime.now();
      await _repository.saveRoutine(routine);
    }
    await loadRoutines();
  }

  Future<void> updateRoutineName(String routineId, String newName) async {
    final routine = _routines.firstWhere(
      (r) => r.id == routineId,
      orElse: () => throw StateError('Routine $routineId not found'),
    );
    routine.name = newName;
    routine.updatedAt = DateTime.now();
    await _repository.saveRoutine(routine);
    await loadRoutines();
  }

  Future<void> deleteRoutine(String routineId) async {
    await _repository.deleteRoutine(routineId);
    _routines.removeWhere((r) => r.id == routineId);
    _notify();
  }

  Future<void> duplicateRoutine(String routineId) async {
    final original = _routines.firstWhere(
      (r) => r.id == routineId,
      orElse: () => throw StateError('Routine $routineId not found'),
    );

    final now = DateTime.now();
    final newId = _uuid.v4();
    final duplicate = WorkoutRoutine(
      id: newId,
      name: '${original.name} (Copy)',
      exercises: original.exercises
          .map((e) => RoutineExercise(
                id: _uuid.v4(),
                routineId: newId,
                exerciseId: e.exerciseId,
                exerciseName: e.exerciseName,
                muscleGroup: e.muscleGroup,
                gifUrl: e.gifUrl,
                defaultSets: e.defaultSets,
                defaultReps: e.defaultReps,
                defaultWeight: e.defaultWeight,
                sortOrder: e.sortOrder,
              ))
          .toList(),
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveRoutine(duplicate);
    await loadRoutines();
  }

  // ── Exercise management ─────────────────────────────────────────────────────

  Future<void> addExercise(String routineId, RoutineExercise exercise) async {
    await _repository.addExerciseToRoutine(routineId, exercise);
    await loadRoutines();
  }

  Future<void> removeExercise(
      String routineId, String exerciseRowId) async {
    await _repository.removeExerciseFromRoutine(routineId, exerciseRowId);
    await loadRoutines();
  }

  Future<void> reorderExercises(
      String routineId, List<String> orderedIds) async {
    await _repository.reorderExercises(routineId, orderedIds);
    // Update local state immediately without full reload
    final routine = _routines.firstWhere((r) => r.id == routineId);
    final exerciseMap = {for (var e in routine.exercises) e.id: e};
    routine.exercises = orderedIds
        .map((id) => exerciseMap[id])
        .whereType<RoutineExercise>()
        .toList();
    _notify();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _setLoading(bool val) {
    _isLoading = val;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
