enum ChatRole { user, assistant }

enum ChatMessageStatus { sending, sent, error }

class ChatMessageEntity {
  final String id;
  final String? sessionId; // NEW: track conversation grouping
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final ChatMessageStatus status;

  const ChatMessageEntity({
    required this.id,
    this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = ChatMessageStatus.sent,
  });

  bool get isUser => role == ChatRole.user;

  ChatMessageEntity copyWith({
    ChatMessageStatus? status,
    String? content,
    String? sessionId,
  }) {
    return ChatMessageEntity(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }
}
