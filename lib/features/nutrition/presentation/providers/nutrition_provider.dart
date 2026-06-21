import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/food_item.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/daily_nutrition.dart';
import '../../data/local/nutrition_local_database.dart';
import '../../data/services/open_food_facts_service.dart';
import '../../../../core/achievements/engine/achievement_event_bus.dart';

import '../../domain/usecases/get_daily_nutrition_usecase.dart';
import '../../domain/usecases/log_meal_usecase.dart';
import '../../domain/usecases/log_water_usecase.dart';

import '../../domain/mappers/nutrition_mapper.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../domain/entities/calorie_history_item.dart';

class NutritionProvider extends ChangeNotifier {
  final OpenFoodFactsService _apiService = OpenFoodFactsService();
  final Uuid _uuid = const Uuid();
  final NutritionLocalDatabase _local = NutritionLocalDatabase.instance;

  // Use Cases
  late final GetDailyNutritionUseCase _getDailyUseCase;
  late final LogMealUseCase _logMealUseCase;
  late final LogWaterUseCase _logWaterUseCase;

  // ── State ──────────────────────────────────────────────────
  String? _userId;
  DateTime _selectedDate = DateTime.now();
  DailyNutrition _dailyNutrition = DailyNutrition(
    date: DateTime.now(),
    logs: [],
  );

  // Search
  List<FoodItem> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounceTimer;
  int _searchSessionId = 0;

  // Recently added (for "+X kcal" indicator)
  double? _lastAddedCalories;

  /// Totals (ml) Mon–Sun for the week that contains [selectedDate].
  List<int> _weekWaterTotalsMl = List<int>.filled(7, 0);

  List<MealLog> _recentMeals = [];

  // Loading
  bool _isLoading = false;
  bool _isInitialized = false;

  NutritionProvider() {
    final repository = NutritionRepository(local: _local);
    _getDailyUseCase = GetDailyNutritionUseCase(repository);
    _logMealUseCase = LogMealUseCase(repository);
    _logWaterUseCase = LogWaterUseCase(repository);
  }

  // ── Getters ────────────────────────────────────────────────
  DateTime get selectedDate => _selectedDate;
  DailyNutrition get dailyNutrition => _dailyNutrition;
  List<FoodItem> get searchResults => _searchResults;
  List<String> get recentSearches => _recentSearches;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  double? get lastAddedCalories => _lastAddedCalories;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<MealLog> get recentMeals => List.unmodifiable(_recentMeals);

  /// Milliliters per day (Mon = index 0 … Sun = index 6) for hydration weekly chart.
  List<int> get weekWaterTotalsMl => List<int>.unmodifiable(_weekWaterTotalsMl);

  // ── Analytics / History ────────────────────────────────────
  List<CalorieHistoryItem> _calorieHistory = [];
  bool _isHistoryLoading = false;

  List<CalorieHistoryItem> get calorieHistory => _calorieHistory;
  bool get isHistoryLoading => _isHistoryLoading;

  double get averageCaloriesInHistory {
    if (_calorieHistory.isEmpty) return 0;
    final sum = _calorieHistory.fold(0.0, (a, b) => a + b.caloriesEaten);
    return sum / _calorieHistory.length;
  }

  double get goalAdherenceRate {
    final trackedDays = _calorieHistory.where((i) => i.caloriesEaten > 0).toList();
    if (trackedDays.isEmpty) return 0;
    final metCount = trackedDays.where((i) => i.isGoalMet).length;
    return (metCount / trackedDays.length) * 100;
  }

  Future<void> loadHistoryReport(String period) async {
    if (_userId == null) return;
    _isHistoryLoading = true;
    notifyListeners();

    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day);

    switch (period.toLowerCase()) {
      case 'week':
        start = end.subtract(const Duration(days: 6));
        break;
      case 'month':
        start = end.subtract(const Duration(days: 29));
        break;
      case 'year':
        start = end.subtract(const Duration(days: 364));
        break;
      default:
        start = end.subtract(const Duration(days: 6));
    }

