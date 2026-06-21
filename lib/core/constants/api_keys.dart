// lib/core/constants/api_keys.dart

class ApiKeys {
  ApiKeys._();

  /// Primary Gemini API key provided for the final project.
  static const String gemini = String.fromEnvironment('BEFIT_GEMINI_API_KEY');

  /// Secondary Gemini API key.
  static const String geminiSecondary = String.fromEnvironment('BEFIT_GEMINI_SECONDARY_API_KEY');

  /// Tertiary Gemini API key.
  static const String geminiTertiary = String.fromEnvironment('BEFIT_GEMINI_TERTIARY_API_KEY');

  /// List of all Gemini API keys in order of priority.
  static const List<String> geminiKeys = [
    gemini,
    geminiSecondary,
    geminiTertiary,
  ];
}
