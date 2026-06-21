import '../../domain/entities/chat_message.dart';
import '../../domain/models/chat_message.dart' as models;
import '../../data/services/ai_response_parser.dart';

class ChatMapper {
  static ChatMessageEntity toEntity(models.ChatMessage model) {
    return ChatMessageEntity(
      id: model.id,
      sessionId: model.sessionId,
      role: _toEntityRole(model.role),
      content: model.content,
      timestamp: model.timestamp,
      status: _toEntityStatus(model.status),
    );
  }

  static models.ChatMessage toModel(ChatMessageEntity entity) {
    final parsed = AiResponseParser.parse(entity.content);
    return models.ChatMessage(
      id: entity.id,
      sessionId: entity.sessionId,
      role: _toModelRole(entity.role),
      content: parsed.displayContent,
      timestamp: entity.timestamp,
      status: _toModelStatus(entity.status),
      messageType: parsed.type,
      structuredData: parsed.data,
    );
  }

  static ChatRole _toEntityRole(models.MessageRole role) {
    return role == models.MessageRole.user ? ChatRole.user : ChatRole.assistant;
  }

  static models.MessageRole _toModelRole(ChatRole role) {
    return role == ChatRole.user ? models.MessageRole.user : models.MessageRole.assistant;
  }

  static ChatMessageStatus _toEntityStatus(models.MessageStatus status) {
    return switch (status) {
      models.MessageStatus.sending => ChatMessageStatus.sending,
      models.MessageStatus.sent => ChatMessageStatus.sent,
      models.MessageStatus.error => ChatMessageStatus.error,
    };
  }

  static models.MessageStatus _toModelStatus(ChatMessageStatus status) {
    return switch (status) {
      ChatMessageStatus.sending => models.MessageStatus.sending,
      ChatMessageStatus.sent => models.MessageStatus.sent,
      ChatMessageStatus.error => models.MessageStatus.error,
    };
  }
}
