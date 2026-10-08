import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// A single message in the AI Assistant conversation.
class AiChatMessage {
  final String text;
  final bool fromBot;
  final DateTime? createdAt;

  const AiChatMessage(this.text, this.fromBot, {this.createdAt});

  factory AiChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
        return AiChatMessage(
      data['text'] ?? '',
      data['fromBot'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AiAssistantService {
  // TODO: replace with your own free Groq API key from
  // https://console.groq.com/keys — no credit card required, and
  // Groq's free tier has proven far more reliably provisioned than
  // Gemini's for new Google accounts.
  static const String _apiKey =
    String.fromEnvironment('GROQ_API_KEY');
  // llama-3.3-70b-versatile was decommissioned by Groq on Aug 16, 2026.
  // Switched to their official recommended replacement.
  static const String _model = 'openai/gpt-oss-120b';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _historyCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('ai_conversations').doc(uid).collection('messages');
  }

  /// Live stream of the current user's saved conversation, oldest
  /// first, so the chat screen can render it top-to-bottom exactly
  /// like it was left.
  Stream<List<AiChatMessage>> streamChatHistory() {
    final collection = _historyCollection;
    if (collection == null) return const Stream.empty();

    return collection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AiChatMessage.fromFirestore).toList());
  }

  /// Persists a single message (from the farmer or the assistant) to
  /// Firestore so the conversation survives closing the app.
  Future<void> saveMessage(AiChatMessage message) async {
    final collection = _historyCollection;
    if (collection == null) return; // not signed in — skip silently
    await collection.add({
      'text': message.text,
      'fromBot': message.fromBot,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes the current user's entire saved conversation — used by
  /// the "New Chat" action.
  Future<void> clearHistory() async {
    final collection = _historyCollection;
    if (collection == null) return;
    final existing = await collection.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
  }

  static const String _systemPrompt = '''
You are the AgriVision Assistant, a friendly and knowledgeable agricultural
helper built into the AgriVision AI app used by farmers in India. You help
with crop disease symptoms, treatment guidance, weather-related farming
decisions, and general crop-care questions.

Rules you must follow:
- Keep answers short and practical (2-4 sentences) — farmers are reading
  this on a small phone screen, often in bright sunlight.
- If the farmer describes symptoms that sound like a specific disease,
  name your best guess but always recommend they use the app's camera
  scanner for a confirmed diagnosis, since you cannot see their crop.
- Be supportive and plain-spoken. Avoid jargon; explain any technical term
  you use in simple words.
- CRITICAL LANGUAGE RULE: Always respond in the SAME language as the farmer's
  MOST RECENT message only — English, Hindi, or Marathi. Ignore what language
  earlier messages in this conversation were in. If the farmer's last message
  is in English, reply only in English, even if you replied in Hindi or
  Marathi earlier in this same conversation. If their last message is in
  Hindi, reply only in Hindi. Never mix two languages in one reply, and never
  reply in a language different from the farmer's most recent message.
- You are not a substitute for a licensed agronomist for serious or
  unclear cases; suggest local agricultural extension services when a
  situation sounds severe or uncertain.
''';

  /// Sends the full conversation so far (for context) plus the new
  /// user message, and returns the assistant's reply.
  Future<String> sendMessage({
    required List<AiChatMessage> history,
    required String newMessage,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
    ];

    for (final msg in history) {
      messages.add({
        'role': msg.fromBot ? 'assistant' : 'user',
        'content': msg.text,
      });
    }
    messages.add({'role': 'user', 'content': newMessage});

    final uri = Uri.parse(_baseUrl);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 300,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI Assistant request failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('AI Assistant returned no response.');
    }

    return (choices[0]['message']['content'] as String).trim();
  }
}