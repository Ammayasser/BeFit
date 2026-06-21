// lib/core/achievements/models/achievement_models.dart

import 'achievement_event.dart';

enum AchievementCategory {
  fitness,
  nutrition,
  consistency,
  social,
  milestone,
}

enum RequirementType {
  count,        // e.g., 10 workouts
  sum,          // e.g., 5000 kcal burned
  streak,       // e.g., 7 days in a row
  boolean,      // e.g., linked instagram
  minValue,     // e.g., lift 100kg once
}

class AchievementRequirement {
  final String id;
  final AchievementEventType eventType;
  final RequirementType type;
  final double targetValue;
  final String? dataKey; // Which key in event.data to look at (e.g., 'calories')
  final Map<String, dynamic>? dataFilter; // e.g., {'start_hour': '<8'}
  final Map<String, dynamic>? metadata;

  const AchievementRequirement({
    required this.id,
    required this.eventType,
    required this.type,
    required this.targetValue,
    this.dataKey,
    this.dataFilter,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventType': eventType.name,
    'type': type.name,
    'targetValue': targetValue,
    'dataKey': dataKey,
    'dataFilter': dataFilter,
    'metadata': metadata,
  };
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final List<AchievementRequirement> requirements;
  final int points;
  final bool isHidden;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.requirements,
    this.points = 10,
    this.isHidden = false,
  });
}

class UserAchievementProgress {
  final String achievementId;
  final String userId;
  final Map<String, double> requirementValues; // Multi-requirement tracking
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime lastUpdatedAt;

  UserAchievementProgress({
    required this.achievementId,
    required this.userId,
    this.requirementValues = const {},
    this.isUnlocked = false,
    this.unlockedAt,
    DateTime? lastUpdatedAt,
  }) : lastUpdatedAt = lastUpdatedAt ?? DateTime.now();

  UserAchievementProgress copyWith({
    Map<String, double>? requirementValues,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return UserAchievementProgress(
      achievementId: achievementId,
      userId: userId,
      requirementValues: requirementValues ?? this.requirementValues,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      lastUpdatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'achievementId': achievementId,
    'userId': userId,
    'requirementValues': requirementValues,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
  };

  factory UserAchievementProgress.fromJson(Map<String, dynamic> json) => UserAchievementProgress(
    achievementId: json['achievementId'],
    userId: json['userId'],
    requirementValues: (json['requirementValues'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ) ?? {},
    isUnlocked: json['isUnlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    lastUpdatedAt: DateTime.parse(json['lastUpdatedAt']),
  );
}
