import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/chat_session_model.dart';
import '../../../repositories/chat_repository.dart';
import '../../../services/pet_health_chat_service.dart';

/// Full-screen chat with the Pawfect vet AI.
///
/// The session is created by the caller (so the right clinical context
/// is attached at the start) and persisted in Firestore. This screen
/// streams the session's messages, manages a [PetHealthChatService]
/// for AI replies, and renders the editorial chat surface: cream page,
/// context strip, suggested prompts (before any user turn), message
/// bubbles, typing indicator, and an input bar.
class VetChatScreen extends StatefulWidget {
  final ChatSessionModel session;

  const VetChatScreen({super.key, required this.session});

  @override
  State<VetChatScreen> createState() => _VetChatScreenState();
}

class _VetChatScreenState extends State<VetChatScreen> {
  // ─── Palette ─────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _emergency = Color(0xFFD32F2F);

  late final ChatRepository _repo;
  late final PetHealthChatService _ai;
  late final TextEditingController _input;
  late final ScrollController _scroll;
  late final FocusNode _focus;

  List<ChatMessageModel> _messages = const [];
  bool _isReplying = false;
  bool _hasSeededHistory = false;

  @override
  void initState() {
    super.initState();
    _repo = ChatRepository();
    _ai = PetHealthChatService(session: widget.session);
    _input = TextEditingController();
    _scroll = ScrollController();
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ─────────────────────────── Send flow ────────────────────────────
  Future<void> _sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _isReplying) return;
    final sessionId = widget.session.id;
    if (sessionId == null) return;

    HapticFeedback.selectionClick();
    final uid = widget.session.userId;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    _input.clear();
    setState(() => _isReplying = true);

    final now = DateTime.now();
    final userMessage = ChatMessageModel(
      sessionId: sessionId,
      userId: uid,
      role: ChatRole.user,
      text: text,
      timestamp: now,
    );

