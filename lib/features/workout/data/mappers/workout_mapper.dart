import 'package:befit/features/workout/data/models/workout_models.dart';
import 'package:befit/features/workout/data/models/workout_routine.dart' as models;
import 'package:befit/features/workout/domain/entities/workout_session.dart';

class WorkoutMapper {
  static SetType toEntitySetType(models.SetType model) {
    switch (model) {
      case models.SetType.warmup:
        return SetType.warmup;
      case models.SetType.dropSet:
        return SetType.dropSet;
      case models.SetType.failure:
        return SetType.failure;
      case models.SetType.normal:
        return SetType.normal;
    }
  }

  static models.SetType toModelSetType(SetType entity) {
    switch (entity) {
      case SetType.warmup:
        return models.SetType.warmup;
      case SetType.dropSet:
        return models.SetType.dropSet;
      case SetType.failure:
        return models.SetType.failure;
      case SetType.normal:
        return models.SetType.normal;
    }
  }

  static WorkoutSet toEntitySet(LoggedSet model) {
    return WorkoutSet(
      setNumber: model.setNumber,
      weightKg: model.weightKg,
      reps: model.reps,
      loggedAt: model.loggedAt,
      isEdited: model.isEdited,
      isCompleted: model.isCompleted,
      setType: toEntitySetType(model.setType),
    );
  }

  static LoggedSet toModelSet(WorkoutSet entity) {
    return LoggedSet(
      setNumber: entity.setNumber,
      weightKg: entity.weightKg,
      reps: entity.reps,
      loggedAt: entity.loggedAt,
      isEdited: entity.isEdited,
      isCompleted: entity.isCompleted,
      setType: toModelSetType(entity.setType),
    );
  }

  static WorkoutExercise toEntityExercise(SessionExercise model) {
    return WorkoutExercise(
      id: model.id,
      name: model.name,
      muscleGroup: model.muscleGroup,
      gifUrl: model.gifUrl,
      targetSets: model.targetSets,
      targetReps: model.targetReps,
      targetWeight: model.targetWeight,
      met: model.met,
      loggedSets: model.loggedSets.map(toEntitySet).toList(),
      isSkipped: model.isSkipped,
    );
  }

  static SessionExercise toModelExercise(WorkoutExercise entity) {
    return SessionExercise(
      id: entity.id,
      name: entity.name,
      muscleGroup: entity.muscleGroup,
      gifUrl: entity.gifUrl,
      targetSets: entity.targetSets,
      targetReps: entity.targetReps,
      targetWeight: entity.targetWeight,
      met: entity.met,
      loggedSets: entity.loggedSets.map(toModelSet).toList(),
      isSkipped: entity.isSkipped,
    );
  }

  static WorkoutSessionEntity toEntitySession(WorkoutSession model) {
    return WorkoutSessionEntity(
      sessionId: model.sessionId,
      userId: model.userId,
      workoutName: model.workoutName,
      startedAt: model.startedAt,
      finishedAt: model.finishedAt,
      exercises: model.exercises.map(toEntityExercise).toList(),
      currentExerciseIndex: model.currentExerciseIndex,
      sessionNote: model.sessionNote,
      moodRating: model.moodRating,
    );
  }

  static WorkoutSession toModelSession(WorkoutSessionEntity entity) {
    return WorkoutSession(
      sessionId: entity.sessionId,
      userId: entity.userId,
      workoutName: entity.workoutName,
      startedAt: entity.startedAt,
      finishedAt: entity.finishedAt,
      exercises: entity.exercises.map(toModelExercise).toList(),
      currentExerciseIndex: entity.currentExerciseIndex,
      sessionNote: entity.sessionNote,
      moodRating: entity.moodRating,
    );
  }
}
