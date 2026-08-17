import 'package:cloud_firestore/cloud_firestore.dart';

/// Kind of clinical context a chat session is anchored to. Drives the
/// system instruction used when calling Gemini and the suggested
/// starter prompts shown in the UI.
enum ChatContextType { poisoning, illness, general }

/// A chat session between an owner and the AI vet assistant.
///
/// The [context] is captured at session creation so that even after the
/// underlying diagnosis or incident is edited, the chat keeps its
/// original frame of reference. Messages live in a `messages`
/// subcollection: `chat_sessions/{id}/messages/{msgId}`.
class ChatSessionModel {
  final String? id;
  final String userId;
  final String? petId;
  final String? petName;
  final String? petSpecies;
  final ChatContextType contextType;

  /// Substance name for poisoning chats, condition name for illness
  /// chats. Empty string for [ChatContextType.general].
  final String subject;

  /// Risk / urgency label captured from the originating screen
  /// (`EMERGENCY`, `HIGH`, `MODERATE`, `LOW`, or empty).
  final String riskLabel;

  /// Optional one-paragraph clinical summary so the AI doesn't need to
  /// reconstruct the case on every reply.
  final String summary;

  /// Title shown in any future "your past chats" list. Defaults to the
  /// first user message, trimmed.
  final String title;

  final DateTime createdAt;
  final DateTime lastMessageAt;

  const ChatSessionModel({
    this.id,
    required this.userId,
    this.petId,
    this.petName,
    this.petSpecies,
    required this.contextType,
    required this.subject,
    required this.riskLabel,
    required this.summary,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
  });

  ChatSessionModel copyWith({
    String? id,
    String? title,
    DateTime? lastMessageAt,
  }) {
    return ChatSessionModel(
      id: id ?? this.id,
      userId: userId,
      petId: petId,
      petName: petName,
      petSpecies: petSpecies,
      contextType: contextType,
      subject: subject,
      riskLabel: riskLabel,
      summary: summary,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petId': petId,
      'petName': petName,
      'petSpecies': petSpecies,
      'contextType': contextType.name,
      'subject': subject,
      'riskLabel': riskLabel,
      'summary': summary,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
    };
  }

  factory ChatSessionModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return ChatSessionModel(
      id: docId,
      userId: data['userId'] ?? '',
      petId: data['petId'],
      petName: data['petName'],
      petSpecies: data['petSpecies'],
      contextType: _parseContext(data['contextType']),
      subject: data['subject'] ?? '',
      riskLabel: data['riskLabel'] ?? '',
      summary: data['summary'] ?? '',
      title: data['title'] ?? 'Chat with the vet AI',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static ChatContextType _parseContext(dynamic raw) {
    switch (raw) {
      case 'poisoning':
        return ChatContextType.poisoning;
      case 'illness':
        return ChatContextType.illness;
      default:
        return ChatContextType.general;
    }
  }
}
