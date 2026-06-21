import 'dart:convert';
import '../../domain/models/chat_message.dart';

/// Determines whether the AI returned structured JSON or plain text,
/// and returns the appropriate ChatMessageType + parsed data.
class AiResponseParser {
  static ({ChatMessageType type, String displayContent, Map<String, dynamic>? data})
      parse(String rawResponse) {
    final trimmed = rawResponse.trim();

    // 1. Try to find a JSON object in the string by locating the first '{' and last '}'
    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final possibleJson = trimmed.substring(firstBrace, lastBrace + 1);
      try {
        final json = jsonDecode(possibleJson) as Map<String, dynamic>;
        final type = json['type'] as String?;
        if (type == 'workout_plan') {
          return (
            type: ChatMessageType.workoutPlan,
            displayContent: possibleJson,
            data: json,
          );
        }
        if (type == 'nutrition_plan') {
          return (
            type: ChatMessageType.nutritionPlan,
            displayContent: possibleJson,
            data: json,
          );
        }
        if (type == 'progress_summary') {
          return (
            type: ChatMessageType.progressSummary,
            displayContent: possibleJson,
            data: json,
          );
        }
      } catch (_) {
        // Substring was not valid JSON
      }
    }

    // 2. Fallback: Also handle JSON embedded in markdown code blocks specifically
    final jsonMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(trimmed);
    if (jsonMatch != null) {
      try {
        final json = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
        final type = json['type'] as String?;
        if (type == 'workout_plan' || type == 'nutrition_plan' || type == 'progress_summary') {
          return (
            type: type == 'workout_plan' ? ChatMessageType.workoutPlan
                : type == 'nutrition_plan' ? ChatMessageType.nutritionPlan
                : ChatMessageType.progressSummary,
            displayContent: jsonMatch.group(1)!,
            data: json,
          );
        }
      } catch (_) {}
    }

    // Default: plain text
    return (type: ChatMessageType.text, displayContent: rawResponse, data: null);
  }
}
