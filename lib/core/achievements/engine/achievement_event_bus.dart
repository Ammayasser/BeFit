// lib/core/achievements/engine/achievement_event_bus.dart

import 'dart:async';
import '../models/achievement_event.dart';

/// A professional event bus for broadcasting user actions that might trigger achievements.
/// Using the Singleton pattern for global access without tight coupling.
class AchievementEventBus {
  static final AchievementEventBus _instance = AchievementEventBus._internal();
  factory AchievementEventBus() => _instance;
  AchievementEventBus._internal();

  final _eventController = StreamController<AchievementEvent>.broadcast();

  /// Stream of all achievement-related events.
  Stream<AchievementEvent> get onEvent => _eventController.stream;

  /// Publishes a new event to the bus.
  void fire(AchievementEvent event) {
    _eventController.add(event);
  }

  /// Helper to fire a workout event.
  void fireWorkout(String userId, Map<String, dynamic> data) {
    fire(AchievementEvent(
      type: AchievementEventType.workoutCompleted,
      userId: userId,
      data: data,
    ));
  }

  /// Helper to fire a nutrition event.
  void fireMeal(String userId, Map<String, dynamic> data) {
    fire(AchievementEvent(
      type: AchievementEventType.mealLogged,
      userId: userId,
      data: data,
    ));
  }

  /// Helper to fire a water event.
  void fireWater(String userId, Map<String, dynamic> data) {
    fire(AchievementEvent(
      type: AchievementEventType.waterLogged,
      userId: userId,
      data: data,
    ));
  }

  void dispose() {
    _eventController.close();
  }
}
