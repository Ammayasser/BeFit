// lib/features/workout/data/curated_workouts.dart

import 'package:flutter/material.dart';
import '../../smart_plan/data/models/smart_workout_plan.dart';

class CuratedWorkout {
  final String routeId;
  final String name;
  final String category;
  final String muscleGroup;
  final int durationMin;
  final String difficulty;
  final int estimatedKcal;
  final int exerciseCount;
  final List<SmartWorkoutExercise> exercises;
  final List<Color> gradient;
  final String? imageUrl;

  const CuratedWorkout({
    required this.routeId,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.durationMin,
    required this.difficulty,
    required this.estimatedKcal,
    required this.exerciseCount,
    required this.exercises,
    this.gradient = const [Color(0xFF1E293B), Color(0xFF0F172A)],
    this.imageUrl,
  });

  SmartWorkoutDay toSmartWorkoutDay() {
    return SmartWorkoutDay(
      dayIndex: 1,
      name: name,
      isRestDay: false,
      exercises: exercises,
      imageUrl: imageUrl,
    );
  }
}

class CuratedWorkoutCategory {
  final String title;
  final List<SmartWorkoutDay> workouts;

  const CuratedWorkoutCategory({
    required this.title,
    required this.workouts,
  });
}

const List<CuratedWorkoutCategory> curatedWorkoutSections = [
  CuratedWorkoutCategory(
    title: 'Recommended For You',
    workouts: [
      SmartWorkoutDay(
        dayIndex: 1,
        name: 'Full Body Power Blast',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Barbell Squat', sets: 4, reps: '8-10', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Barbell Bench Press', sets: 4, reps: '8-10', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Barbell Bent Over Row', sets: 4, reps: '8-10', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Barbell Standing Military Press', sets: 3, reps: '10-12', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'Plank', sets: 3, reps: '60s', muscleGroup: 'Core'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 2,
        name: 'Metabolic HIIT Burn',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Burpee', sets: 4, reps: '15', muscleGroup: 'Full Body'),
          SmartWorkoutExercise(name: 'Mountain Climber', sets: 4, reps: '30s', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Kettlebell Swing', sets: 4, reps: '20', muscleGroup: 'Glutes'),
          SmartWorkoutExercise(name: 'Jump Squat', sets: 4, reps: '12', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Push Up', sets: 4, reps: 'Failure', muscleGroup: 'Chest'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 3,
        name: 'Elite Upper Body Pumping',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Dumbbell Incline Bench Press', sets: 4, reps: '10-12', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Lat Pulldown', sets: 4, reps: '10-12', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Dumbbell Lateral Raise', sets: 3, reps: '15', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'Dumbbell Bicep Curl', sets: 3, reps: '12', muscleGroup: 'Arms'),
          SmartWorkoutExercise(name: 'Dumbbell Triceps Extension', sets: 3, reps: '12', muscleGroup: 'Arms'),
        ],
      ),
    ],
  ),
  CuratedWorkoutCategory(
    title: 'Strength & Power',
    workouts: [
      SmartWorkoutDay(
        dayIndex: 1,
        name: 'Deadlift Dominance',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Barbell Deadlift', sets: 5, reps: '5', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Barbell Romanian Deadlift', sets: 3, reps: '10', muscleGroup: 'Hamstrings'),
          SmartWorkoutExercise(name: 'Pull Up', sets: 3, reps: 'Max', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Barbell Shrug', sets: 3, reps: '12', muscleGroup: 'Traps'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 2,
        name: 'Chest Force One',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Barbell Bench Press', sets: 5, reps: '5', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Chest Dip', sets: 3, reps: '8-10', muscleGroup: 'Chest/Triceps'),
          SmartWorkoutExercise(name: 'Cable Fly', sets: 3, reps: '15', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Barbell Close Grip Bench Press', sets: 3, reps: '10', muscleGroup: 'Triceps'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 3,
        name: 'Leg Day Annihilation',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Barbell Full Squat', sets: 5, reps: '5', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Leg Press', sets: 3, reps: '12-15', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Lying Leg Curl', sets: 3, reps: '12', muscleGroup: 'Hamstrings'),
          SmartWorkoutExercise(name: 'Seated Calf Raise', sets: 4, reps: '15', muscleGroup: 'Calves'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 4,
        name: 'Shoulder Boulder Build',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Barbell Military Press', sets: 5, reps: '5', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'Dumbbell Arnold Press', sets: 3, reps: '10', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'Cable Face Pull', sets: 3, reps: '15', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'Dumbbell Front Raise', sets: 3, reps: '12', muscleGroup: 'Shoulders'),
        ],
      ),
    ],
  ),
  CuratedWorkoutCategory(
    title: 'Weight Loss & Tone',
    workouts: [
      SmartWorkoutDay(
        dayIndex: 1,
        name: 'Full Body Circuit A',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Dumbbell Goblet Squat', sets: 3, reps: '15', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Dumbbell Bench Press', sets: 3, reps: '15', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Dumbbell One Arm Row', sets: 3, reps: '15', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Box Jump', sets: 3, reps: '10', muscleGroup: 'Legs'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 2,
        name: 'Core & Cardio Shred',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Bicycle Crunch', sets: 3, reps: '20', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Lying Leg Raise', sets: 3, reps: '15', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Russian Twist', sets: 3, reps: '20', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Mountain Climber', sets: 3, reps: '45s', muscleGroup: 'Core'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 3,
        name: 'Upper Body Tone',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Push Up', sets: 3, reps: 'Max', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Lat Pulldown', sets: 3, reps: '15', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Dumbbell Overhead Press', sets: 3, reps: '15', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'Dumbbell Triceps Kickback', sets: 3, reps: '15', muscleGroup: 'Arms'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 4,
        name: 'Lower Body Sculpt',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Dumbbell Walking Lunge', sets: 3, reps: '20 total', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Glute Bridge', sets: 3, reps: '15', muscleGroup: 'Glutes'),
          SmartWorkoutExercise(name: 'Barbell Sumo Squat', sets: 3, reps: '15', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Dumbbell Step Up', sets: 3, reps: '12 per leg', muscleGroup: 'Legs'),
        ],
      ),
    ],
  ),
  CuratedWorkoutCategory(
    title: 'Beginner Series',
    workouts: [
      SmartWorkoutDay(
        dayIndex: 1,
        name: 'Intro to Strength',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Wall Push Up', sets: 3, reps: '10', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Bodyweight Squat', sets: 3, reps: '12', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Bird Dog', sets: 3, reps: '10', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Dead Bug', sets: 3, reps: '10', muscleGroup: 'Core'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 2,
        name: 'Dumbbell Basics',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Dumbbell Squat', sets: 3, reps: '10', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Dumbbell Chest Press', sets: 3, reps: '10', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Dumbbell Row', sets: 3, reps: '10', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Dumbbell Lateral Raise', sets: 3, reps: '10', muscleGroup: 'Shoulders'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 3,
        name: 'Machine Mastery',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Leg Press Machine', sets: 3, reps: '12', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Chest Press Machine', sets: 3, reps: '12', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Seated Row Machine', sets: 3, reps: '12', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Lat Pulldown Machine', sets: 3, reps: '12', muscleGroup: 'Back'),
        ],
      ),
    ],
  ),
  CuratedWorkoutCategory(
    title: 'Advanced Athletics',
    workouts: [
      SmartWorkoutDay(
        dayIndex: 1,
        name: 'Olympic Power',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Barbell Clean and Press', sets: 5, reps: '3', muscleGroup: 'Full Body'),
          SmartWorkoutExercise(name: 'Barbell Front Squat', sets: 4, reps: '6', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Barbell Snatch', sets: 4, reps: '5', muscleGroup: 'Full Body'),
          SmartWorkoutExercise(name: 'Box Jump', sets: 4, reps: '5', muscleGroup: 'Legs'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 2,
        name: 'Cali Mastery',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Muscle Up', sets: 3, reps: 'Failure', muscleGroup: 'Full Body'),
          SmartWorkoutExercise(name: 'Handstand Push Up', sets: 3, reps: '8', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'L-Sit', sets: 3, reps: '30s', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Plank', sets: 3, reps: '60s', muscleGroup: 'Core'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 3,
        name: 'Heavy Duty 2.0',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Barbell Incline Bench Press', sets: 3, reps: '6-8', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Weighted Pull Up', sets: 3, reps: '6-8', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Dumbbell Shoulder Press', sets: 3, reps: '6-8', muscleGroup: 'Shoulders'),
          SmartWorkoutExercise(name: 'Barbell Deadlift', sets: 2, reps: '5', muscleGroup: 'Back'),
        ],
      ),
    ],
  ),
  CuratedWorkoutCategory(
    title: 'Quick 20-Min Sessions',
    workouts: [
      SmartWorkoutDay(
        dayIndex: 1,
        name: 'Lunch Break Pump',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Dumbbell Goblet Squat', sets: 3, reps: '15', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Push Up', sets: 3, reps: 'Failure', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Dumbbell Row', sets: 3, reps: '15', muscleGroup: 'Back'),
          SmartWorkoutExercise(name: 'Plank', sets: 2, reps: '60s', muscleGroup: 'Core'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 2,
        name: 'Traveler Routine',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Bodyweight Squat', sets: 4, reps: '20', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Wall Sit', sets: 3, reps: '45s', muscleGroup: 'Legs'),
          SmartWorkoutExercise(name: 'Push Up', sets: 4, reps: '15', muscleGroup: 'Chest'),
          SmartWorkoutExercise(name: 'Mountain Climber', sets: 4, reps: '30s', muscleGroup: 'Core'),
        ],
      ),
      SmartWorkoutDay(
        dayIndex: 3,
        name: 'Express Core',
        isRestDay: false,
        exercises: [
          SmartWorkoutExercise(name: 'Bicycle Crunch', sets: 3, reps: '30s', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'V-Up', sets: 3, reps: '15', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Russian Twist', sets: 3, reps: '30s', muscleGroup: 'Core'),
          SmartWorkoutExercise(name: 'Hollow Body Hold', sets: 3, reps: '30s', muscleGroup: 'Core'),
        ],
      ),
    ],
  ),
];

// Helper to expose all workouts as CuratedWorkout for legacy screens
final List<CuratedWorkout> allCuratedWorkouts = curatedWorkoutSections.expand((section) {
  return section.workouts.map((day) {
    final duration = (day.exercises.length * 7).clamp(20, 90);
    final difficulty = day.exercises.length > 7 ? 'Advanced' : (day.exercises.length > 4 ? 'Intermediate' : 'Beginner');
    final muscleGroup = day.primaryMuscles.isNotEmpty ? day.primaryMuscles.first : 'Full Body';
    
    return CuratedWorkout(
      routeId: day.name.toLowerCase().replaceAll(' ', '-'),
      name: day.name,
      category: section.title.contains('Strength') ? 'Strength' : (section.title.contains('HIIT') ? 'HIIT' : 'Other'),
      muscleGroup: muscleGroup,
      durationMin: duration,
      difficulty: difficulty,
      estimatedKcal: duration * 7,
      exerciseCount: day.exercises.length,
      exercises: day.exercises,
      imageUrl: day.imageUrl,
    );
  });
}).toList();

CuratedWorkout? curatedWorkoutByRouteId(String id) {
  try {
    return allCuratedWorkouts.firstWhere((w) => w.routeId == id);
  } catch (_) {
    return null;
  }
}

final Map<String, List<Map<String, dynamic>>> curatedWorkoutExerciseSets = {
  for (var w in allCuratedWorkouts)
    w.name: w.exercises.map((e) => {
      'name': e.name,
      'muscleGroup': e.muscleGroup,
      'sets': e.sets,
      'reps': e.reps,
    }).toList(),
};
