// lib/features/workout/data/models/workout_routine.dart

import 'package:flutter/foundation.dart';

/// Type-safe set categories, matching the Strong app convention.
/// Stored as a string in SQLite / JSON for forward compatibility.
enum SetType {
  normal,   // plain numbered set
  warmup,   // "W" — gold badge
  dropSet,  // "D" — purple badge
  failure,  // "F" — red badge
}

extension SetTypeLabel on SetType {
  String get label {
    switch (this) {
      case SetType.warmup:
        return 'W';
      case SetType.dropSet:
        return 'D';
      case SetType.failure:
        return 'F';
      case SetType.normal:
        return '';
    }
  }

  String toJson() => name;

  static SetType fromJson(String? value) {
    switch (value) {
      case 'warmup':
        return SetType.warmup;
      case 'dropSet':
        return SetType.dropSet;
      case 'failure':
        return SetType.failure;
      default:
        return SetType.normal;
    }
  }

  /// Cycles through the four states in Strong-app order.
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

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutRoutine — user-created named workout template
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutRoutine {
  final String id;
  String name;
  List<RoutineExercise> exercises;
  final DateTime createdAt;
  DateTime updatedAt;

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WorkoutRoutine.fromMap(
    Map<String, dynamic> map,
    List<RoutineExercise> exercises,
  ) {
    return WorkoutRoutine(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      exercises: exercises,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  /// Convenience subtitle: first 3 exercise names + "and N more".
  String get exerciseSubtitle {
    if (exercises.isEmpty) return 'No exercises';
    const max = 3;
    final shown = exercises.take(max).map((e) => e.exerciseName).join(', ');
    if (exercises.length <= max) return shown;
    return '$shown and ${exercises.length - max} more';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RoutineExercise — one exercise slot inside a WorkoutRoutine
// ─────────────────────────────────────────────────────────────────────────────

class RoutineExercise {
  final String id;
  final String routineId;
  final String exerciseId;
  String exerciseName;
  String? muscleGroup;
  String? gifUrl;
  int defaultSets;
  String defaultReps;
  double? defaultWeight;
  int sortOrder;

  RoutineExercise({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    this.gifUrl,
    this.defaultSets = 3,
    this.defaultReps = '8-12',
    this.defaultWeight,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'muscle_group': muscleGroup,
      'gif_url': gifUrl,
      'default_sets': defaultSets,
      'default_reps': defaultReps,
      'default_weight': defaultWeight,
      'sort_order': sortOrder,
    };
  }

  factory RoutineExercise.fromMap(Map<String, dynamic> map) {
    return RoutineExercise(
      id: map['id']?.toString() ?? '',
      routineId: map['routine_id']?.toString() ?? '',
      exerciseId: map['exercise_id']?.toString() ?? '',
      exerciseName: map['exercise_name']?.toString() ?? '',
      muscleGroup: map['muscle_group']?.toString(),
      gifUrl: map['gif_url']?.toString(),
      defaultSets: (map['default_sets'] as int?) ?? 3,
      defaultReps: map['default_reps']?.toString() ?? '8-12',
      defaultWeight: map['default_weight'] != null
          ? double.tryParse(map['default_weight'].toString())
          : null,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'gifUrl': gifUrl,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultWeight': defaultWeight,
      'sortOrder': sortOrder,
    };
  }

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      id: json['id']?.toString() ?? '',
      routineId: json['routineId']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? '',
      exerciseName: json['exerciseName']?.toString() ?? '',
      muscleGroup: json['muscleGroup']?.toString(),
      gifUrl: json['gifUrl']?.toString(),
      defaultSets: (json['defaultSets'] as int?) ?? 3,
      defaultReps: json['defaultReps']?.toString() ?? '8-12',
      defaultWeight: json['defaultWeight'] != null
          ? double.tryParse(json['defaultWeight'].toString())
          : null,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
    );
  }
}

// Make SetType visible from this file without extra imports in UI code
// ignore: unused_element
void _noop() => debugPrint('workout_routine.dart loaded');
