import 'package:flutter/material.dart';
import '../../data/models/user_context.dart';
import '../../data/services/user_context_builder.dart';
import '../../data/services/ai_chat_service.dart';
import '../../data/services/ai_response_parser.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_session.dart';
import '../../domain/mappers/chat_mapper.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/repositories/i_chat_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';

class ChatProvider extends ChangeNotifier {
  final AiChatService _aiService = AiChatService();
  late final IChatRepository _repository;

  String? _userId;
  String? _currentSessionId; // NEW: track current active conversation
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _error;
  bool _disposed = false;

  UserContext? _userContext; // holds the loaded user snapshot

  ChatProvider() {
    _repository = ChatRepository();
  }

  List<ChatMessage> get messages {
    if (_currentSessionId == null) return [];
    // Only show messages belonging to the current session
    return _messages.where((m) => m.sessionId == _currentSessionId).toList();
  }
  bool get isTyping => _isTyping;
  bool get hasMessages => messages.isNotEmpty;
  String? get error => _error;
  UserContext? get userContext => _userContext;
  String? get currentSessionId => _currentSessionId;

  // ── Context-aware suggested questions ─────────────────────────

  List<SuggestedQuestion> get suggestedQuestions {
    final ctx = _userContext;
    if (ctx == null) return _defaultSuggestions;

    return [
      SuggestedQuestion(
        icon: 'fitness_center',
        text:
            'Give me a ${ctx.workoutLocation} ${ctx.fitnessGoal.split(' ').first.toLowerCase()} workout',
      ),
      SuggestedQuestion(
        icon: 'restaurant',
        text:
            'I\'ve eaten ${ctx.caloriesToday} kcal today — what should I eat next?',
      ),
      SuggestedQuestion(
        icon: 'trending_up',
        text: 'How\'s my progress this week?',
      ),
    ];
  }

  static final _defaultSuggestions = [
    SuggestedQuestion(icon: 'fitness_center', text: 'Give me a chest workout'),
    SuggestedQuestion(icon: 'restaurant', text: 'What should I eat today?'),
    SuggestedQuestion(
      icon: 'trending_up',
      text: 'How can I track my progress?',
    ),
  ];

  // ── Init ──────────────────────────────────────────────────────

  Future<void> initForUser(String userId, BuildContext context) async {
    _userId = userId;
    await Future.wait([_loadMessages(), _loadUserContext(context)]);
    
    // If we have messages but no current session, pick the most recent one
    if (_messages.isNotEmpty && _currentSessionId == null) {
      _currentSessionId = _messages.last.sessionId;
      _notify();
    }
  }

  Future<void> _loadUserContext(BuildContext context) async {
    try {
      _userContext = await UserContextBuilder.build(context);
      _notify();
    } catch (e) {
      debugPrint('ChatProvider: failed to load user context: $e');
    }
  }

  Future<void> refreshContext(BuildContext context) =>
      _loadUserContext(context);

  Future<void> _loadMessages() async {
    if (_userId == null) return;
    try {
      final entities = await _repository.getChatHistory(_userId!);
      _messages = entities.map(ChatMapper.toModel).toList();
      _notify();
    } catch (e) {
      debugPrint('ChatProvider: error loading history: $e');
    }
  }

  // ── Actions ────────────────────────────────────────────────

  Future<List<ChatSession>> getAllSessions() async {
    if (_userId == null) return [];

    try {
      final entities = await _repository.getChatHistory(_userId!);
      final allMessages = entities.map(ChatMapper.toModel).toList();

      final Map<String, List<ChatMessage>> grouped = {};
      for (final m in allMessages) {
        final sid = m.sessionId ?? 'legacy';
        grouped.putIfAbsent(sid, () => []).add(m);
      }

      final sessions = <ChatSession>[];
      
      grouped.forEach((sid, sessionMessages) {
        // Find first user message for title
        final firstUserMsg = sessionMessages.firstWhere(
          (m) => m.role == MessageRole.user,
          orElse: () => sessionMessages.first,
        );
        
        sessions.add(
          ChatSession(
            id: sid,
            title: firstUserMsg.content.isEmpty 
                ? 'New Conversation' 
                : (firstUserMsg.content.length > 60 
                    ? '${firstUserMsg.content.substring(0, 57)}...' 
                    : firstUserMsg.content),
            createdAt: sessionMessages.first.timestamp,
            updatedAt: sessionMessages.last.timestamp,
            messages: sessionMessages,
          ),
        );
      });

      // Sort by latest message first
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return sessions;
    } catch (e) {
      debugPrint('ChatProvider: error fetching all sessions: $e');
      return [];
    }
  }

  String? _scrollToMessageId;
  String? get scrollToMessageId => _scrollToMessageId;

