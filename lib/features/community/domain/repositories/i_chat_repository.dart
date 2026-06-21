import '../entities/chat_message.dart';

abstract class IChatRepository {
  Future<List<ChatMessageEntity>> getChatHistory(String userId);
  Future<void> saveMessage(String userId, ChatMessageEntity message);
  Future<void> clearHistory(String userId);
}
