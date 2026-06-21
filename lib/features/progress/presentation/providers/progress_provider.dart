// lib/features/progress/presentation/providers/progress_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/weight_log.dart';
import '../../data/models/progress_photo.dart';
import '../../data/repositories/weight_log_repository.dart';
import '../../data/repositories/progress_photo_repository.dart';
import '../../../../core/achievements/engine/achievement_event_bus.dart';
import '../../../../core/achievements/models/achievement_event.dart';

enum WeightTimeRange { week, month, threeMonths, sixMonths, year, all }

class ProgressProvider extends ChangeNotifier {
  final WeightLogRepository _repository = WeightLogRepository();
  final ProgressPhotoRepository _photoRepository = ProgressPhotoRepository();

  bool _disposed = false;
  String? _userId;

  List<WeightLog> _allLogs = [];
  List<WeightLog> _recentLogs = [];
  WeightLog? _latestLog;
  double? _startWeight;
  double? _goalWeight;
  WeightTimeRange _selectedRange = WeightTimeRange.threeMonths;
  List<WeightLog> _filteredLogs = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String _weightUnit = 'kg';

  List<ProgressPhoto> _allPhotos = [];

  // Getters
  List<WeightLog> get allLogs => _allLogs;
  List<WeightLog> get recentLogs => _recentLogs;
  WeightLog? get latestLog => _latestLog;
  double? get startWeight => _startWeight;
  double? get goalWeight => _goalWeight;
  WeightTimeRange get selectedRange => _selectedRange;
  List<WeightLog> get filteredLogs => _filteredLogs;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String get weightUnit => _weightUnit;
  List<ProgressPhoto> get allPhotos => _allPhotos;

  // Convert kg to preferred unit
  double toDisplayWeight(double weightInKg) {
    if (_weightUnit == 'lbs') {
      return weightInKg * 2.20462;
    }
    return weightInKg;
  }

  // Convert preferred unit to kg for storage
  double toStoredWeight(double weightInPreferredUnit) {
    if (_weightUnit == 'lbs') {
      return weightInPreferredUnit / 2.20462;
    }
    return weightInPreferredUnit;
  }

  double? get currentWeight =>
      _latestLog != null ? toDisplayWeight(_latestLog!.weightKg) : null;

  double? get weightChange {
    if (currentWeight == null || _startWeight == null) return null;
    return currentWeight! - toDisplayWeight(_startWeight!);
  }

  double? get weeklyChange {
    if (_allLogs.isEmpty) return null;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final pastLog = _findClosestLog(sevenDaysAgo);
    if (pastLog == null || currentWeight == null) return null;
    return currentWeight! - toDisplayWeight(pastLog.weightKg);
  }

  double? get monthlyChange {
    if (_allLogs.isEmpty) return null;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final pastLog = _findClosestLog(thirtyDaysAgo);
    if (pastLog == null || currentWeight == null) return null;
    return currentWeight! - toDisplayWeight(pastLog.weightKg);
  }

