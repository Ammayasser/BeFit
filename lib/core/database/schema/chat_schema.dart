import 'package:sqflite/sqflite.dart';

class ChatSchema {
  static const String tableMessages = 'chat_messages';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE $tableMessages (
        id          TEXT PRIMARY KEY,
        userId      TEXT NOT NULL,
        sessionId   TEXT,
        content     TEXT NOT NULL,
        isUser      INTEGER NOT NULL,
        timestamp   TEXT NOT NULL,
        isError     INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_chat_messages_userId ON $tableMessages(userId)');
    await db.execute('CREATE INDEX idx_chat_messages_sessionId ON $tableMessages(sessionId)');
    await db.execute('CREATE INDEX idx_chat_messages_timestamp ON $tableMessages(timestamp)');
  }
}
