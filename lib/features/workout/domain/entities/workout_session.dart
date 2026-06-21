enum SetType {
  normal,
  warmup,
  dropSet,
  failure;

  String toJson() => name;

  static SetType fromJson(String? json) {
    return SetType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => SetType.normal,
    );
  }

  SetType get next {
    const order = [
      SetType.normal,
      SetType.warmup,
      SetType.dropSet,
      SetType.failure,
    ];
    final idx = order.indexOf(this);
    return order[(idx + 1) % order.length];
  }
}

class WorkoutExercise {
  final String id;
  final String name;
  final String? muscleGroup;
  final String? gifUrl;
  final int targetSets;
  final String targetReps;
  final double? targetWeight;
  final double? met;
  final List<WorkoutSet> loggedSets;
  final bool isSkipped;

  const WorkoutExercise({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.gifUrl,
    required this.targetSets,
    required this.targetReps,
    this.targetWeight,
    this.met,
    required this.loggedSets,
    this.isSkipped = false,
  });

  WorkoutExercise copyWith({
    List<WorkoutSet>? loggedSets,
    bool? isSkipped,
  }) {
    return WorkoutExercise(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      gifUrl: gifUrl,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      met: met,
      loggedSets: loggedSets ?? this.loggedSets,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'gifUrl': gifUrl,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'met': met,
      'loggedSets': loggedSets.map((e) => e.toJson()).toList(),
      'isSkipped': isSkipped,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      muscleGroup: json['muscleGroup']?.toString(),
      gifUrl: json['gifUrl']?.toString(),
      targetSets: json['targetSets'] as int? ?? 3,
      targetReps: json['targetReps']?.toString() ?? '10',
      targetWeight: json['targetWeight'] != null ? double.tryParse(json['targetWeight'].toString()) : null,
      met: json['met'] != null ? double.tryParse(json['met'].toString()) : 3.5,
      loggedSets: (json['loggedSets'] as List? ?? [])
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      isSkipped: json['isSkipped'] as bool? ?? false,
    );
  }
}

class WorkoutSet {
  final int setNumber;
  final double weightKg;
  final int reps;
  final DateTime loggedAt;
  final bool isEdited;
  final bool isCompleted;
  final SetType setType;

  const WorkoutSet({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.loggedAt,
    this.isEdited = false,
    this.isCompleted = false,
    this.setType = SetType.normal,
  });

  WorkoutSet copyWith({
    int? setNumber,
    double? weightKg,
    int? reps,
    DateTime? loggedAt,
    bool? isEdited,
    bool? isCompleted,
    SetType? setType,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      loggedAt: loggedAt ?? this.loggedAt,
      isEdited: isEdited ?? this.isEdited,
      isCompleted: isCompleted ?? this.isCompleted,
      setType: setType ?? this.setType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'weightKg': weightKg,
      'reps': reps,
      'loggedAt': loggedAt.toIso8601String(),
      'isEdited': isEdited,
      'isCompleted': isCompleted,
      'setType': setType.toJson(),
    };
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setNumber: json['setNumber'] as int? ?? 1,
      weightKg: double.tryParse(json['weightKg']?.toString() ?? '') ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      loggedAt: json['loggedAt'] != null ? DateTime.parse(json['loggedAt'].toString()) : DateTime.now(),
      isEdited: json['isEdited'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      setType: SetType.fromJson(json['setType']?.toString()),
    );
  }
}

class WorkoutSessionEntity {
  final String sessionId;
  final String userId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<WorkoutExercise> exercises;
  final int currentExerciseIndex;
  final String? sessionNote;
  final int? moodRating;

  const WorkoutSessionEntity({
    required this.sessionId,
    required this.userId,
    required this.workoutName,
    required this.startedAt,
    this.finishedAt,
    required this.exercises,
    this.currentExerciseIndex = 0,
    this.sessionNote,
    this.moodRating,
  });

  int get totalSets => exercises.expand((e) => e.loggedSets).where((s) => s.isCompleted).length;
  int get totalReps => exercises.expand((e) => e.loggedSets).where((s) => s.isCompleted).fold(0, (s, l) => s + l.reps);
  double get totalVolume => exercises.expand((e) => e.loggedSets).where((s) => s.isCompleted).fold(0, (s, l) => s + l.weightKg * l.reps);
  Duration get duration => (finishedAt ?? DateTime.now()).difference(startedAt);

  WorkoutSessionEntity copyWith({
    DateTime? finishedAt,
    List<WorkoutExercise>? exercises,
    int? currentExerciseIndex,
    String? sessionNote,
    int? moodRating,
  }) {
    return WorkoutSessionEntity(
      sessionId: sessionId,
      userId: userId,
      workoutName: workoutName,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      sessionNote: sessionNote ?? this.sessionNote,
      moodRating: moodRating ?? this.moodRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'workoutName': workoutName,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'currentExerciseIndex': currentExerciseIndex,
      'sessionNote': sessionNote,
      'moodRating': moodRating,
    };
  }

  factory WorkoutSessionEntity.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionEntity(
      sessionId: json['sessionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      workoutName: json['workoutName']?.toString() ?? '',
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'].toString()) : DateTime.now(),
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt'].toString()) : null,
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentExerciseIndex: json['currentExerciseIndex'] as int? ?? 0,
      sessionNote: json['sessionNote']?.toString(),
      moodRating: json['moodRating'] as int?,
    );
  }
}
