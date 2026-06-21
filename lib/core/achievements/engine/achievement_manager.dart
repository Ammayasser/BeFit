// lib/core/achievements/engine/achievement_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_event.dart';
import '../models/achievement_models.dart';
import 'achievement_event_bus.dart';
import 'achievement_definitions.dart';

class AchievementManager extends ChangeNotifier {
  static final AchievementManager _instance = AchievementManager._internal();
  factory AchievementManager() => _instance;
  AchievementManager._internal();

  final Map<String, UserAchievementProgress> _progressMap = {};
  bool _isInitialized = false;
  String? _userId;
  StreamSubscription<AchievementEvent>? _eventSubscription;

  // Listeners
  void init(String userId) async {
    if (_isInitialized && _userId == userId) return;
    
    // Cleanup previous subscription if any
    await _eventSubscription?.cancel();
    
    _userId = userId;
    await _loadProgress();
    
    // Subscribe to the event bus
    _eventSubscription = AchievementEventBus().onEvent.listen(_handleEvent);
    
    _isInitialized = true;
    notifyListeners();
  }

  List<UserAchievementProgress> get allProgress => _progressMap.values.toList();
  
  List<Achievement> get unlockedAchievements {
    final unlockedIds = _progressMap.values
        .where((p) => p.isUnlocked)
        .map((p) => p.achievementId)
        .toSet();
    return AchievementDefinitions.all.where((a) => unlockedIds.contains(a.id)).toList();
  }

  void _handleEvent(AchievementEvent event) {
    if (event.userId != _userId) return;

    bool changed = false;
    for (final achievement in AchievementDefinitions.all) {
      final progress = _progressMap[achievement.id] ?? 
          UserAchievementProgress(achievementId: achievement.id, userId: event.userId);

      if (progress.isUnlocked) continue;

      Map<String, double> updatedValues = Map.from(progress.requirementValues);
      bool meetsAll = true;

      for (final req in achievement.requirements) {
        double currentReqValue = updatedValues[req.id] ?? 0.0;

        if (req.eventType == event.type) {
          // Check data filters (e.g., start_hour < 8)
          if (!_passesFilter(event, req)) {
            if (currentReqValue < req.targetValue) meetsAll = false;
            continue;
          }

          final incomingValue = _extractValue(event, req);
          
          switch (req.type) {
            case RequirementType.count:
              currentReqValue += 1;
              break;
            case RequirementType.sum:
              currentReqValue += incomingValue;
              break;
            case RequirementType.minValue:
              if (incomingValue > currentReqValue) currentReqValue = incomingValue;
              break;
            case RequirementType.streak:
            case RequirementType.boolean:
              currentReqValue = incomingValue;
              break;
          }
          updatedValues[req.id] = currentReqValue;
        }

        if (currentReqValue < req.targetValue) {
          meetsAll = false;
        }
      }

      if (_hasValuesChanged(progress.requirementValues, updatedValues) || (meetsAll && !progress.isUnlocked)) {
        final newProgress = progress.copyWith(
          requirementValues: updatedValues,
          isUnlocked: meetsAll,
          unlockedAt: meetsAll ? DateTime.now() : null,
        );
        _progressMap[achievement.id] = newProgress;
        changed = true;

        if (meetsAll) {
          _onAchievementUnlocked(achievement);
          // Broadcast cascading event to support "Milestone Crusher"
          AchievementEventBus().fire(AchievementEvent(
            type: AchievementEventType.achievementUnlocked,
            userId: event.userId,
            data: {'achievement_id': achievement.id},
          ));
        }
      }
    }

    if (changed) {
      _saveProgress();
      notifyListeners();
    }
  }

  bool _passesFilter(AchievementEvent event, AchievementRequirement req) {
    if (req.dataFilter == null || req.dataFilter!.isEmpty) return true;

    for (final entry in req.dataFilter!.entries) {
      final key = entry.key;
      final condition = entry.value.toString();
      final actualValue = event.data[key];

      if (actualValue == null) return false;

      if (condition.startsWith('<')) {
        final threshold = double.tryParse(condition.substring(1)) ?? 0;
        if ((actualValue as num).toDouble() >= threshold) return false;
      } else if (condition.startsWith('>')) {
        final threshold = double.tryParse(condition.substring(1)) ?? 0;
        if ((actualValue as num).toDouble() <= threshold) return false;
      } else {
        if (actualValue.toString() != condition) return false;
      }
    }
    return true;
  }

  bool _hasValuesChanged(Map<String, double> oldV, Map<String, double> newV) {
    if (oldV.length != newV.length) return true;
    for (final key in newV.keys) {
      if (oldV[key] != newV[key]) return true;
    }
    return false;
  }

  double _extractValue(AchievementEvent event, AchievementRequirement req) {
    if (req.dataKey == null) return 0;
    final val = event.data[req.dataKey];
    if (val is num) return val.toDouble();
    if (val is bool) return val ? 1.0 : 0.0;
    return 0;
  }

  Achievement? _lastUnlocked;
  Achievement? get lastUnlocked => _lastUnlocked;

  void clearLastUnlocked() {
    _lastUnlocked = null;
  }

  void _onAchievementUnlocked(Achievement achievement) {
    debugPrint('🏆 ACHIEVEMENT UNLOCKED: ${achievement.title}');
    _lastUnlocked = achievement;
    // We notify listeners so the main shell can show the toast
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'achievements_progress_$_userId';
    final jsonStr = prefs.getString(key);
    
    if (jsonStr != null) {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (final item in list) {
        final progress = UserAchievementProgress.fromJson(item);
        _progressMap[progress.achievementId] = progress;
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'achievements_progress_$_userId';
    final jsonStr = jsonEncode(_progressMap.values.map((e) => e.toJson()).toList());
    await prefs.setString(key, jsonStr);
  }
}
