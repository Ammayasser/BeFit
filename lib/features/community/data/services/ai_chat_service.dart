import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/user_context.dart';

class AiChatService {
  final http.Client _client;
  AiChatService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> sendContextualMessage({
    required List<Map<String, String>> conversationHistory,
    required String userMessage,
    required UserContext userContext,
  }) async {
    final apiKey = ApiConstants.openRouterApiKey.trim();
    if (apiKey.isEmpty) throw AiChatException('AI coach not configured.');

    final messages = [
      {
        'role': 'system',
        'content': userContext.toSystemPrompt(),  // Full personalized system prompt
      },
      // Last 10 messages for context window efficiency
      ...(conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory),
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    final response = await _client.post(
      Uri.parse(ApiConstants.openRouterChatUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://befit.app',
        'X-Title': 'BeFit AI Coach',
      },
      body: jsonEncode({
        'model': ApiConstants.openRouterChatModel,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = (data['choices'] as List?)
          ?.first?['message']?['content'] as String?;
      if (content != null && content.trim().isNotEmpty) return content.trim();
      throw AiChatException('Empty AI response. Please try again.');
    }

    throw AiChatException(_parseErrorBody(response.statusCode, response.body));
  }

  String _parseErrorBody(int code, String body) {
    try {
      final err = (jsonDecode(body) as Map)['error'];
      if (err is Map) return 'AI error ($code): ${err['message']}';
    } catch (_) {}
    return 'AI error ($code)';
  }

  void dispose() => _client.close();
}

class AiChatException implements Exception {
  final String message;
  const AiChatException(this.message);
  @override String toString() => message;
}
