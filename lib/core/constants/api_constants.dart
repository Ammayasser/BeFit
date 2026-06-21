// lib/core/constants/api_constants.dart

/// Central registry for every remote endpoint the BeFit app communicates with.
/// No other file in the project should contain raw URL strings.
class ApiConstants {
  ApiConstants._();

  // ── BeFit REST API ────────────────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'BEFIT_BASE_URL',
    defaultValue: 'https://befit-api.runasp.net',
  );

  // Auth
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';

  // User profile
  static const String me = '$baseUrl/api/users/me';

  // Protected resources
  static const String progress = '$baseUrl/api/progress';

  // ── Community AI coach (OpenRouter) ───────────────────────────────────────
  static const String openRouterChatUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String openRouterChatModel = 'openai/gpt-4o-mini';

  static const String openRouterApiKey = String.fromEnvironment(
    'BEFIT_OPENROUTER_KEY',
  );

  // ── Claude AI (legacy constants; community chat uses OpenRouter above) ────
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-3-5-haiku-20241022';
  static const String claudeVersion = '2023-06-01';

  // ── Exercise Library API (https://workout.runasp.net) ──────────────────────
  static const String exerciseApiBase = 'https://workout.runasp.net';

  // ── Open Food Facts ───────────────────────────────────────────────────────
  static const String openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  // ── Spoonacular Food API (https://spoonacular.com/food-api) ───────────────
  static const String spoonacularBaseUrl = 'https://api.spoonacular.com';

  static const String spoonacularApiKey = String.fromEnvironment(
    'BEFIT_SPOONACULAR_API_KEY',
  );

  static const String fitbodDataAsset = 'assets/data/fitbod_data_for_app.json';
  static const String muscleSvgsDir = 'assets/muscle_svgs/';
}
