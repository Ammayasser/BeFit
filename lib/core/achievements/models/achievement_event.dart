// lib/core/achievements/models/achievement_event.dart

enum AchievementEventType {
  workoutCompleted,
  mealLogged,
  waterLogged,
  weightLogged,
  streakUpdated,
  profileUpdated,
  achievementUnlocked, // For cascading achievements
}

class AchievementEvent {
  final AchievementEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String userId;

  AchievementEvent({
    required this.type,
    required this.data,
    required this.userId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AchievementEvent(type: $type, userId: $userId, data: $data)';
}
