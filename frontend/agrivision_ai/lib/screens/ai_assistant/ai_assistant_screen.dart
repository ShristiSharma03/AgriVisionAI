import 'package:flutter/material.dart';
import '../../core/services/ai_assistant_service.dart';
import '../../core/services/ai_chat_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';
import '../camera/camera_capture_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _textFieldFocusNode = FocusNode();
  final AiAssistantService _aiService = AiAssistantService();
  final AiChatService _chatService = AiChatService();
  final VoiceService _voiceService = VoiceService();

  String? _sessionId;
  bool _isTyping = false;
  bool _isInitializing = true;

  bool _isListening = false;
  bool _isSpeakingReply = false;
  String _voiceLanguageCode = 'en';
  String? _lastBotReply;

  @override
  void initState() {
    super.initState();
    _loadVoiceLanguage();
    _initSession();
    // Typing into the input field is a clear signal the farmer is done
    // listening to any previous reply — stop it immediately rather than
    // letting it keep talking over them while they type.
    _textFieldFocusNode.addListener(() {
      if (_textFieldFocusNode.hasFocus && _isSpeakingReply) {
        _voiceService.stopSpeaking();
        setState(() => _isSpeakingReply = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _loadVoiceLanguage() async {
    final code = await _voiceService.getSavedLanguageCode();
    if (mounted) setState(() => _voiceLanguageCode = code);
  }

  Future<void> _selectVoiceLanguage(String code) async {
    setState(() => _voiceLanguageCode = code);
    await _voiceService.saveLanguageCode(code);
  }

  Future<void> _toggleVoiceInput() async {
    // If the AI is currently reading a reply aloud, tapping the mic
    // interrupts it immediately — the farmer wants to speak now, so
    // don't make them wait for the AI to finish talking first.
    if (_isSpeakingReply) {
      await _voiceService.stopSpeaking();
      setState(() => _isSpeakingReply = false);
    }

    if (_isListening) {
      // Mark listening as stopped immediately (before awaiting the
      // actual stop call) so the onResult guard below starts ignoring
      // results right away. The speech engine can occasionally send
      // one more "corrected" transcript slightly after stop() is
      // called, sometimes shorter than what was already captured —
      // without this guard, that stray result was overwriting the
      // farmer's full spoken text with just a fragment.
      setState(() => _isListening = false);
      await _voiceService.stopListening();
      return;
    }

    final started = await _voiceService.startListening(
      languageCode: _voiceLanguageCode,
      onResult: (text) {
        if (!_isListening) return; // ignore stray results after manual stop
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('ai_voice_input_error').replaceAll('{error}', '$error'))),
          );
        }
      },
    );

    if (!started) return;

    setState(() => _isListening = true);
  }

  Future<void> _toggleSpeakLastReply() async {
    if (_isSpeakingReply) {
      await _voiceService.stopSpeaking();
      setState(() => _isSpeakingReply = false);
      return;
    }
    if (_lastBotReply == null || _lastBotReply!.trim().isEmpty) return;

    setState(() => _isSpeakingReply = true);
    // The bot's reply already comes back in whichever language the
    // farmer spoke/typed in, so using the same voice-language code
    // for playback is a reasonable match — unlike the Detection AI's
    // static English-only content, this is genuinely accurate.
    await _voiceService.speak(_lastBotReply!, languageCode: _voiceLanguageCode);
    if (mounted) setState(() => _isSpeakingReply = false);
  }

  Future<void> _initSession() async {
    // Always start a fresh conversation when the AI Assistant screen
    // opens — the previous conversation stays saved and accessible
    // in the history drawer, it just isn't auto-resumed.
    await _startNewChat();
  }

  Future<void> _startNewChat() async {
    final newId = await _chatService.createSession();
    await _chatService.addMessage(sessionId: newId, text: context.tr('ai_welcome_message'), fromBot: true);
    if (!mounted) return;
    setState(() {
      _sessionId = newId;
      _isInitializing = false;
      _lastBotReply = null;
    });
    // Close the drawer if this was triggered from "New Chat" while
    // browsing history — guarded since on cold start there's no
    // Scaffold/drawer to close yet.
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  void _openSession(String sessionId) {
    setState(() {
      _sessionId = sessionId;
      _lastBotReply = null;
    });
    Navigator.of(context).pop(); // close drawer
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

    Future<void> _send([String? quickText]) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty || _isTyping || _sessionId == null) return;

    // Sending a message is a clear signal the farmer is done — stop
    // both the AI's voice (if it's mid-reply) and the microphone (if
    // still listening) immediately. Without stopping the mic
    // specifically, it kept firing onResult in the background even
    // after the text field was cleared, silently refilling it with
    // whatever it was still hearing.
    if (_isSpeakingReply) {
      await _voiceService.stopSpeaking();
      if (mounted) setState(() => _isSpeakingReply = false);
    }
    if (_isListening) {
      setState(() => _isListening = false);
      await _voiceService.stopListening();
    }

    final sessionId = _sessionId!;
    // Grab current history (for LLM context) before saving the new message.
    final historySoFar = await _chatService.streamMessages(sessionId).first;
    final aiHistory = historySoFar.map((m) => AiChatMessage(m.text, m.fromBot)).toList();

    _controller.clear();
    setState(() => _isTyping = true);
    await _chatService.addMessage(sessionId: sessionId, text: text, fromBot: false);
    _scrollToBottom();

    try {
      final reply = await _aiService.sendMessage(history: aiHistory, newMessage: text);
      await _chatService.addMessage(sessionId: sessionId, text: reply, fromBot: true);
      _lastBotReply = reply;
    } catch (e) {
      if (!mounted) return;
      await _chatService.addMessage(
        sessionId: sessionId,
        text: context.tr('ai_connection_error').replaceAll('{error}', '$e'),
        fromBot: true,
      );
    }
    if (!mounted) return;
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: const Icon(Icons.smart_toy_outlined, color: AppColors.greenPale, size: 15),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('ai_assistant_name'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(context.tr('ai_assistant_status'), style: const TextStyle(fontSize: 8.5, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: context.tr('new_chat'),
            onPressed: _isInitializing ? null : _startNewChat,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: AppColors.greenMain),
                    const SizedBox(width: 8),
                    Text(context.tr('chat_history'), style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<ChatSession>>(
                  stream: _chatService.streamSessions(),
                  builder: (context, snapshot) {
                    final sessions = snapshot.data ?? [];
                    if (sessions.isEmpty) {
                      return Center(
                        child: Text(context.tr('no_conversations_yet'), style: theme.textTheme.bodyMedium),
                      );
                    }
                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isActive = session.id == _sessionId;
                        return ListTile(
                          leading: Icon(Icons.chat_bubble_outline, size: 18, color: isActive ? AppColors.greenMain : theme.textTheme.bodySmall?.color),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive ? AppColors.greenMain : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 17),
                            onPressed: () async {
                              await _chatService.deleteSession(session.id);
                              if (session.id == _sessionId) {
                                final remaining = await _chatService.streamSessions().first;
                                if (remaining.isNotEmpty) {
                                  setState(() {
                                    _sessionId = remaining.first.id;
                                    _lastBotReply = null;
                                  });
                                } else {
                                  await _startNewChat();
                                }
                              }
                            },
                          ),
                          selected: isActive,
                          onTap: () => _openSession(session.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isInitializing || _sessionId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<StoredChatMessage>>(
                    stream: _chatService.streamMessages(_sessionId!),
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? [];
                      _scrollToBottom();
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        itemCount: messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _BotBubble(text: context.tr('typing_indicator'), theme: theme);
                          }
                          final msg = messages[index];
                          return msg.fromBot
                              ? _BotBubble(text: msg.text, theme: theme)
                              : _UserBubble(text: msg.text);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Row(
                    children: [
                      ...kVoiceLanguages.map((lang) {
                        final selected = lang.code == _voiceLanguageCode;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(lang.label, style: const TextStyle(fontSize: 10)),
                            selected: selected,
                            onSelected: (_) => _selectVoiceLanguage(lang.code),
                            selectedColor: AppColors.greenMain,
                            labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }),
                      const Spacer(),
                      if (_lastBotReply != null)
                        IconButton(
                          icon: Icon(_isSpeakingReply ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 20, color: AppColors.greenMain),
                          tooltip: _isSpeakingReply ? context.tr('stop_reading') : context.tr('read_last_reply_aloud'),
                          onPressed: _toggleSpeakLastReply,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        _QuickReplyChip(
                          label: context.tr('open_scanner'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
                          ),
                        ),
                        _QuickReplyChip(
                          label: context.tr('treatment_tips_chip'),
                          onTap: () => _send(context.tr('treatment_tips_query')),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _textFieldFocusNode,
                            decoration: InputDecoration(
                              hintText: _isListening ? context.tr('listening_hint') : context.tr('type_question_hint'),
                              border: InputBorder.none,
                              filled: false,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isListening ? Icons.stop : Icons.mic_none, color: _isListening ? AppColors.red : AppColors.greenMain),
                          onPressed: _toggleVoiceInput,
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(color: AppColors.greenMain, shape: BoxShape.circle),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.send, color: Colors.white, size: 15),
                            onPressed: () => _send(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _BotBubble({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.greenDark,
            child: const Icon(Icons.smart_toy_outlined, color: AppColors.greenPale, size: 13),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border.all(color: theme.dividerColor),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                  bottomLeft: Radius.circular(3),
                ),
              ),
              child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: const BoxDecoration(
                color: AppColors.greenMain,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(3),
                ),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.greenLightBg, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: const TextStyle(color: AppColors.greenDark, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}