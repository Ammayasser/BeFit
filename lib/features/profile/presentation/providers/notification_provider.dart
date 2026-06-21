// lib/features/profile/presentation/providers/notification_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _prefWorkoutReminders = 'notifications_workout_reminders';
  static const String _prefMealReminders = 'notifications_meal_reminders';
  static const String _prefAchievementAlerts = 'notifications_achievement_alerts';
  static const String _prefAppUpdates = 'notifications_app_updates';
  static const String _prefMarketing = 'notifications_marketing';

  bool _workoutReminders = true;
  bool _mealReminders = true;
  bool _achievementAlerts = true;
  bool _appUpdates = false;
  bool _marketing = false;
  bool _isInitialized = false;

  bool get workoutReminders => _workoutReminders;
  bool get mealReminders => _mealReminders;
  bool get achievementAlerts => _achievementAlerts;
  bool get appUpdates => _appUpdates;
  bool get marketing => _marketing;
  bool get isInitialized => _isInitialized;

  NotificationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _workoutReminders = prefs.getBool(_prefWorkoutReminders) ?? true;
      _mealReminders = prefs.getBool(_prefMealReminders) ?? true;
      _achievementAlerts = prefs.getBool(_prefAchievementAlerts) ?? true;
      _appUpdates = prefs.getBool(_prefAppUpdates) ?? false;
      _marketing = prefs.getBool(_prefMarketing) ?? false;
    } catch (e) {
      debugPrint('NotificationProvider: Load settings error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setWorkoutReminders(bool value) async {
    _workoutReminders = value;
    notifyListeners();
    await _saveBool(_prefWorkoutReminders, value);
    _handleScheduling();
  }

  Future<void> setMealReminders(bool value) async {
    _mealReminders = value;
    notifyListeners();
    await _saveBool(_prefMealReminders, value);
    _handleScheduling();
  }

  Future<void> setAchievementAlerts(bool value) async {
    _achievementAlerts = value;
    notifyListeners();
    await _saveBool(_prefAchievementAlerts, value);
  }

  Future<void> setAppUpdates(bool value) async {
    _appUpdates = value;
    notifyListeners();
    await _saveBool(_prefAppUpdates, value);
  }

  Future<void> setMarketing(bool value) async {
    _marketing = value;
    notifyListeners();
    await _saveBool(_prefMarketing, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _handleScheduling() {
    // This is where we would call flutter_local_notifications to schedule/cancel
    // For now, we log the intent to make it "functionally aware"
    if (_workoutReminders) {
      debugPrint('NotificationService: Scheduling daily workout reminders...');
    } else {
      debugPrint('NotificationService: Cancelling workout reminders...');
    }

    if (_mealReminders) {
      debugPrint('NotificationService: Scheduling daily meal log nudges...');
    } else {
      debugPrint('NotificationService: Cancelling meal log nudges...');
    }
  }
}
