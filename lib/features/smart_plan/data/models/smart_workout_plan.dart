// lib/features/smart_plan/data/models/smart_workout_plan.dart

class SmartWorkoutExercise {
  final String name;
  final int sets;
  final String reps;
  final String? notes;
  final String? muscleGroup;
  final String? gifUrl;
  final String? exerciseId;
  final String? videoUrl;

  const SmartWorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
    this.muscleGroup,
    this.gifUrl,
    this.exerciseId,
    this.videoUrl,
  });

  factory SmartWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return SmartWorkoutExercise(
      name: json['name']?.toString() ?? '',
      sets: (json['sets'] is int)
          ? json['sets'] as int
          : int.tryParse(json['sets']?.toString() ?? '3') ?? 3,
      reps: json['reps']?.toString() ?? '10',
      notes: json['notes']?.toString(),
      muscleGroup: json['muscleGroup']?.toString(),
      gifUrl: json['gifUrl']?.toString(),
      exerciseId: json['exerciseId']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'notes': notes,
        'muscleGroup': muscleGroup,
        'gifUrl': gifUrl,
        'exerciseId': exerciseId,
        'videoUrl': videoUrl,
      };
}

class SmartWorkoutDay {
  final int dayIndex; // 1 = Monday … 7 = Sunday
  final String name;
  final bool isRestDay;
  final List<SmartWorkoutExercise> exercises;
  final String? imageUrl;

  const SmartWorkoutDay({
    required this.dayIndex,
    required this.name,
    required this.isRestDay,
    required this.exercises,
    this.imageUrl,
  });

  /// Short day abbreviation for cards (Mon, Tue, etc.)
  String get dayAbbr {
    const abbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final idx = dayIndex.clamp(1, 7) - 1;
    return abbrs[idx];
  }

  /// Primary muscle groups mentioned across exercises
  List<String> get primaryMuscles {
    final muscles = exercises
        .map((e) => e.muscleGroup)
        .whereType<String>()
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();
    return muscles.take(3).toList();
  }

  factory SmartWorkoutDay.fromJson(Map<String, dynamic> json) {
    final exercisesList = json['exercises'];
    final List<SmartWorkoutExercise> exercises = exercisesList is List
        ? exercisesList
            .whereType<Map<String, dynamic>>()
            .map((e) => SmartWorkoutExercise.fromJson(e))
            .toList()
        : [];

    return SmartWorkoutDay(
      dayIndex: (json['dayIndex'] is int)
          ? json['dayIndex'] as int
          : int.tryParse(json['dayIndex']?.toString() ?? '1') ?? 1,
      name: json['name']?.toString() ?? 'Day',
      isRestDay: json['isRestDay'] == true,
      exercises: exercises,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'name': name,
        'isRestDay': isRestDay,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'imageUrl': imageUrl,
      };
}
