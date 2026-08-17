import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

/// CRUD + streaming for vet-AI chat.
///
/// Layout:
///   chat_sessions/{sessionId}
///     userId, petId, contextType, subject, riskLabel, summary, …
///     messages/{messageId}
///       userId, role, text, timestamp
///
/// Owner is identified by `userId` on both docs. Rules enforce that
/// `request.auth.uid == userId` for every operation.
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('chat_sessions');

  CollectionReference<Map<String, dynamic>> _messagesIn(String sessionId) =>
      _sessions.doc(sessionId).collection('messages');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('ChatRepository requires an authenticated user.');
    }
    return uid;
  }

  /// Create a new chat session anchored to a specific clinical context.
  /// Returns the session with its assigned [ChatSessionModel.id].
  Future<ChatSessionModel> createSession(ChatSessionModel session) async {
    final uid = _requireUid();
    if (session.userId != uid) {
      throw StateError('Cannot create a chat session for another user.');
    }
    final doc = await _sessions.add(session.toFirestore());
    return session.copyWith(id: doc.id);
  }

  /// Append a message to a session and bump the session's
  /// `lastMessageAt`. Returns the message with its assigned id.
  Future<ChatMessageModel> appendMessage(ChatMessageModel message) async {
    final uid = _requireUid();
    if (message.userId != uid) {
      throw StateError('Cannot post a chat message as another user.');
    }
    final ref = await _messagesIn(message.sessionId).add(message.toFirestore());
    await _sessions.doc(message.sessionId).update({
      'lastMessageAt': Timestamp.fromDate(message.timestamp),
    });
    return message.copyWith(id: ref.id);
  }

  /// Stream messages in a session ordered by send time. The stream is
  /// scoped to the current authenticated user — rules deny anything
  /// else.
  Stream<List<ChatMessageModel>> streamMessages(String sessionId) {
    return _messagesIn(sessionId)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Update the title (typically the first user message, trimmed).
  Future<void> updateTitle(String sessionId, String title) {
    return _sessions.doc(sessionId).update({'title': title});
  }
}
