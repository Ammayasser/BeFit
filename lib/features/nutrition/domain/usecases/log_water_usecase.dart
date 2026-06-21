import '../repositories/i_nutrition_repository.dart';

class LogWaterUseCase {
  final INutritionRepository _repository;

  LogWaterUseCase(this._repository);

  Future<void> execute({
    required String userId,
    required DateTime date,
    required int amountMl,
    required int totalMl,
    required List<int> hourly,
  }) async {
    final hour = DateTime.now().hour;
    final updatedHourly = List<int>.from(hourly);
    updatedHourly[hour] += amountMl;
    
    await _repository.updateWaterIntake(userId, date, totalMl + amountMl, updatedHourly);
  }
}