    try {
      final repository = NutritionRepository(local: _local);
      _calorieHistory = await repository.getCalorieHistory(_userId!, start, end);
    } catch (e) {
      debugPrint('NutritionProvider: History load error: $e');
      _calorieHistory = [];
    }

    _isHistoryLoading = false;
    notifyListeners();
  }

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get formattedDate {
    return DateFormat('EEE, MMM d').format(_selectedDate);
  }

  // ── Date Navigation ────────────────────────────────────────
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _loadDailyNutrition();
    notifyListeners();
  }

  /// Called by SmartPlanProvider after meal plan is generated to set the
  /// recommended calories as the user's daily calorie goal.
  void setSmartCalorieGoal(double calories) {
    if (calories <= 0) return;
    _dailyNutrition = _dailyNutrition.copyWith(calorieGoal: calories.toInt());
    if (_userId != null) {
      _local.updateDailyGoals(
        _userId!,
        _selectedDate,
        calorieGoal: calories.toInt(),
      );
    }
    notifyListeners();
  }

  void goToPreviousDay() {
    selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void goToNextDay() {
    final tomorrow = _selectedDate.add(const Duration(days: 1));
    final now = DateTime.now();
    if (tomorrow.isBefore(now) || _isSameDay(tomorrow, now)) {
      selectDate(tomorrow);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Food Search ────────────────────────────────────────────
  void searchFoods(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.length < 2) {
      _searchResults = [];
      _isSearching = false;
      _searchError = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    final sessionId = ++_searchSessionId;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (sessionId != _searchSessionId) return;

      try {
        final results = await _apiService.searchByName(trimmed);

        if (sessionId == _searchSessionId) {
          _searchResults = results;
          _searchError = null;
          if (results.isNotEmpty) {
            _saveRecentSearch(trimmed);
          }
        }
      } catch (e) {
        if (sessionId == _searchSessionId) {
          _searchError = 'Failed to search. Check your connection.';
          _searchResults = [];
        }
      } finally {
        if (sessionId == _searchSessionId) {
          _isSearching = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _loadRecentSearches() async {
    if (_userId == null) return;
    try {
      _recentSearches = await _local.loadRecentSearches(_userId!, limit: 2);
      notifyListeners();
    } catch (e) {
      debugPrint('NutritionProvider: recent searches load error: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (_userId == null) return;
    try {
      await _local.saveRecentSearch(_userId!, query);
      await _loadRecentSearches();
    } catch (e) {
      debugPrint('NutritionProvider: save recent search error: $e');
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchSessionId++;
    _searchResults = [];
    _isSearching = false;
    _searchError = null;
    notifyListeners();
  }

  void removeRecentSearch(String query) async {
    // Note: Actually need a delete method in local DB if we want this
    // For now just local memory filter or implement in DB
  }

  // ── Barcode Scan ───────────────────────────────────────────
  Future<FoodItem?> lookupBarcode(String barcode) async {
    try {
      return await _apiService.getByBarcode(barcode);
    } catch (e) {
      return null;
    }
  }

  // ── Add / Remove Food Log ──────────────────────────────────
  Future<void> addFoodLog(
    MealType mealType,
    FoodItem food,
    double grams,
  ) async {
    final log = MealLog.create(
      id: _uuid.v4(),
      mealType: mealType,
      foodItem: food,
      quantityGrams: grams,
    );

    _lastAddedCalories = log.loggedCalories;

    final updatedLogs = List<MealLog>.from(_dailyNutrition.logs)..add(log);
    _dailyNutrition = _dailyNutrition.copyWith(logs: updatedLogs);

    // Update UI immediately
    notifyListeners();

    if (_userId != null) {
      final logEntity = NutritionMapper.toEntityMeal(
        log,
        _userId!,
        _selectedDate,
      );
      // Save in background to avoid blocking UI notification
      _logMealUseCase.execute(logEntity).then((_) {
         // Optionally refresh recent meals after save
         _loadRecentMeals();
      }).catchError((e) {
         debugPrint('NutritionProvider: Failed to save meal log: $e');
      });
    }

    // 🏆 Broadcast achievement event
    if (_userId != null) {
      AchievementEventBus().fireMeal(_userId!, {
        'meal_type': mealType.name,
        'calories': log.loggedCalories,
        'protein': log.loggedProtein,
        'carbs': log.loggedCarbs,
        'fat': log.loggedFat,
        'food_name': food.name,
      });
    }

    // Clear the "just added" indicator after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      _lastAddedCalories = null;
      notifyListeners();
    });
  }

  void deleteFoodLog(String logId) async {
    final updatedLogs = _dailyNutrition.logs
        .where((l) => l.id != logId)
        .toList();
    _dailyNutrition = _dailyNutrition.copyWith(logs: updatedLogs);

    if (_userId != null) {
      await _local.deleteMealLog(logId);
    }

    notifyListeners();
  }

  // Undo delete: re-add a log
  void undoDelete(MealLog log) async {
    final updatedLogs = List<MealLog>.from(_dailyNutrition.logs)..add(log);
    // Sort by loggedAt to maintain order
    updatedLogs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    _dailyNutrition = _dailyNutrition.copyWith(logs: updatedLogs);

    if (_userId != null) {
      final logEntity = NutritionMapper.toEntityMeal(
        log,
        _userId!,
        _selectedDate,
      );
      await _logMealUseCase.execute(logEntity);
    }

    notifyListeners();
  }

  // ── Water Tracking ─────────────────────────────────────────
  int _hourForWaterEntry() {
    final now = DateTime.now();
    final sel = _selectedDate;
    if (sel.year == now.year && sel.month == now.month && sel.day == now.day) {
      return now.hour;
    }
    return 12;
  }

  Future<void> addWater(int ml) async {
    if (ml <= 0) return;
    final newAmount = (_dailyNutrition.waterLoggedMl + ml).clamp(0, 10000);
    final hour = _hourForWaterEntry().clamp(0, 23);
    final hourly = _dailyNutrition.hourlyWaterMl;
    hourly[hour] = (hourly[hour] + ml).clamp(0, 10000);

    if (_userId != null) {
      await _logWaterUseCase.execute(
        userId: _userId!,
        date: _selectedDate,
        amountMl: ml,
        totalMl: _dailyNutrition.waterLoggedMl,
        hourly: _dailyNutrition.hourlyWaterMl,
      );
    }

    _dailyNutrition = _dailyNutrition.copyWith(
      waterLoggedMl: newAmount,
      waterMlPerHour: hourly,
    );
    _refreshWeekWaterTotalsInMemory();
    notifyListeners();

    // 🏆 Broadcast achievement event
    if (_userId != null) {
      AchievementEventBus().fireWater(_userId!, {
        'amount_ml': ml,
        'daily_total': newAmount,
      });
    }
  }

  Future<void> removeWater(int ml) async {
    if (ml <= 0) return;
    final oldTotal = _dailyNutrition.waterLoggedMl;
    final newAmount = (oldTotal - ml).clamp(0, 10000);
    if (oldTotal <= 0) return;
    final hourly = _dailyNutrition.hourlyWaterMl;
    final sumH = hourly.fold<int>(0, (a, b) => a + b);
    List<int> newHourly;
    if (sumH == 0) {
      newHourly = hourly;
    } else {
      final factor = newAmount / oldTotal;
      newHourly = hourly.map((e) => (e * factor).round()).toList();
      var drift = newAmount - newHourly.fold<int>(0, (a, b) => a + b);
      if (drift != 0) {
        var idx = 0;
        for (var i = 1; i < 24; i++) {
          if (newHourly[i] > newHourly[idx]) idx = i;
        }
        newHourly[idx] = (newHourly[idx] + drift).clamp(0, 10000);
      }
    }
    _dailyNutrition = _dailyNutrition.copyWith(
      waterLoggedMl: newAmount,
      waterMlPerHour: newHourly,
    );

    if (_userId != null) {
      await _local.saveDay(_userId!, _selectedDate, _dailyNutrition);
    }

    _refreshWeekWaterTotalsInMemory();
    notifyListeners();
  }

  /// Loads [weekWaterTotalsMl] from SQLite for the week containing [selectedDate].
  Future<void> loadWeekWaterTotals() async {
    if (_userId == null) return;
    try {
      _weekWaterTotalsMl = await _local.loadWeekWaterTotals(
        _userId!,
        _selectedDate,
      );
    } catch (e) {
      debugPrint('NutritionProvider: week water load: $e');
    }
    notifyListeners();
  }

  void _refreshWeekWaterTotalsInMemory() {
    if (_weekWaterTotalsMl.length != 7) {
      _weekWaterTotalsMl = List<int>.filled(7, 0);
    } else {
      _weekWaterTotalsMl = List<int>.from(_weekWaterTotalsMl);
    }
    final start = _startOfWeekMonday(_selectedDate);
    for (var i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      if (_isSameDay(d, _selectedDate)) {
        _weekWaterTotalsMl[i] = _dailyNutrition.waterLoggedMl;
        return;
      }
    }
  }

  DateTime _startOfWeekMonday(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _migrateWaterHourlyIfNeeded() {
    final hourly = _dailyNutrition.hourlyWaterMl;
    final sum = hourly.fold<int>(0, (a, b) => a + b);
    final total = _dailyNutrition.waterLoggedMl;
    if (total > 0 && sum == 0) {
      final migrated = List<int>.filled(24, 0);
      migrated[12] = total;
      _dailyNutrition = _dailyNutrition.copyWith(waterMlPerHour: migrated);
    }
  }

  // ── Auto-select Meal Type Based on Time of Day ─────────────
  MealType get suggestedMealType {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) return MealType.breakfast;
    if (hour >= 10 && hour < 15) return MealType.lunch;
    if (hour >= 15 && hour < 19) return MealType.dinner;
    return MealType.snacks;
  }

  // ── Persistence (SQLite, per user) ─────────────────────────
  Future<void> _loadDailyNutrition() async {
    if (_userId == null) return;
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final entity = await _getDailyUseCase.execute(_userId!, _selectedDate);
      _dailyNutrition = NutritionMapper.toModelDaily(entity);
      _migrateWaterHourlyIfNeeded();
      _isInitialized = true;
    } catch (e) {
      debugPrint('NutritionProvider: Error loading: $e');
      _dailyNutrition = DailyNutrition(date: _selectedDate, logs: []);
      _isInitialized = true;
    }

    _isLoading = false;
    notifyListeners();
    unawaited(loadWeekWaterTotals());
  }

  /// Call once when provider is first created to load today's data
  Future<void> initForUser(String userId) async {
    _userId = userId;
    OpenFoodFactsService.initialize();
    await _local.importLegacySharedPreferencesForUser(userId);
    await _loadDailyNutrition();
    await _loadRecentSearches();
    await _loadRecentMeals();
  }

  Future<void> refresh() async {
    await _loadDailyNutrition();
    await _loadRecentSearches();
    await _loadRecentMeals();
  }

  Future<void> _loadRecentMeals() async {
    if (_userId == null) return;
    try {
      _recentMeals = await _local.loadRecentMeals(_userId!, limit: 10);
    } catch (e) {
      debugPrint('NutritionProvider: recent meals load error: $e');
    }
    notifyListeners();
  }

  Future<void> resetForLogout() async {
    _userId = null;
    _dailyNutrition = DailyNutrition(date: DateTime.now(), logs: []);
    _selectedDate = DateTime.now();
    _searchResults = [];
    _recentSearches = [];
    _isLoading = false;
    _weekWaterTotalsMl = List<int>.filled(7, 0);
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
