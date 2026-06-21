import '../../../../core/achievements/engine/achievement_event_bus.dart';
import '../../domain/usecases/finish_workout_session_usecase.dart';

class AchievementServiceAdapter implements IAchievementService {
  @override
  void fireWorkout(String userId, Map<String, dynamic> data) {
    AchievementEventBus().fireWorkout(userId, data);
  }
}