  Future<void> loadChat(String sessionId) async {
    if (_userId == null) return;
    
    _currentSessionId = sessionId;
    
    // Reload messages to be sure
    await _loadMessages();
    
    // Check if the session exists in our loaded messages
    final sessionMessages = _messages.where((m) => m.sessionId == sessionId).toList();
    if (sessionMessages.isNotEmpty) {
      _scrollToMessageId = sessionMessages.last.id;
      _notify();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _scrollToMessageId = null;
      });
    }
  }

  Future<void> deleteChat(String sessionId) async {
    if (_userId == null) return;
    try {
      final db = await DatabaseHelper.instance.database;
      if (sessionId == 'legacy') {
        await db.delete('chat_messages', where: 'userId = ? AND sessionId IS NULL', whereArgs: [_userId]);
      } else {
        await db.delete('chat_messages', where: 'userId = ? AND sessionId = ?', whereArgs: [_userId, sessionId]);
      }

      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
      }
      
      await _loadMessages();
    } catch (e) {
      debugPrint('ChatProvider: error deleting chat: $e');
    }
  }

  // ── Send ──────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (_userId == null || text.trim().isEmpty) return;

    final content = text.trim();
    
    // Ensure we have a session ID
    _currentSessionId ??= const Uuid().v4();

    // 1. Add user message immediately
    final userMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      sessionId: _currentSessionId,
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    _messages.add(userMsg);
    _isTyping = true;
    _error = null;
    _notify();

    // Persist user message
    await _repository.saveMessage(_userId!, ChatMapper.toEntity(userMsg));

    // 2. Build placeholder for AI response
    final aiId = '${DateTime.now().millisecondsSinceEpoch + 1}';
    final placeholder = ChatMessage(
      id: aiId,
      sessionId: _currentSessionId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.add(placeholder);
    _notify();

    try {
      // 3. Build conversation history for API (text-only, last 20 messages)
      final sentMessages = _messages
          .where((m) => m.status == MessageStatus.sent && m.content.isNotEmpty)
          .toList();
      final last20 = sentMessages.length > 20
          ? sentMessages.sublist(sentMessages.length - 20)
          : sentMessages;

      final history = last20
          .map(
            (m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content':
                  m.role == MessageRole.assistant &&
                      m.messageType != ChatMessageType.text
                  ? '[Structured response rendered as UI card]' // Don't send raw JSON back
                  : m.content,
            },
          )
          .toList();

      // 4. Send to AI with user context
      final rawResponse = await _aiService.sendContextualMessage(
        conversationHistory: history.cast<Map<String, String>>(),
        userMessage: content,
        userContext: _userContext ?? _buildFallbackContext(),
      );

      // 5. Parse the response (text vs structured)
      final parsed = AiResponseParser.parse(rawResponse);

      // 6. Replace placeholder with final message
      final finalMsg = ChatMessage(
        id: aiId,
        sessionId: _currentSessionId,
        role: MessageRole.assistant,
        content: parsed.displayContent,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        messageType: parsed.type,
        structuredData: parsed.data,
      );

      final idx = _messages.indexWhere((m) => m.id == aiId);
      if (idx != -1) _messages[idx] = finalMsg;

      // 7. Persist (store content as-is; structured data will be re-parsed on load)
      await _repository.saveMessage(_userId!, ChatMapper.toEntity(finalMsg));
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == aiId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(
          content: 'Sorry, I encountered an issue. Please try again.',
          status: MessageStatus.error,
        );
      }
      _error = e.toString();
    } finally {
      _isTyping = false;
      _notify();
    }
  }

  UserContext _buildFallbackContext() => const UserContext(
    name: 'Athlete',
    age: 25,
    gender: 'Male',
    heightCm: 175,
    weightKg: 75,
    fitnessGoal: 'Build Muscle',
    activityLevel: 'Moderate',
    experienceLevel: 'Intermediate',
    workoutLocation: 'gym',
    workoutDaysPerWeek: 4,
    bmi: 24.5,
    tdee: 2800,
    proteinTargetG: 150,
    caloriesToday: 0,
    calorieGoal: 2800,
    proteinTodayG: 0,
    carbsTodayG: 0,
    fatTodayG: 0,
    waterTodayMl: 0,
    waterGoalMl: 2500,
    totalWorkoutsAllTime: 0,
    workoutsThisWeek: 0,
    currentStreakDays: 0,
    recentWorkoutFocuses: [],
    primaryEquipment: 'gym equipment',
  );

  void sendSuggested(String text) => sendMessage(text);
  void startNewChat() {
    _currentSessionId = const Uuid().v4();
    _notify();
  }

  Future<void> clearHistory() async {
    if (_userId == null) return;
    await _repository.clearHistory(_userId!);
    _messages = [];
    _currentSessionId = null;
    _notify();
  }

  void clearError() {
    _error = null;
    _notify();
  }

  void resetForLogout() {
    _userId = null;
    _messages = [];
    _isTyping = false;
    _error = null;
    _userContext = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _aiService.dispose();
    super.dispose();
  }
}

