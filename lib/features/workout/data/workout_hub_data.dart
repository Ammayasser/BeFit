import 'package:flutter/material.dart';
import 'curated_workouts.dart';

class WorkoutCoach {
  final String name;
  final double rating;
  final String specialty;
  final Color avatarColor;

  const WorkoutCoach({
    required this.name,
    required this.rating,
    required this.specialty,
    required this.avatarColor,
  });
}

class WorkoutProgram {
  final String id;
  final String title;
  final String duration;
  final String difficulty;
  final String goal;
  final int workoutsPerWeek;
  final int totalWeeks;
  final double progress;
  final List<Color> gradient;

  const WorkoutProgram({
    required this.id,
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.goal,
    required this.workoutsPerWeek,
    required this.totalWeeks,
    this.progress = 0,
    required this.gradient,
  });
}

class WorkoutChallenge {
  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final double target;
  final bool isMonthly;

  const WorkoutChallenge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.target,
    this.isMonthly = false,
  });
}

class LeaderboardEntry {
  final String name;
  final int score;
  final int rank;
  final Color color;

  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.rank,
    required this.color,
  });
}

const workoutDiscoverCategories = ['All', 'Strength', 'HIIT', 'Yoga', 'Run'];

const workoutCollections = [
  ('No Equipment', Icons.home_outlined, Color(0xFFDBEAFE)),
  ('Fat Loss', Icons.local_fire_department_outlined, Color(0xFFFEF3C7)),
  ('Build Muscle', Icons.fitness_center, Color(0xFFECFCCB)),
  ('Mobility', Icons.self_improvement, Color(0xFFF3E8FF)),
];

const topCoaches = [
  WorkoutCoach(name: 'Sarah Chen', rating: 4.9, specialty: 'Strength', avatarColor: Color(0xFFFCA5A5)),
  WorkoutCoach(name: 'Marcus Lee', rating: 4.8, specialty: 'HIIT', avatarColor: Color(0xFF93C5FD)),
  WorkoutCoach(name: 'Elena Rossi', rating: 4.9, specialty: 'Yoga', avatarColor: Color(0xFFF9A8D4)),
  WorkoutCoach(name: 'James Park', rating: 4.7, specialty: 'Run', avatarColor: Color(0xFFA7F3D0)),
];

const featuredPrograms = [
  WorkoutProgram(
    id: '30_day_shred',
    title: '30-Day Shred',
    duration: '4 weeks',
    difficulty: 'Intermediate',
    goal: 'Fat loss & conditioning',
    workoutsPerWeek: 5,
    totalWeeks: 4,
    progress: 0.35,
    gradient: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
  ),
  WorkoutProgram(
    id: 'lean_muscle',
    title: 'Lean Muscle Builder',
    duration: '8 weeks',
    difficulty: 'Intermediate',
    goal: 'Hypertrophy',
    workoutsPerWeek: 4,
    totalWeeks: 8,
    progress: 0,
    gradient: [Color(0xFF365314), Color(0xFF1A2E05)],
  ),
  WorkoutProgram(
    id: 'beginner_foundation',
    title: 'Beginner Foundation',
    duration: '6 weeks',
    difficulty: 'Beginner',
    goal: 'Build habits',
    workoutsPerWeek: 3,
    totalWeeks: 6,
    progress: 0,
    gradient: [Color(0xFF4C1D95), Color(0xFF2E1065)],
  ),
];

const activeChallenges = [
  WorkoutChallenge(
    id: 'monthly_50',
    title: '50 Workouts Challenge',
    subtitle: 'Complete 50 workouts this month',
    progress: 32,
    target: 50,
    isMonthly: true,
  ),
  WorkoutChallenge(
    id: 'steps_100k',
    title: '100K Steps',
    subtitle: 'Walk 100,000 steps',
    progress: 68420,
    target: 100000,
  ),
  WorkoutChallenge(
    id: 'streak_14',
    title: '14-Day Streak',
    subtitle: 'Work out 14 days in a row',
    progress: 12,
    target: 14,
  ),
];

const challengeLeaderboard = [
  LeaderboardEntry(name: 'Alex M.', score: 48, rank: 1, color: Color(0xFFA3E635)),
  LeaderboardEntry(name: 'Jordan K.', score: 45, rank: 2, color: Color(0xFF93C5FD)),
  LeaderboardEntry(name: 'Sam R.', score: 42, rank: 3, color: Color(0xFFF9A8D4)),
  LeaderboardEntry(name: 'You', score: 32, rank: 8, color: Color(0xFF171717)),
];

const _dummyWorkout = CuratedWorkout(
  routeId: 'full-body-dummy',
  name: 'Full Body',
  category: 'Strength',
  difficulty: 'Intermediate',
  durationMin: 45,
  estimatedKcal: 350,
  exerciseCount: 10,
  muscleGroup: 'Full Body',
  exercises: [],
  gradient: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
);

CuratedWorkout get featuredWorkout => _dummyWorkout;

WorkoutProgram? programById(String id) {
  for (final p in featuredPrograms) {
    if (p.id == id) return p;
  }
  return null;
}
