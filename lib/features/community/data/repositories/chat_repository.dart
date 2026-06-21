import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  final DatabaseHelper _dbHelper;

  ChatRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<void> saveMessage(String userId, ChatMessageEntity message) async {
    final db = await _dbHelper.database;
    await db.insert('chat_messages', {
      'id': message.id,
      'userId': userId,
      'sessionId': message.sessionId,
      'content': message.content,
      'isUser': message.isUser ? 1 : 0,
      'timestamp': message.timestamp.toIso8601String(),
      'isError': message.status == ChatMessageStatus.error ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'chat_messages',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
    );
    return results.map(_toEntity).toList();
  }

  Future<List<ChatMessageEntity>> getSessionMessages(String userId, String sessionId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'chat_messages',
      where: 'userId = ? AND sessionId = ?',
      whereArgs: [userId, sessionId],
      orderBy: 'timestamp ASC',
    );
    return results.map(_toEntity).toList();
  }

  @override
  Future<void> clearHistory(String userId) async {
    final db = await _dbHelper.database;
    await db.delete('chat_messages', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> deleteSession(String userId, String sessionId) async {
    final db = await _dbHelper.database;
    await db.delete('chat_messages', where: 'userId = ? AND sessionId = ?', whereArgs: [userId, sessionId]);
  }

  ChatMessageEntity _toEntity(Map<String, dynamic> data) {
    return ChatMessageEntity(
      id: data['id'] as String,
      sessionId: data['sessionId'] as String?,
      role: (data['isUser'] as int) == 1 ? ChatRole.user : ChatRole.assistant,
      content: data['content'] as String,
      timestamp: DateTime.parse(data['timestamp'] as String),
      status: (data['isError'] as int) == 1 ? ChatMessageStatus.error : ChatMessageStatus.sent,
    );
  }
}
