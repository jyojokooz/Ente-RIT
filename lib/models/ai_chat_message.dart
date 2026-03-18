// ===============================
// FILE PATH: lib/models/ai_chat_message.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSource { app, web, chat, error }

class AiChatMessage {
  String text;
  final bool isUserMessage;
  MessageSource source;
  final Timestamp timestamp;

  AiChatMessage({
    required this.text,
    required this.isUserMessage,
    this.source = MessageSource.chat,
    required this.timestamp,
  });

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    return AiChatMessage(
      text: map['text'] ?? '',
      isUserMessage: map['isUserMessage'] ?? false,
      source: MessageSource.values[map['source'] ?? MessageSource.chat.index],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUserMessage': isUserMessage,
      'source': source.index,
      'timestamp': timestamp,
    };
  }
}
