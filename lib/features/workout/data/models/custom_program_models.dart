// reuse RoutineExercise
import 'workout_models.dart'; // for SessionExercise
import '../../domain/entities/workout_session.dart';

class ProgramDayExercise {
  final String id;
  final String programDayId;
  final String exerciseId;
  final String exerciseName;
  final String? muscleGroup;
  final String? gifUrl;
  final int sets;
  final String reps;        // "8-12", "10", "AMRAP"
  final double? weightKg;
  final int restSeconds;    // default 90
  final String? notes;
  final int sortOrder;

  ProgramDayExercise({
    required this.id,
    required this.programDayId,
    required this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    this.gifUrl,
    this.sets = 3,
    this.reps = '8-12',
    this.weightKg,
    this.restSeconds = 90,
    this.notes,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'program_day_id': programDayId,
    'exercise_id': exerciseId,
    'exercise_name': exerciseName,
    'muscle_group': muscleGroup,
    'gif_url': gifUrl,
    'sets': sets,
    'reps': reps,
    'weight_kg': weightKg,
    'rest_seconds': restSeconds,
    'notes': notes,
    'sort_order': sortOrder,
  };

  factory ProgramDayExercise.fromMap(Map<String, dynamic> m) =>
    ProgramDayExercise(
      id: m['id'] as String,
      programDayId: m['program_day_id'] as String,
      exerciseId: m['exercise_id'] as String,
      exerciseName: m['exercise_name'] as String,
      muscleGroup: m['muscle_group'] as String?,
      gifUrl: m['gif_url'] as String?,
      sets: m['sets'] as int? ?? 3,
      reps: m['reps'] as String? ?? '8-12',
      weightKg: m['weight_kg'] != null ? (m['weight_kg'] as num).toDouble() : null,
      restSeconds: m['rest_seconds'] as int? ?? 90,
      notes: m['notes'] as String?,
      sortOrder: m['sort_order'] as int? ?? 0,
    );

  ProgramDayExercise copyWith({
    String? id,
    String? programDayId,
    String? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    String? gifUrl,
    int? sets,
    String? reps,
    double? weightKg,
    int? restSeconds,
    String? notes,
    int? sortOrder,
  }) {
    return ProgramDayExercise(
      id: id ?? this.id,
      programDayId: programDayId ?? this.programDayId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      gifUrl: gifUrl ?? this.gifUrl,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Convert to SessionExercise for launching ActiveSessionScreen
  SessionExercise toSessionExercise() => SessionExercise(
    id: exerciseId,
    name: exerciseName,
    muscleGroup: muscleGroup,
    gifUrl: gifUrl,
    targetSets: sets,
    targetReps: reps,
    targetWeight: weightKg,
    loggedSets: [],
  );

  /// Convert to WorkoutExercise domain entity
  WorkoutExercise toWorkoutExercise() {
    final parsedReps = RegExp(r'\d+').firstMatch(reps)?.group(0) ?? '10';
    return WorkoutExercise(
      id: exerciseId,
      name: exerciseName,
      muscleGroup: muscleGroup,
      gifUrl: gifUrl,
      targetSets: sets,
      targetReps: reps,
      targetWeight: weightKg,
      met: 4.0,
      loggedSets: List.generate(
        sets,
        (i) => WorkoutSet(
          setNumber: i + 1,
          weightKg: weightKg ?? 0.0,
          reps: int.tryParse(parsedReps) ?? 10,
          loggedAt: DateTime.now(),
          isCompleted: false,
        ),
      ),
    );
  }
}

class ProgramDay {
  final String id;
  final String programWeekId;
  final String programId;
  final int dayNumber;        // 1–7 position in the week
  final String name;          // "Push Day", "Monday", "Chest & Triceps", etc.
  final bool isRestDay;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<ProgramDayExercise> exercises;

  ProgramDay({
    required this.id,
    required this.programWeekId,
    required this.programId,
    required this.dayNumber,
    required this.name,
    this.isRestDay = false,
    this.isCompleted = false,
    this.completedAt,
    this.exercises = const [],
  });

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets);
  int get estimatedMinutes => isRestDay ? 0 : (exercises.length * 7 + totalSets * 1).clamp(15, 120);

  List<String> get primaryMuscles => exercises
      .map((e) => e.muscleGroup)
      .whereType<String>()
      .toSet()
      .take(3)
      .toList();

  Map<String, dynamic> toMap() => {
    'id': id,
    'program_week_id': programWeekId,
    'program_id': programId,
    'day_number': dayNumber,
    'name': name,
    'is_rest_day': isRestDay ? 1 : 0,
    'is_completed': isCompleted ? 1 : 0,
    'completed_at': completedAt?.toIso8601String(),
  };

  factory ProgramDay.fromMap(Map<String, dynamic> m, {List<ProgramDayExercise> exercises = const []}) =>
    ProgramDay(
      id: m['id'] as String,
      programWeekId: m['program_week_id'] as String,
      programId: m['program_id'] as String,
      dayNumber: m['day_number'] as int,
      name: m['name'] as String,
      isRestDay: (m['is_rest_day'] as int? ?? 0) == 1,
      isCompleted: (m['is_completed'] as int? ?? 0) == 1,
      completedAt: m['completed_at'] != null ? DateTime.tryParse(m['completed_at'] as String) : null,
      exercises: exercises,
    );

  ProgramDay copyWith({
    String? id,
    String? programWeekId,
    String? programId,
    int? dayNumber,
    String? name,
    bool? isRestDay,
    bool? isCompleted,
    DateTime? completedAt,
    List<ProgramDayExercise>? exercises,
  }) {
    return ProgramDay(
      id: id ?? this.id,
      programWeekId: programWeekId ?? this.programWeekId,
      programId: programId ?? this.programId,
      dayNumber: dayNumber ?? this.dayNumber,
      name: name ?? this.name,
      isRestDay: isRestDay ?? this.isRestDay,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      exercises: exercises ?? this.exercises,
    );
  }
}

class ProgramWeek {
  final String id;
  final String programId;
  final int weekNumber;
  final String? label;    // optional override label e.g. "Deload Week"
  final List<ProgramDay> days;

  ProgramWeek({
    required this.id,
    required this.programId,
    required this.weekNumber,
    this.label,
    this.days = const [],
  });

  String get displayName => label?.isNotEmpty == true ? label! : 'Week $weekNumber';

  int get completedDays => days.where((d) => d.isCompleted && !d.isRestDay).length;
  int get totalTrainingDays => days.where((d) => !d.isRestDay).length;
  bool get isCompleted => totalTrainingDays > 0 && completedDays >= totalTrainingDays;

  Map<String, dynamic> toMap() => {
    'id': id,
    'program_id': programId,
    'week_number': weekNumber,
    'label': label,
  };

  factory ProgramWeek.fromMap(Map<String, dynamic> m, {List<ProgramDay> days = const []}) =>
    ProgramWeek(
      id: m['id'] as String,
      programId: m['program_id'] as String,
      weekNumber: m['week_number'] as int,
      label: m['label'] as String?,
      days: days,
    );
}

class CustomProgram {
  final String id;
  final String userId;
  final String name;
  final String? emoji;      // e.g. "💪"
  final int totalWeeks;
  final int daysPerWeek;    // 1–7 (used to scaffold days)
  final bool isActive;
  final bool isCompleted;
  final int currentWeekIndex;   // 0-based
  final int currentDayIndex;    // 0-based within week
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final List<ProgramWeek> weeks;  // loaded on demand

  CustomProgram({
    required this.id,
    required this.userId,
    required this.name,
    this.emoji,
    this.totalWeeks = 4,
    this.daysPerWeek = 4,
    this.isActive = false,
    this.isCompleted = false,
    this.currentWeekIndex = 0,
    this.currentDayIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.weeks = const [],
  });

  double get progressFraction {
    final total = totalWeeks * daysPerWeek;
    if (total == 0) return 0;
    final done = (currentWeekIndex * daysPerWeek) + currentDayIndex;
    return (done / total).clamp(0.0, 1.0);
  }

  String get progressLabel => '${(progressFraction * 100).toInt()}%';
  String get durationLabel => '$totalWeeks Weeks';

  ProgramDay? get currentDay {
    if (weeks.isEmpty) return null;
    final week = weeks[currentWeekIndex.clamp(0, weeks.length - 1)];
    final trainingDays = week.days.where((d) => !d.isRestDay).toList();
    if (trainingDays.isEmpty) return null;
    return trainingDays[currentDayIndex.clamp(0, trainingDays.length - 1)];
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'emoji': emoji,
    'total_weeks': totalWeeks,
    'days_per_week': daysPerWeek,
    'is_active': isActive ? 1 : 0,
    'is_completed': isCompleted ? 1 : 0,
    'current_week_index': currentWeekIndex,
    'current_day_index': currentDayIndex,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
  };

  factory CustomProgram.fromMap(Map<String, dynamic> m, {List<ProgramWeek> weeks = const []}) =>
    CustomProgram(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      name: m['name'] as String,
      emoji: m['emoji'] as String?,
      totalWeeks: m['total_weeks'] as int? ?? 4,
      daysPerWeek: m['days_per_week'] as int? ?? 4,
      isActive: (m['is_active'] as int? ?? 0) == 1,
      isCompleted: (m['is_completed'] as int? ?? 0) == 1,
      currentWeekIndex: m['current_week_index'] as int? ?? 0,
      currentDayIndex: m['current_day_index'] as int? ?? 0,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
      startedAt: m['started_at'] != null ? DateTime.tryParse(m['started_at'] as String) : null,
      weeks: weeks,
    );

  CustomProgram copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    int? totalWeeks,
    int? daysPerWeek,
    bool? isActive,
    bool? isCompleted,
    int? currentWeekIndex,
    int? currentDayIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    List<ProgramWeek>? weeks,
  }) {
    return CustomProgram(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      currentWeekIndex: currentWeekIndex ?? this.currentWeekIndex,
      currentDayIndex: currentDayIndex ?? this.currentDayIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      weeks: weeks ?? this.weeks,
    );
  }
}
