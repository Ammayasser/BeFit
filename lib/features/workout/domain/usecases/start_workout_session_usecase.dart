import '../entities/workout_session.dart';
import '../repositories/i_workout_repository.dart';

class StartWorkoutSessionUseCase {
  final IWorkoutRepository _repository;

  StartWorkoutSessionUseCase(this._repository);

  Future<WorkoutSessionEntity> execute({
    required String name,
    required String userId,
    required List<WorkoutExercise> exercises,
  }) async {
    final List<WorkoutExercise> populatedExercises = [];

    for (final exercise in exercises) {
      if (exercise.loggedSets.isEmpty) {
        final lastSets = await _repository.getLastWorkoutSets(userId, exercise.name);
        if (lastSets.isNotEmpty) {
          populatedExercises.add(exercise.copyWith(
            loggedSets: lastSets.map((prevSet) => WorkoutSet(
              setNumber: prevSet.setNumber,
              weightKg: prevSet.weightKg,
              reps: prevSet.reps,
              loggedAt: DateTime.now(),
              isCompleted: false,
              isEdited: false,
            )).toList(),
          ));
        } else {
          int defaultReps = 10;
          final match = RegExp(r'\d+').firstMatch(exercise.targetReps);
          if (match != null) {
            final matchedText = match.group(0);
            if (matchedText != null) {
              defaultReps = int.tryParse(matchedText) ?? 10;
            }
          }
          final defaultWeight = exercise.targetWeight ?? 0.0;
          populatedExercises.add(exercise.copyWith(
            loggedSets: List.generate(
              exercise.targetSets > 0 ? exercise.targetSets : 3,
              (index) => WorkoutSet(
                setNumber: index + 1,
                weightKg: defaultWeight,
                reps: defaultReps,
                loggedAt: DateTime.now(),
                isCompleted: false,
                isEdited: false,
              ),
            ),
          ));
        }
      } else {
        populatedExercises.add(exercise);
      }
    }

    return WorkoutSessionEntity(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      workoutName: name,
      startedAt: DateTime.now(),
      exercises: populatedExercises,
      currentExerciseIndex: 0,
    );
  }
}
