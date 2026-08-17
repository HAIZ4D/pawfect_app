import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import 'gemini_client.dart';

/// Pawfect's vet-AI chat brain.
///
/// Wraps Gemini with a veterinary-expert system instruction biased
/// toward cat health (per product spec) while still answering
/// competently for dogs. The system instruction is rebuilt per
/// session so the agent stays grounded in the actual case it was
/// invoked from — what substance the pet got into, what condition was
/// diagnosed, the current risk level, and the pet's profile — and
/// won't drift into generic "see your vet" non-answers.
///
/// Memory is multi-turn within a single instance. Construct one
/// service per chat session, replay any persisted messages via
/// [seedHistory], then call [sendMessage] for each new exchange.
class PetHealthChatService {
  PetHealthChatService({
    required ChatSessionModel session,
    List<ChatMessageModel> history = const [],
  })  : _session = session,
        _model = GeminiClient.buildModel(
          systemInstruction: Content.system(_systemInstructionFor(session)),
          generationConfig: GenerationConfig(
            temperature: 0.6,
            topK: 32,
            topP: 0.92,
            maxOutputTokens: 720,
          ),
        ) {
    _chat = _model.startChat(history: _seedFrom(history));
  }

  final ChatSessionModel _session;
  final GenerativeModel _model;
  late final ChatSession _chat;

  /// Convert persisted messages into Gemini [Content] turns so the
  /// next reply has the full thread to reason against. Skips empty
  /// turns so a half-saved message doesn't corrupt the alternation
  /// Gemini expects (user → model → user → …).
  static List<Content> _seedFrom(List<ChatMessageModel> messages) {
    final out = <Content>[];
    for (final m in messages) {
      if (m.text.trim().isEmpty) continue;
      out.add(m.role == ChatRole.user
          ? Content.text(m.text)
          : Content.model([TextPart(m.text)]));
    }
    return out;
  }

  /// Send a user turn and get the assistant's reply. Strips markdown
  /// fences and leading bullet/asterisk artifacts so the UI can render
  /// plain text without manual cleanup.
  Future<String> sendMessage(String userText) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty) {
      return _safeReply(
        'I didn\'t catch your question. Could you ask again?',
      );
    }
    try {
      final response = await _chat.sendMessage(Content.text(trimmed));
      final raw = response.text ?? '';
      return _cleanResponse(raw);
    } catch (e) {
      return _safeReply(
        'I couldn\'t reach the assessor for that reply. Check your '
        'connection and try the question again.',
      );
    }
  }

  /// Default starter prompts presented to the owner before any message
  /// is sent. Tailored to the session's context so they feel relevant.
  List<String> suggestedPrompts() {
    final petName = _session.petName ?? 'my pet';
    switch (_session.contextType) {
      case ChatContextType.poisoning:
        return [
          'Should I induce vomiting at home?',
          'What worsening signs mean I need the ER right now?',
          'How long until $petName is out of the danger window?',
          'Is activated charcoal safe to give?',
        ];
      case ChatContextType.illness:
        return [
          'What home care helps $petName most tonight?',
          'When does this usually clear up on its own?',
          'What signs mean it\'s getting worse?',
          'Any foods or activities I should avoid?',
        ];
      case ChatContextType.general:
        return [
          'What\'s a healthy weight for $petName?',
          'How do I tell if $petName is in pain?',
          'How often should I be visiting the vet?',
          'What vaccinations matter most?',
        ];
    }
  }

  /// Build the system instruction once at construction time. Pulls
  /// every available field from the session so the agent talks like it
  /// has read the chart, not like it just met the pet.
  static String _systemInstructionFor(ChatSessionModel s) {
    final speciesLabel = (s.petSpecies ?? '').trim();
    final isCat = speciesLabel.toLowerCase() == 'cat';

    final speciesGuidance = isCat
        ? '''
The pet is a cat. Lean on your feline-specific expertise: feline acetaminophen and lily toxicity are unique to cats, cats hide pain stoically, they need taurine, they can\'t metabolise NSAIDs the way dogs can, dehydration risk rises fast in kittens and seniors. When in doubt, default to cat-first guidance.'''
        : '''
Adapt your advice to the species named. You are most expert in cat health but you handle dogs and other small pets competently. Never apply cat-specific drug warnings to a dog and vice versa.''';

    final petLine = (s.petName != null && s.petName!.isNotEmpty)
        ? '${s.petName} is a ${speciesLabel.isEmpty ? "pet" : speciesLabel.toLowerCase()}.'
        : 'The pet\'s profile is incomplete.';

    final contextLine = switch (s.contextType) {
      ChatContextType.poisoning => 'The owner is consulting you because '
          '${s.petName ?? "their pet"} was exposed to ${s.subject.isEmpty ? "a toxic substance" : s.subject}. '
          'Current AI risk classification: ${s.riskLabel.isEmpty ? "not yet classified" : s.riskLabel}.',
      ChatContextType.illness => '${s.petName ?? "The pet"} has been '
          'evaluated for ${s.subject.isEmpty ? "an illness" : s.subject}. '
          'Current urgency: ${s.riskLabel.isEmpty ? "moderate" : s.riskLabel}.',
      ChatContextType.general =>
        'No active incident — answer general feline/canine health questions.',
    };

    final summaryLine = s.summary.isEmpty
        ? ''
        : '\nClinical summary so far: ${s.summary.trim()}';

    return '''
You are Pawfect's veterinary AI assistant. You speak as an experienced small-animal vet with a feline-medicine specialty. The owner is anxious — be calm, specific, and direct.

$petLine $contextLine$summaryLine

$speciesGuidance

RULES OF ENGAGEMENT
1. Stay grounded in the case above. Reference the substance, condition, or risk level when relevant. Don\'t pretend you don\'t know the context.
2. Be substantive. "See your vet" is a closing line, not the whole answer. Always explain WHY something matters before recommending action.
3. If the owner asks about a treatment or remedy, name it specifically (drug name, dose range when safe to share generically, mechanism). If it would be dangerous to specify dose, say so and explain why.
4. Flag red lines clearly. If a question implies the pet is in active distress (e.g., seizures, collapse, severe bleeding), open with "Stop reading and call the ER now." then give 2-3 stabilisation steps to do during the drive.
5. Plain text only. No markdown, no bullet stars, no bold. Short paragraphs, complete sentences.
6. Length: 80-180 words per reply. Never single-sentence brush-offs.
7. No em-dashes. Use periods or commas.
8. Never invent test results, lab values, or veterinary names. If you don\'t know, say "I don\'t know that off the top of my head — your vet can run X to find out."
9. If the owner asks something outside small-animal medicine (politics, code help, gossip), gently redirect to pet health.
10. Always end with a single clear next step the owner can take in the next hour.
''';
  }

  String _cleanResponse(String raw) {
    if (raw.trim().isEmpty) {
      return _safeReply(
        'I lost the thread there. Could you rephrase the question?',
      );
    }
    var text = raw
        .replaceAll('```', '')
        .replaceAll('**', '')
        .replaceAll('—', ', ')
        .replaceAll('  ', ' ')
        .trim();
    // Strip leading "Assistant:" / "Vet:" labels Gemini sometimes adds.
    final labelled = RegExp(r'^(assistant|vet|ai)[:\-]\s*', caseSensitive: false);
    text = text.replaceFirst(labelled, '');
    return text;
  }

  String _safeReply(String fallback) {
    return fallback;
  }
}