    try {
      await _repo.appendMessage(userMessage);
      // Update the session title with the first user turn so the chat
      // is easy to find later. Keep it tight.
      if (_messages.where((m) => m.role == ChatRole.user).isEmpty) {
        final firstTitle = text.length > 70 ? '${text.substring(0, 70)}…' : text;
        await _repo.updateTitle(sessionId, firstTitle);
      }

      final reply = await _ai.sendMessage(text);

      final aiMessage = ChatMessageModel(
        sessionId: sessionId,
        userId: uid,
        role: ChatRole.assistant,
        text: reply,
        timestamp: DateTime.now(),
      );
      await _repo.appendMessage(aiMessage);
    } catch (e) {
      scaffoldMessenger.showSnackBar(_brandSnack(
        'Something went wrong sending that. Try again.',
        isError: true,
      ));
    } finally {
      if (mounted) {
        setState(() => _isReplying = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ─────────────────────────── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sessionId = widget.session.id;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      resizeToAvoidBottomInset: true,
      appBar: LiquidAppBar(
        title: 'Ask the Vet AI',
        subtitle: _appBarSubtitle(),
        icon: Icons.psychology_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.45),
          if (sessionId == null)
            _buildMissingSessionState()
          else
            StreamBuilder<List<ChatMessageModel>>(
              stream: _repo.streamMessages(sessionId),
              builder: (context, snapshot) {
                // Surface stream errors loudly. Firestore rule denials
                // arrive as exceptions here — silently falling back to
                // an empty list was how the "no messages appear" bug
                // hid itself the first time.
                if (snapshot.hasError) {
                  return _buildStreamErrorState(snapshot.error.toString());
                }

                final messages = snapshot.data ?? const <ChatMessageModel>[];
                _messages = messages;

                if (!_hasSeededHistory && messages.isNotEmpty) {
                  _hasSeededHistory = true;
                  // Already covered by constructor seed path. Marking
                  // it so future stream emissions don't redo work.
                }

                return _buildChatBody(messages);
              },
            ),
        ],
      ),
    );
  }

  String _appBarSubtitle() {
    final pet = widget.session.petName;
    final subject = widget.session.subject;
    if (pet != null && pet.isNotEmpty && subject.isNotEmpty) {
      return '$pet · $subject';
    }
    if (pet != null && pet.isNotEmpty) return pet;
    if (subject.isNotEmpty) return subject;
    return 'Feline expertise, all-pet advice';
  }

  // ─────────────────────────── Chat body ────────────────────────────
  Widget _buildChatBody(List<ChatMessageModel> messages) {
    final topInset = MediaQuery.of(context).padding.top;
    final hasMessages = messages.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, topInset + 132, 20, 16),
            children: [
              _buildContextStrip(),
              const SizedBox(height: 22),
              if (!hasMessages) _buildIntro(),
              if (!hasMessages) const SizedBox(height: 16),
              if (!hasMessages) _buildSuggestedPrompts(),
              ...messages.map(_buildMessageBubble),
              if (_isReplying) _buildTypingBubble(),
              const SizedBox(height: 12),
            ],
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  // ─────────────────────────── Context strip ────────────────────────
  Widget _buildContextStrip() {
    final s = widget.session;
    final eyebrow = switch (s.contextType) {
      ChatContextType.poisoning => 'TOXIN EXPOSURE',
      ChatContextType.illness => 'ILLNESS REVIEW',
      ChatContextType.general => 'GENERAL CARE',
    };
    final risk = s.riskLabel.toUpperCase().trim();
    final hasRisk = risk.isNotEmpty;
    final riskColor = _riskColor(risk);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF6E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (hasRisk)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: riskColor.withOpacity(0.32),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    risk,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: riskColor,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (s.subject.isNotEmpty)
            Text(
              s.subject,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          if (s.petName != null && s.petName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${s.petName}${s.petSpecies != null && s.petSpecies!.isNotEmpty ? " · ${s.petSpecies}" : ""}',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _inkSoft.withOpacity(0.95),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── Intro ────────────────────────────────
  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'VET AI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 22, height: 1, color: _hairline),
            const SizedBox(width: 12),
            const Text(
              'CAT SPECIALTY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _inkSoft,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Ask anything.',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.1,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'I\'ve read the case. Specific questions get specific answers.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: PawfectColors.pawfectOrange.withOpacity(0.92),
            letterSpacing: -0.2,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Suggested prompts ────────────────────
  Widget _buildSuggestedPrompts() {
    final prompts = _ai.suggestedPrompts();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TRY',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: _inkSoft,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 22, height: 1, color: _hairline),
          ],
        ),
        const SizedBox(height: 10),
        ...prompts.map(_buildPromptCard),
      ],
    );
  }

  Widget _buildPromptCard(String prompt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _sendText(prompt),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: PawfectColors.pawfectOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      letterSpacing: -0.1,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: _inkSoft.withOpacity(0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Message bubble ───────────────────────
  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.role == ChatRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAiAvatar(),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: isUser
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            PawfectColors.pawfectOrange,
                            Color(0xFFFFB347),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PawfectColors.pawfectOrange
                                .withOpacity(0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      )
                    : BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFFFF6E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.88),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUser ? Colors.white : _ink.withOpacity(0.92),
                    fontWeight: FontWeight.w500,
                    height: 1.55,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: PawfectColors.pawfectOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: PawfectColors.pawfectOrange.withOpacity(0.32),
          width: 1.2,
        ),
      ),
      child: const Icon(
        Icons.psychology_rounded,
        color: PawfectColors.pawfectOrange,
        size: 16,
      ),
    );
  }

  // ─────────────────────────── Typing bubble ────────────────────────
  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF6E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.88),
                width: 1.2,
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Input bar ────────────────────────────
  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: PawfectColors.pawfectCream.withOpacity(0.96),
          border: const Border(
            top: BorderSide(color: _hairline, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF6E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.88),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  enabled: !_isReplying,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _ink,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText: _isReplying
                        ? 'Listening…'
                        : 'Ask a follow-up',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: _inkSoft.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(
              enabled: !_isReplying,
              onTap: () => _sendText(_input.text),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Stream error ────────────────────────
  Widget _buildStreamErrorState(String error) {
    final topInset = MediaQuery.of(context).padding.top;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF6E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.88),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _emergency,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CHAT UNAVAILABLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'We can\'t load this chat.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you just updated the app, your Firestore security rules may need to be redeployed. Otherwise check your connection and try again.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft.withOpacity(0.95),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _inkSoft.withOpacity(0.85),
                    height: 1.4,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Missing session ──────────────────────
  Widget _buildMissingSessionState() {
    final topInset = MediaQuery.of(context).padding.top;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF6E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.88),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Text(
            'Chat session unavailable. Please return to the previous screen and tap "Ask the Vet AI" again.',
            style: TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _ink,
              height: 1.55,
            ),
          ),
        ),
      ),
    );
  }

  SnackBar _brandSnack(String message, {bool isError = false}) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? _emergency : _ink,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.1,
        ),
      ),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Color _riskColor(String label) {
    switch (label) {
      case 'EMERGENCY':
        return _emergency;
      case 'HIGH':
        return const Color(0xFFE65100);
      case 'MODERATE':
        return const Color(0xFFF57C00);
      case 'LOW':
        return const Color(0xFF2E8A68);
      default:
        return _inkSoft;
    }
  }
}

// ─────────────────────────── Send button ───────────────────────────
class _SendButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  PawfectColors.pawfectOrange,
                  Color(0xFFFFB347),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: PawfectColors.pawfectOrange.withOpacity(0.36),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Typing dots ───────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 14,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_ctl.value + i * 0.18) % 1.0;
              final scale = 0.7 + 0.6 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: i == 1 ? 4 : 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          PawfectColors.pawfectOrange.withOpacity(0.65 + 0.35 * scale.clamp(0.0, 1.0)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
