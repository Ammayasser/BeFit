import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/services/workout_sync_service.dart';

class ExerciseLibraryProvider extends ChangeNotifier {
  final ExerciseRepository _repository;
  final WorkoutSyncService _syncService;
  bool _disposed = false;

  List<ExerciseLibraryItem> _exercises = [];
  int _totalInDatabase = 0;
  bool _isLoading = false;
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _searchQuery = '';
  String? _filterBodyPart;
  String? _filterEquipment;
  String? _filterDifficulty;
  String _sortBy = 'name';
  int _loadSequence = 0;

  ExerciseLibraryProvider({
    ExerciseRepository? repository,
    WorkoutSyncService? syncService,
  }) : _repository = repository ?? ExerciseRepository(),
       _syncService = syncService ?? WorkoutSyncService();

  List<ExerciseLibraryItem> get exercises => _exercises;
  int get totalExerciseCount =>
      _totalInDatabase > 0 ? _totalInDatabase : _exercises.length;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get searchQuery => _searchQuery;
  String? get filterBodyPart => _filterBodyPart;
  String? get filterEquipment => _filterEquipment;
  String? get filterDifficulty => _filterDifficulty;
  String get sortBy => _sortBy;

  Completer<void>? _initCompleter;

  Future<void> initialize() async {
    if (_disposed) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      // 1. Load what we already have first so the UI isn't empty
      await loadExercises();

      // 2. Check if we need to sync
      final synced = await _syncService.isSynced();
      if (!synced) {
        // Start sync in background - DO NOT 'await' it here
        _runBackgroundSync();
      }
    } finally {
      _initCompleter?.complete();
    }
  }

  Future<void> _runBackgroundSync() async {
    _isSyncing = true;
    _notify();

    await _syncService.performSync((progress) {
      _syncProgress = progress;
      _notify();
    });

    _isSyncing = false;
    await loadExercises(); // Refresh list with new data
    _notify();
  }

  Future<void> loadExercises() async {
    final currentSequence = ++_loadSequence;
    _isLoading = true;
    _notify();
    try {
      // Source of Truth is always the local database after sync.
      // This prevents the "Mixed Data" issue where filters go to API and "All" goes to DB.
      final results = await _repository.searchAndFilterExercises(
        query: _searchQuery,
        bodyPart: _filterBodyPart,
        equipment: _filterEquipment,
        difficulty: _filterDifficulty,
      );

      if (currentSequence != _loadSequence) return;

      // Apply sorting
      if (_sortBy == 'popularity') {
        results.sort((a, b) => (a.popularityRank ?? 9999).compareTo(b.popularityRank ?? 9999));
      } else if (_sortBy == 'efficacy') {
        results.sort((a, b) => (a.efficacyRank ?? 9999).compareTo(b.efficacyRank ?? 9999));
      } else {
        results.sort((a, b) => a.name.compareTo(b.name));
      }

      _exercises = results;
      _totalInDatabase = await _repository.getExercisesCount();
    } catch (e) {
      if (currentSequence == _loadSequence) {
        debugPrint('[ExerciseLibraryProvider] Load error: $e');
      }
    } finally {
      if (currentSequence == _loadSequence) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> applySortBy(String type) async {
    _sortBy = type;
    await loadExercises();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await loadExercises();
  }

  Future<void> applyFilter({
    String? bodyPart,
    String? equipment,
    String? difficulty,
  }) async {
    if (bodyPart != null) {
      _filterBodyPart = bodyPart == 'All' ? null : bodyPart;
    }
    if (equipment != null) {
      _filterEquipment = equipment == 'All' ? null : equipment;
    }
    if (difficulty != null) {
      _filterDifficulty = difficulty == 'All' ? null : difficulty;
    }
    await loadExercises();
  }

  Future<void> resetFilters() async {
    _searchQuery = '';
    _filterBodyPart = null;
    _filterEquipment = null;
    _filterDifficulty = null;
    await loadExercises();
  }

  Future<void> toggleSave(String exerciseId, String userId, String name) async {
    try {
      await _repository.toggleSaveExercise(userId, exerciseId, name);
      _notify();
    } catch (e) {
      debugPrint('[ExerciseLibraryProvider] toggleSave error: $e');
    }
  }

  Future<bool> isSaved(String exerciseId, String userId) async {
    try {
      return await _repository.isSaved(userId, exerciseId);
    } catch (e) {
      debugPrint('[ExerciseLibraryProvider] check isSaved error: $e');
      return false;
    }
  }

  Future<List<ExerciseLibraryItem>> getSaved(String userId) async {
    try {
      return await _repository.getSavedExercises(userId);
    } catch (e) {
      debugPrint('[ExerciseLibraryProvider] getSaved error: $e');
      return [];
    }
  }

  /// Suggests similar exercises locally using targeting similarity
  Future<List<ExerciseLibraryItem>> getSimilar(String exerciseId) async {
    try {
      final targetExercise = await _repository.getExerciseById(exerciseId);
      if (targetExercise == null) return [];

      // Query database for exercises targeting the same muscle
      final matches = await _repository.searchAndFilterExercises(
        bodyPart: targetExercise.bodyPart,
      );

      // Return matches excluding the current exercise itself
      return matches.where((e) => e.id != exerciseId).take(5).toList();
    } catch (e) {
      debugPrint('[ExerciseLibraryProvider] getSimilar error: $e');
      return [];
    }
  }

  // ignore: unused_element
  void _setLoading(bool val) {
    _isLoading = val;
    _notify();
  }

  Future<void> initForUser(String uid) async {
    await initialize();
  }

  void resetForLogout() {
    _exercises = [];
    _searchQuery = '';
    _filterBodyPart = null;
    _filterEquipment = null;
    _filterDifficulty = null;
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
