import 'dart:convert';

class FitbodWorkout {
  final String id;
  final String name;
  final String difficulty;
  final String goal;
  final String category;
  final String gender;
  final List<String> imageUrls;
  final List<String> primaryMuscles;
  final List<FitbodWorkoutExercise> exercises;

  FitbodWorkout({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.goal,
    required this.category,
    required this.gender,
    required this.imageUrls,
    required this.primaryMuscles,
    required this.exercises,
  });

  factory FitbodWorkout.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    final rawExercises = json['exercises'] as List? ?? [];
    final parsedExercises = rawExercises
        .map((e) => FitbodWorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    String gender = json['gender']?.toString().toLowerCase() ?? 'unisex';
    if (gender == 'men') {
      gender = 'Male';
    } else if (gender == 'women') gender = 'Female';
    else if (gender == 'unisex' || gender == 'null') gender = 'Unisex';
    else gender = gender[0].toUpperCase() + gender.substring(1); // Capitalize others

    return FitbodWorkout(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'Intermediate',
      goal: json['goal']?.toString() ?? 'General Fitness',
      category: json['category']?.toString() ?? 'General',
      gender: gender,
      imageUrls: parseList(json['imageUrls'] ?? json['image_urls']),
      primaryMuscles: parseList(json['primaryMuscles'] ?? json['primary_muscles']),
      exercises: parsedExercises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'difficulty': difficulty,
      'goal': goal,
      'category': category,
      'gender': gender,
      'image_urls': jsonEncode(imageUrls),
      'primary_muscles': jsonEncode(primaryMuscles),
    };
  }

  String get exerciseSubtitle {
    if (exercises.isEmpty) return 'No exercises';
    const max = 3;
    final shown = exercises.take(max).map((e) => e.exerciseId).join(', '); // Note: in practice, we resolve this name in UI, but this is a stub
    if (exercises.length <= max) return shown;
    return '$shown and ${exercises.length - max} more';
  }
}

class FitbodWorkoutExercise {
  final String exerciseId;
  final int sets;
  final String reps;
  final double weight;
  final int restSeconds;
  final String equipment;

  FitbodWorkoutExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    this.equipment = '',
  });

  factory FitbodWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return FitbodWorkoutExercise(
      exerciseId: json['exerciseId']?.toString() ?? json['exercise_id']?.toString() ?? '',
      sets: json['sets'] is int ? json['sets'] as int : int.tryParse(json['sets'].toString()) ?? 3,
      reps: json['reps']?.toString() ?? '8-12',
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) ?? 0.0 : 0.0,
      restSeconds: json['restSeconds'] is int ? json['restSeconds'] as int : int.tryParse(json['restSeconds'].toString()) ?? 60,
      equipment: json['equipment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap(String workoutId) {
    return {
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_seconds': restSeconds,
      'equipment': equipment,
    };
  }
}
