import '../entities/nutrition_daily.dart';
import '../repositories/i_nutrition_repository.dart';

class GetDailyNutritionUseCase {
  final INutritionRepository _repository;

  GetDailyNutritionUseCase(this._repository);

  Future<NutritionDailyEntity> execute(String userId, DateTime date) async {
    return await _repository.getDailyNutrition(userId, date);
  }
}
