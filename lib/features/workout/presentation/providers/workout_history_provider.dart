import 'package:flutter/foundation.dart';
import '../../data/models/workout_history_entry.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_log_repository.dart';

import '../../data/mappers/workout_mapper.dart';

class WorkoutHistoryProvider extends ChangeNotifier {
  final WorkoutLogRepository _repository;
  bool _disposed = false;

  List<WorkoutHistoryEntry> _history = [];
  Map<String, double> _personalRecords = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  WorkoutHistoryProvider({WorkoutLogRepository? repository})
      : _repository = repository ?? WorkoutLogRepository();

  List<WorkoutHistoryEntry> get history => _history;
  Map<String, double> get personalRecords => _personalRecords;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> loadHistory(String userId) async {
    _setLoading(true);
    try {
      _history = await _repository.getWorkoutHistory(userId);
      _personalRecords = await _repository.getPersonalRecords(userId);
      _isInitialized = true;
      _notify();
    } catch (e) {
      debugPrint('[WorkoutHistoryProvider] loadHistory error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkAndTriggerPr(String userId, String exerciseName, double weightKg) async {
    try {
      final isPr = await _repository.isPersonalRecord(userId, exerciseName, weightKg);
      if (isPr) {
        // Reload PRs
        _personalRecords = await _repository.getPersonalRecords(userId);
        _notify();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[WorkoutHistoryProvider] checkAndTriggerPr error: $e');
      return false;
    }
  }

  Future<List<LoggedSet>> getExerciseHistory(String exerciseName, String userId) async {
    try {
      final entities = await _repository.getExerciseHistory(userId, exerciseName);
      return entities.map(WorkoutMapper.toModelSet).toList().cast<LoggedSet>();
    } catch (e) {
      debugPrint('[WorkoutHistoryProvider] getExerciseHistory error: $e');
      return [];
    }
  }

  Future<void> deleteHistoryEntry(int logId, String userId) async {
    try {
      await _repository.deleteWorkoutLog(logId);
      await loadHistory(userId);
    } catch (e) {
      debugPrint('[WorkoutHistoryProvider] deleteHistoryEntry error: $e');
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _notify();
  }

  Future<void> initForUser(String uid) async {
    await loadHistory(uid);
  }

  void resetForLogout() {
    _history = [];
    _personalRecords = {};
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
