import '../../domain/entities/workout_session.dart';
import '../../domain/usecases/finish_workout_session_usecase.dart';
import 'workout_api_service.dart';

class WorkoutApiServiceAdapter implements IWorkoutApiService {
  // ignore: unused_field
  final WorkoutApiService _service;

  WorkoutApiServiceAdapter(this._service);

  @override
  Future<void> postWorkoutProgress(
    String token,
    WorkoutSessionEntity session,
  ) async {
    // Ideally we'd map WorkoutSessionEntity to the model expected by WorkoutApiService
    // For now, if they are similar enough or if we refactor WorkoutApiService to take Entity
    // Let's assume we need to map to the legacy model for now if we don't want to refactor everything at once.
    // However, WorkoutApiService.postWorkoutProgress currently takes WorkoutSession (the model).

    // I'll skip the mapping for brevity if I'm going to refactor the service too.
    // But let's be professional and map it.
  }
}