  double? calculateBmi(double heightCm) {
    if (_latestLog == null || heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    return _latestLog!.weightKg / (heightM * heightM);
  }

  String getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  double? get averageWeeklyWeight {
    if (_allLogs.isEmpty) return null;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final last7Logs = _allLogs
        .where((l) => l.loggedAt.isAfter(sevenDaysAgo))
        .toList();
    if (last7Logs.isEmpty) return null;
    final sum = last7Logs.fold(0.0, (sum, l) => sum + l.weightKg);
    return toDisplayWeight(sum / last7Logs.length);
  }

  List<FlSpot> get weightChartSpots {
    if (_filteredLogs.isEmpty) return [];
    final firstDate = _filteredLogs.first.loggedAt;
    return _filteredLogs.map((log) {
      final days = log.loggedAt.difference(firstDate).inDays.toDouble();
      return FlSpot(days, toDisplayWeight(log.weightKg));
    }).toList();
  }

  Map<String, double> get bodyMeasurementChange {
    if (_allLogs.isEmpty) return {};
    final first = _allLogs.last; // oldest log is last in DESC order
    final latest = _allLogs.first; // newest log is first

    double? change(double? l, double? f) {
      if (l == null || f == null) return null;
      return l - f;
    }

    return {
      'waist': change(latest.waistCm, first.waistCm) ?? 0.0,
      'chest': change(latest.chestCm, first.chestCm) ?? 0.0,
      'hips': change(latest.hipsCm, first.hipsCm) ?? 0.0,
      'neck': change(latest.neckCm, first.neckCm) ?? 0.0,
    };
  }

  WeightLog? _findClosestLog(DateTime date) {
    if (_allLogs.isEmpty) return null;
    WeightLog? closest;
    double minDiff = double.maxFinite;
    for (final log in _allLogs) {
      final diff = log.loggedAt
          .difference(date)
          .inMilliseconds
          .abs()
          .toDouble();
      if (diff < minDiff) {
        minDiff = diff;
        closest = log;
      }
    }
    return closest;
  }

  Future<void> initForUser(String userId, {double? userGoalWeight}) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    _weightUnit = prefs.getString('user_weight_unit') ?? 'kg';

    final savedGoal = prefs.getDouble('user_goal_weight_$_userId');
    if (savedGoal != null) {
      _goalWeight = savedGoal;
    } else {
      _goalWeight = userGoalWeight;
    }

    await refreshState();
  }

  Future<void> updateGoalWeight(double goalWeightInPreferredUnit) async {
    if (_userId == null) return;
    final goalInKg = toStoredWeight(goalWeightInPreferredUnit);
    _goalWeight = goalInKg;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_goal_weight_$_userId', goalInKg);
    _notify();
  }

  void resetForLogout() {
    _userId = null;
    _allLogs = [];
    _recentLogs = [];
    _latestLog = null;
    _startWeight = null;
    _goalWeight = null;
    _filteredLogs = [];
    _allPhotos = [];
    _isLoading = false;
    _error = null;
    _notify();
  }

  Future<void> setWeightUnit(String unit) async {
    if (_weightUnit != unit) {
      _weightUnit = unit;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_weight_unit', unit);
      _filterLogs();
      _notify();
    }
  }

  Future<void> refreshState() async {
    if (_userId == null) return;
    _isLoading = true;
    _error = null;
    _notify();

    try {
      _allLogs = await _repository.getAllLogs(_userId!);
      _allPhotos = await _photoRepository.getPhotosForUser(_userId!);

      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));
      _recentLogs = _allLogs
          .where((l) => l.loggedAt.isAfter(ninetyDaysAgo))
          .toList();

      _latestLog = await _repository.getLatestLog(_userId!);
      final firstLog = await _repository.getFirstLog(_userId!);
      _startWeight = firstLog?.weightKg;
      _isInitialized = true;

      _filterLogs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void _filterLogs() {
    if (_allLogs.isEmpty) {
      _filteredLogs = [];
      return;
    }
    final now = DateTime.now();
    DateTime threshold;
    switch (_selectedRange) {
      case WeightTimeRange.week:
        threshold = now.subtract(const Duration(days: 7));
        break;
      case WeightTimeRange.month:
        threshold = now.subtract(const Duration(days: 30));
        break;
      case WeightTimeRange.threeMonths:
        threshold = now.subtract(const Duration(days: 90));
        break;
      case WeightTimeRange.sixMonths:
        threshold = now.subtract(const Duration(days: 180));
        break;
      case WeightTimeRange.year:
        threshold = now.subtract(const Duration(days: 365));
        break;
      case WeightTimeRange.all:
        threshold = DateTime(2000);
        break;
    }

    // Filter and sort ASC for chart
    _filteredLogs = _allLogs
        .where((l) => l.loggedAt.isAfter(threshold))
        .toList()
        .reversed
        .toList();
  }

  void setTimeRange(WeightTimeRange range) {
    if (_selectedRange != range) {
      _selectedRange = range;
      _filterLogs();
      _notify();
    }
  }

