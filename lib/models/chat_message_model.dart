import 'package:cloud_firestore/cloud_firestore.dart';

/// One message in a vet-AI chat session.
///
/// Persisted to `chat_sessions/{sessionId}/messages/{messageId}` so that
/// rules cascade naturally and history can be streamed in order. The
/// [userId] field is duplicated onto each message so security rules can
/// validate ownership without reading the parent session doc.
enum ChatRole { user, assistant }

class ChatMessageModel {
  final String? id;
  final String sessionId;
  final String userId;
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  const ChatMessageModel({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  ChatMessageModel copyWith({
    String? id,
    String? sessionId,
    String? userId,
    ChatRole? role,
    String? text,
    DateTime? timestamp,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'role': role.name,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessageModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return ChatMessageModel(
      id: docId,
      sessionId: data['sessionId'] ?? '',
      userId: data['userId'] ?? '',
      role: _parseRole(data['role']),
      text: data['text'] ?? '',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static ChatRole _parseRole(dynamic raw) {
    if (raw == 'user') return ChatRole.user;
    return ChatRole.assistant;
  }
}
