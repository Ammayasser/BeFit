import '../entities/workout_session.dart';

abstract class IWorkoutRepository {
  Future<int> insertWorkoutSession(WorkoutSessionEntity session);
  Future<List<WorkoutSet>> getLastWorkoutSets(String userId, String exerciseName);
}
