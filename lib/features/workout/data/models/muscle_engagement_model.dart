
class MuscleEngagementEntry {
  final int? id;
  final String userId;
  final int workoutLogId;
  final String muscleName;
  final double totalVolume;
  final int setCount;
  final int exerciseCount;
  final bool isPrimary;
  final double intensityScore;
  final DateTime trainedAt;

  const MuscleEngagementEntry({
    this.id,
    required this.userId,
    required this.workoutLogId,
    required this.muscleName,
    this.totalVolume = 0.0,
    this.setCount = 0,
    this.exerciseCount = 0,
    this.isPrimary = true,
    this.intensityScore = 0.0,
    required this.trainedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'workout_log_id': workoutLogId,
      'muscle_name': muscleName,
      'total_volume': totalVolume,
      'set_count': setCount,
      'exercise_count': exerciseCount,
      'is_primary': isPrimary ? 1 : 0,
      'intensity_score': intensityScore,
      'trained_at': trainedAt.toIso8601String(),
    };
  }

  factory MuscleEngagementEntry.fromMap(Map<String, dynamic> map) {
    return MuscleEngagementEntry(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      workoutLogId: map['workout_log_id'] as int,
      muscleName: map['muscle_name'] as String,
      totalVolume: (map['total_volume'] as num?)?.toDouble() ?? 0.0,
      setCount: map['set_count'] as int? ?? 0,
      exerciseCount: map['exercise_count'] as int? ?? 0,
      isPrimary: (map['is_primary'] as int? ?? 1) == 1,
      intensityScore: (map['intensity_score'] as num?)?.toDouble() ?? 0.0,
      trainedAt: DateTime.parse(map['trained_at'] as String),
    );
  }
}
