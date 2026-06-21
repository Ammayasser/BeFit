import '../entities/workout_session.dart';
import '../repositories/i_workout_repository.dart';
import '../../data/repositories/muscle_engagement_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/models/muscle_engagement_model.dart';

abstract class IWorkoutApiService {
  Future<void> postWorkoutProgress(String token, WorkoutSessionEntity session);
}

abstract class IAchievementService {
  void fireWorkout(String userId, Map<String, dynamic> data);
}

class FinishWorkoutSessionUseCase {
  final IWorkoutRepository _repository;
  final IWorkoutApiService _apiService;
  final IAchievementService _achievementService;
  final MuscleEngagementRepository _engagementRepository;
  final ExerciseRepository _exerciseRepository;

  FinishWorkoutSessionUseCase(
    this._repository,
    this._apiService,
    this._achievementService,
    this._engagementRepository,
    this._exerciseRepository,
  );

  Future<WorkoutSessionEntity?> execute({
    required WorkoutSessionEntity session,
    required String token,
    String? note,
    int? mood,
  }) async {
    final finishedSession = session.copyWith(
      finishedAt: DateTime.now(),
      sessionNote: note,
      moodRating: mood,
    );

    // Filter out uncompleted sets and empty exercises
    final List<WorkoutExercise> validExercises = [];
    for (final exercise in finishedSession.exercises) {
      final completedSets = exercise.loggedSets.where((s) => s.isCompleted).toList();
      if (completedSets.isNotEmpty) {
        // Re-number completed sets
        final renumberedSets = <WorkoutSet>[];
        for (int i = 0; i < completedSets.length; i++) {
          renumberedSets.add(completedSets[i].copyWith(setNumber: i + 1));
        }
        validExercises.add(exercise.copyWith(loggedSets: renumberedSets));
      }
    }

    if (validExercises.isEmpty) {
      return null;
    }

    final finalSession = finishedSession.copyWith(exercises: validExercises);

    // 1. Persist locally
    final logId = await _repository.insertWorkoutSession(finalSession);

    // 2. Compute and persist Muscle Engagements
    await _computeAndSaveMuscleEngagements(finalSession, logId);

    // 3. Broadcast achievement
    _achievementService.fireWorkout(finalSession.userId, {
      'name': finalSession.workoutName,
      'volume': finalSession.totalVolume,
      'sets': finalSession.totalSets,
      'reps': finalSession.totalReps,
      'duration_min': finalSession.duration.inMinutes,
      'exercises_count': finalSession.exercises.length,
      'start_hour': finalSession.startedAt.hour,
    });

    // 4. Sync to remote (background)
    _apiService.postWorkoutProgress(token, finalSession).catchError((_) {
      // Log error or handle retry
    });

    return finalSession;
  }

