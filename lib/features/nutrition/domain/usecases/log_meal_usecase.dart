import '../entities/meal_log.dart';
import '../repositories/i_nutrition_repository.dart';

class LogMealUseCase {
  final INutritionRepository _repository;

  LogMealUseCase(this._repository);

  Future<void> execute(MealLogEntity log) async {
    await _repository.saveMealLog(log);
  }
}
