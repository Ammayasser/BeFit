class WorkoutHistoryEntry {
  final int? id;
  final String userId;
  final String date; // YYYY-MM-DD
  final int? dayIndex;
  final String? focus;
  final int durationSeconds;
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final String? completedAt; // Iso8601 string

  WorkoutHistoryEntry({
    this.id,
    required this.userId,
    required this.date,
    this.dayIndex,
    this.focus,
    required this.durationSeconds,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    this.completedAt,
  });

  factory WorkoutHistoryEntry.fromMap(Map<String, dynamic> map) {
    return WorkoutHistoryEntry(
      id: map['id'] as int?,
      userId: map['user_id']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      dayIndex: map['day_index'] as int?,
      focus: map['focus']?.toString(),
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      totalSets: map['total_sets'] as int? ?? 0,
      totalReps: map['total_reps'] as int? ?? 0,
      totalVolume: double.tryParse(map['total_volume']?.toString() ?? '0') ?? 0.0,
      completedAt: map['completed_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date,
      'day_index': dayIndex,
      'focus': focus,
      'duration_seconds': durationSeconds,
      'total_sets': totalSets,
      'total_reps': totalReps,
      'total_volume': totalVolume,
      'completed_at': completedAt,
    };
  }
}
