// lib/features/nutrition/data/services/recipe_api_exception.dart

class RecipeApiException implements Exception {
  final String message;
  final int? statusCode;

  const RecipeApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'RecipeApiException($statusCode): $message';
}