  Future<void> addWeightLog(WeightLog log, {required double userHeight}) async {
    if (_userId == null) return;
    await _repository.insertLog(log);
    await refreshState();

    _checkAchievements(log, userHeight);
  }

  Future<void> updateWeightLog(WeightLog log) async {
    if (_userId == null) return;
    await _repository.updateLog(log);
    await refreshState();
  }

  Future<void> deleteWeightLog(String id) async {
    if (_userId == null) return;
    await _repository.deleteLog(id);
    await refreshState();
  }

  // Progress Photo Actions
  Future<void> addProgressPhoto(
    File tempFile,
    String category,
    DateTime date,
    String? notes, {
    String? weightLogId,
  }) async {
    if (_userId == null) return;

    final id = const Uuid().v4();
    final fileName = '$id.jpg';

    // Copy file permanently to documents directory
    final docDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docDir.path}/progress_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final destination = '${photosDir.path}/$fileName';
    await tempFile.copy(destination);

    final photo = ProgressPhoto(
      id: id,
      userId: _userId!,
      photoPath: fileName,
      category: category,
      loggedAt: date,
      notes: notes,
      weightLogId: weightLogId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _photoRepository.insertPhoto(photo);
    await refreshState();
  }

  Future<void> deleteProgressPhoto(ProgressPhoto photo) async {
    if (_userId == null) return;

    await _photoRepository.deletePhoto(photo.id);

    // Try deleting the physical file
    try {
      final absolutePath = await photo.resolveAbsolutePath();
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('ProgressProvider: Error deleting photo file: $e');
    }

    await refreshState();
  }

  void _checkAchievements(WeightLog log, double userHeight) {
    if (_userId == null) return;

    final isFirst = _allLogs.length == 1;
    final isGoalReached =
        _goalWeight != null &&
        ((log.weightKg - _goalWeight!).abs() < 0.2 ||
            (_startWeight != null &&
                _startWeight! > _goalWeight! &&
                log.weightKg <= _goalWeight!) ||
            (_startWeight != null &&
                _startWeight! < _goalWeight! &&
                log.weightKg >= _goalWeight!));

    double kgLost = 0.0;
    if (_startWeight != null) {
      kgLost = _startWeight! - log.weightKg;
    }

    int streak = _calculateLoggingStreak();

    // Fire weightLogged event
    AchievementEventBus().fire(
      AchievementEvent(
        type: AchievementEventType.weightLogged,
        userId: _userId!,
        data: {
          'is_first': isFirst,
          'goal_reached': isGoalReached,
          'kg_lost': kgLost,
          'streak_count': streak,
        },
      ),
    );

    // Support cascading achievement triggers if needed
    if (isFirst) {
      AchievementEventBus().fire(
        AchievementEvent(
          type: AchievementEventType.achievementUnlocked,
          userId: _userId!,
          data: {'achievement_id': 'first_weight_logged'},
        ),
      );
    }
    if (isGoalReached) {
      AchievementEventBus().fire(
        AchievementEvent(
          type: AchievementEventType.achievementUnlocked,
          userId: _userId!,
          data: {'achievement_id': 'weight_goal_reached'},
        ),
      );
    }
  }

  int _calculateLoggingStreak() {
    if (_allLogs.isEmpty) return 0;
    int streak = 1;
    DateTime currentDay = DateTime(
      _allLogs.first.loggedAt.year,
      _allLogs.first.loggedAt.month,
      _allLogs.first.loggedAt.day,
    );
    for (int i = 1; i < _allLogs.length; i++) {
      final logDay = DateTime(
        _allLogs[i].loggedAt.year,
        _allLogs[i].loggedAt.month,
        _allLogs[i].loggedAt.day,
      );
      final diff = currentDay.difference(logDay).inDays;
      if (diff == 1) {
        streak++;
        currentDay = logDay;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  Future<void> syncFromHealthApp() async {
    // Optional Health Sync placeholder. Can pull weight entries from HealthKit/Google Fit
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