  Future<void> _computeAndSaveMuscleEngagements(WorkoutSessionEntity session, int logId) async {
    final Map<String, MuscleEngagementEntry> muscleMap = {};
    
    for (final exercise in session.exercises) {
      if (exercise.isSkipped) continue;
      
      final dbExercise = await _exerciseRepository.getExerciseByName(exercise.name);
      List<String> primaryMuscles = [];
      List<String> secondaryMuscles = [];
      double met = exercise.met ?? 3.5;
      
      if (dbExercise != null) {
        if (dbExercise.primaryMuscles.isNotEmpty) {
          primaryMuscles = List<String>.from(dbExercise.primaryMuscles);
        } else if (dbExercise.target != null) {
          primaryMuscles = [dbExercise.target!.toLowerCase()];
        }
        
        if (dbExercise.secondaryMuscles.isNotEmpty) {
          secondaryMuscles = List<String>.from(dbExercise.secondaryMuscles);
        }
        met = dbExercise.met ?? met;
      } else {
        if (exercise.muscleGroup != null) {
          primaryMuscles = [exercise.muscleGroup!.toLowerCase()];
        }
      }
      
      double exerciseVolume = 0;
      int completedSets = 0;
      for (final set in exercise.loggedSets) {
        if (set.isCompleted) {
          exerciseVolume += set.weightKg * set.reps;
          completedSets++;
        }
      }
      
      if (completedSets == 0) continue;
      
      final isCompound = (dbExercise?.mechanic?.toLowerCase() == 'compound');
      final compoundMultiplier = isCompound ? 1.3 : 1.0;
      final intensityScore = (exerciseVolume * met * compoundMultiplier) / 1000.0;
      
      // Assign 100% volume to primary muscles
      for (final muscle in primaryMuscles) {
        final key = _normalizeMuscleName(muscle);
        if (key.isEmpty) continue;
        
        if (muscleMap.containsKey(key)) {
          final existing = muscleMap[key]!;
          muscleMap[key] = MuscleEngagementEntry(
            userId: session.userId,
            workoutLogId: logId,
            muscleName: key,
            totalVolume: existing.totalVolume + exerciseVolume,
            setCount: existing.setCount + completedSets,
            exerciseCount: existing.exerciseCount + 1,
            isPrimary: true,
            intensityScore: existing.intensityScore + intensityScore,
            trainedAt: session.finishedAt ?? DateTime.now(),
          );
        } else {
          muscleMap[key] = MuscleEngagementEntry(
            userId: session.userId,
            workoutLogId: logId,
            muscleName: key,
            totalVolume: exerciseVolume,
            setCount: completedSets,
            exerciseCount: 1,
            isPrimary: true,
            intensityScore: intensityScore,
            trainedAt: session.finishedAt ?? DateTime.now(),
          );
        }
      }
      
      // Assign 50% volume to secondary muscles
      for (final muscle in secondaryMuscles) {
        final key = _normalizeMuscleName(muscle);
        if (key.isEmpty) continue;
        
        final partialVolume = exerciseVolume * 0.5;
        final partialIntensity = intensityScore * 0.5;
        
        if (muscleMap.containsKey(key)) {
          final existing = muscleMap[key]!;
          muscleMap[key] = MuscleEngagementEntry(
            userId: session.userId,
            workoutLogId: logId,
            muscleName: key,
            totalVolume: existing.totalVolume + partialVolume,
            setCount: existing.setCount + completedSets,
            exerciseCount: existing.exerciseCount + 1,
            isPrimary: existing.isPrimary, // keep true if it was already primary
            intensityScore: existing.intensityScore + partialIntensity,
            trainedAt: session.finishedAt ?? DateTime.now(),
          );
        } else {
          muscleMap[key] = MuscleEngagementEntry(
            userId: session.userId,
            workoutLogId: logId,
            muscleName: key,
            totalVolume: partialVolume,
            setCount: completedSets,
            exerciseCount: 1,
            isPrimary: false,
            intensityScore: partialIntensity,
            trainedAt: session.finishedAt ?? DateTime.now(),
          );
        }
      }
    }
    
    await _engagementRepository.insertEngagements(muscleMap.values.toList());
  }
  
  String _normalizeMuscleName(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.contains('pec') || lower.contains('chest')) return 'chest';
    if (lower.contains('lat') || lower.contains('back')) return 'back';
    if (lower.contains('bicep')) return 'biceps';
    if (lower.contains('tricep')) return 'triceps';
    if (lower.contains('shoulder') || lower.contains('deltoid')) return 'shoulders';
    if (lower.contains('quad')) return 'quadriceps';
    if (lower.contains('hamstring')) return 'hamstrings';
    if (lower.contains('calf') || lower.contains('calves')) return 'calves';
    if (lower.contains('glute')) return 'glutes';
    if (lower.contains('abs') || lower.contains('core')) return 'abs';
    if (lower.contains('lower back')) return 'lower-back';
    if (lower.contains('trap')) return 'trapezius';
    if (lower.contains('forearm')) return 'forearms';
    if (lower.contains('abductor')) return 'abductors';
    if (lower.contains('adductor')) return 'adductors';
    return lower.replaceAll(' ', '-');
  }
}
