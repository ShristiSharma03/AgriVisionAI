import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One saved AI Assistant conversation thread.
class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;

  ChatSession({required this.id, required this.title, required this.updatedAt});

  factory ChatSession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatSession(
      id: doc.id,
      title: data['title'] ?? 'New Chat',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// One message within a chat session, persisted to Firestore.
class StoredChatMessage {
  final String id;
  final String text;
  final bool fromBot;
  final DateTime createdAt;

  StoredChatMessage({required this.id, required this.text, required this.fromBot, required this.createdAt});

  factory StoredChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StoredChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      fromBot: data['fromBot'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AiChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _sessionsCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User must be signed in.');
    return _firestore.collection('users').doc(uid).collection('ai_chat_sessions');
  }

  /// Live stream of the current user's chat sessions, most recently
  /// updated first — this is what powers the history drawer.
  Stream<List<ChatSession>> streamSessions() {
    return _sessionsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ChatSession.fromFirestore).toList());
  }

  /// Live stream of messages within a single session, oldest first.
  Stream<List<StoredChatMessage>> streamMessages(String sessionId) {
    return _sessionsCollection
        .doc(sessionId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StoredChatMessage.fromFirestore).toList());
  }

  /// Creates a new, empty chat session and returns its ID.
  Future<String> createSession() async {
    final doc = await _sessionsCollection.add({
      'title': 'New Chat',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Adds a message to a session. If this is the first user message
  /// in the session, also sets the session's title from it (so the
  /// history drawer shows a meaningful label, like ChatGPT/Claude do).
  Future<void> addMessage({
    required String sessionId,
    required String text,
    required bool fromBot,
  }) async {
    final sessionRef = _sessionsCollection.doc(sessionId);

    await sessionRef.collection('messages').add({
      'text': text,
      'fromBot': fromBot,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await sessionRef.update({'updatedAt': FieldValue.serverTimestamp()});

    if (!fromBot) {
      final session = await sessionRef.get();
      final currentTitle = session.data()?['title'];
      if (currentTitle == null || currentTitle == 'New Chat') {
        final shortTitle = text.length > 40 ? '${text.substring(0, 40)}...' : text;
        await sessionRef.update({'title': shortTitle});
      }
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final sessionRef = _sessionsCollection.doc(sessionId);
    final messages = await sessionRef.collection('messages').get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
    await sessionRef.delete();
  }
}