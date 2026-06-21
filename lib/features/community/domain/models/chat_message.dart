import 'dart:convert';
import 'package:flutter/material.dart';

enum MessageRole { user, assistant }

enum MessageStatus { sending, sent, error }

// NEW: message content type
enum ChatMessageType {
  text,          // plain markdown text (default)
  workoutPlan,   // structured exercise list → renders as cards
  nutritionPlan, // structured meal plan → renders as nutrition cards
  progressSummary, // user stats summary card
}

class ChatMessage {
  final String id;
  final String? sessionId; // NEW
  final MessageRole role;
  final String content;           // text content OR raw JSON string for structured types
  final DateTime timestamp;
  final MessageStatus status;
  final int? thumbsUp; // 1 = up, -1 = down, null = none
  final ChatMessageType messageType;     // NEW
  final Map<String, dynamic>? structuredData; // NEW — parsed JSON payload

  ChatMessage({
    required this.id,
    this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.thumbsUp,
    this.messageType = ChatMessageType.text,  // default
    this.structuredData,
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    int? thumbsUp,
    ChatMessageType? messageType,
    Map<String, dynamic>? structuredData,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      thumbsUp: thumbsUp ?? this.thumbsUp,
      messageType: messageType ?? this.messageType,
      structuredData: structuredData ?? this.structuredData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'thumbsUp': thumbsUp,
        'messageType': messageType.name,
        'structuredData': structuredData != null ? jsonEncode(structuredData) : null,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String?,
        role: MessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        thumbsUp: json['thumbsUp'] as int?,
        messageType: json['messageType'] != null
            ? ChatMessageType.values.byName(json['messageType'] as String)
            : ChatMessageType.text,
        structuredData: json['structuredData'] != null
            ? jsonDecode(json['structuredData'] as String) as Map<String, dynamic>
            : null,
      );
}

class SuggestedQuestion {
  final String icon;
  final String text;
  final Color? iconColor;

  SuggestedQuestion({
    required this.icon,
    required this.text,
    this.iconColor,
  });
}
