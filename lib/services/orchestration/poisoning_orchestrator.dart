import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/pet_model.dart';
import '../gemini_client.dart';
import 'agent_runner.dart';
import 'agent_stage.dart';

/// Orchestrated poisoning risk assessment pipeline.
///
/// Replaces the single-call `AIPoisoningAssessmentService.assessPoisoningRisk`
/// with five focused agents. Each agent has one job, a narrow prompt,
/// and a structured JSON output. The synthesis agent assembles the
/// final result in the legacy `PoisoningAssessmentResult.fromJson`
/// shape so existing UI and PDF code keep working unchanged.
///
/// Pipeline:
///   1. ToxicologyAgent          — substance + pet → toxicology profile
///   2. SymptomCorrelationAgent  — observed vs expected symptoms
///   3. TimelineAgent            — time since ingestion + critical window
///   4. CriticAgent              — challenges unsupported claims
///   5. SynthesisAgent           — final structured assessment
///
/// Stages 1, 2 and 3 run in parallel since none depends on the others.
/// Stages 4 and 5 run sequentially.
class PoisoningOrchestrator {
  PoisoningOrchestrator({this.progress});

  final ValueNotifier<OrchestrationProgress>? progress;

  static const List<AgentStage> defaultStages = [
    AgentStage(
      key: 'toxicology',
      title: 'Reading toxicology',
      subtitle: 'Mechanism, weight-adjusted risk.',
    ),
    AgentStage(
      key: 'symptom-correlation',
      title: 'Correlating symptoms',
      subtitle: 'Observed vs expected for this substance.',
    ),
    AgentStage(
      key: 'timeline',
      title: 'Mapping the window',
      subtitle: 'Time since exposure, urgency curve.',
    ),
    AgentStage(
      key: 'critic',
      title: 'Challenging the assessment',
      subtitle: 'Demoting unsupported claims.',
    ),
    AgentStage(
      key: 'synthesis',
      title: 'Assembling triage',
      subtitle: 'Risk, immediate actions, prognosis.',
    ),
  ];

  /// Run the full pipeline. Returns a map shaped for
  /// `PoisoningAssessmentResult.fromJson` so callers can hydrate the
  /// existing model unchanged. Extra fields (`toxicology`,
  /// `symptomCorrelation`, `timeline`, `criticNotes`) are appended for
  /// debugging and richer UI later.
  Future<Map<String, dynamic>> assess({
    required String substanceName,
    required String substanceDescription,
    required PetModel pet,
    required List<String> symptoms,
    required String amountIngested,
    required Duration timeSinceIngestion,
  }) async {
    final model = GeminiClient.buildModel(
      generationConfig: GenerationConfig(
        temperature: 0.5,
        topK: 32,
        topP: 0.9,
        maxOutputTokens: 1100,
      ),
    );

    _seedProgress();

    // Stages 1-3 in parallel. Started together, awaited separately.
    _markRunning(0);
    _markRunning(1);
    _markRunning(2);
    final toxFuture = _runToxicologyAgent(
      model: model,
      substanceName: substanceName,
      substanceDescription: substanceDescription,
      pet: pet,
      amountIngested: amountIngested,
    );
    final correlationFuture = _runSymptomCorrelationAgent(
      model: model,
      substanceName: substanceName,
      symptoms: symptoms,
      pet: pet,
    );
    final timelineFuture = _runTimelineAgent(
      model: model,
      substanceName: substanceName,
      timeSinceIngestion: timeSinceIngestion,
    );

    final toxicology = await toxFuture;
    _markCompleted(0);
    final correlation = await correlationFuture;
    _markCompleted(1);
    final timeline = await timelineFuture;
    _markCompleted(2);

    // Stage 4: Critic.
    _markRunning(3);
    final critique = await _runCriticAgent(
      model: model,
      pet: pet,
      substanceName: substanceName,
      toxicology: toxicology,
      correlation: correlation,
      timeline: timeline,
    );
    _markCompleted(3);

    // Stage 5: Synthesis.
    _markRunning(4);
    final synthesis = await _runSynthesisAgent(
      model: model,
      pet: pet,
      substanceName: substanceName,
      amountIngested: amountIngested,
      symptoms: symptoms,
      timeSinceIngestion: timeSinceIngestion,
      toxicology: toxicology,
      correlation: correlation,
      timeline: timeline,
      critique: critique,
    );
    _markCompleted(4);

    return {
      ...synthesis,
      'toxicology': toxicology,
      'symptomCorrelation': correlation,
      'timeline': timeline,
      'criticNotes': _stringList(critique['notes']),
    };
  }

  // ─── Stage 1: Toxicology agent ───────────────────────────────────
  Future<Map<String, dynamic>> _runToxicologyAgent({
    required GenerativeModel model,
    required String substanceName,
    required String substanceDescription,
    required PetModel pet,
    required String amountIngested,
  }) async {
    final speciesAdvice = pet.species.toLowerCase() == 'cat'
        ? 'CAT-SPECIFIC NOTE: Cats lack glucuronyl transferase, making many drugs (acetaminophen, ibuprofen, aspirin) far more dangerous than for dogs. Lilies are uniquely nephrotoxic to cats. Essential oils are not safely metabolised.'
        : 'Adapt mechanism to the species named. Dogs metabolise some compounds (chocolate theobromine) differently from cats.';

    final prompt = '''
You are the TOXICOLOGY agent in a multi-agent veterinary poisoning pipeline. You provide the pharmacological profile only. You do NOT recommend treatment, classify final risk, or write owner-facing copy. Other agents do that.

PATIENT: ${pet.species}${pet.breed.isNotEmpty ? ", ${pet.breed}" : ""}, weight ${pet.weight ?? "unknown"} kg, ${pet.getAge()}.
SUBSTANCE: $substanceName.
SUBSTANCE BACKGROUND: $substanceDescription.
AMOUNT INGESTED (owner-reported): $amountIngested.

$speciesAdvice

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "mechanismOfAction": "<one sentence on how this substance harms this species>",
  "targetSystems": ["nervous", "renal", "hepatic", "cardiovascular", "gastrointestinal", "respiratory", "haematological", "dermal"],
  "lethalDoseEstimate": "<rough toxic threshold for this species/weight, plain language, or 'unknown' if not well-characterised>",
  "weightAdjustedRisk": "MINIMAL|MODERATE|HIGH|EXTREME",
  "antidoteOrCounter": "<specific antidote if one exists, e.g. 'N-acetylcysteine for acetaminophen', or 'none specific' if not>",
  "keyConcerns": ["<2-4 specific clinical risks for this exposure>"]
}

If the substance is genuinely not toxic at the reported dose for this species, set weightAdjustedRisk to MINIMAL and say so in keyConcerns.
''';

    return AgentRunner.runJsonObject(
      model: model,
      prompt: prompt,
      fallback: {
        'mechanismOfAction': 'Toxicology unavailable.',
        'targetSystems': const <String>[],
        'lethalDoseEstimate': 'unknown',
        'weightAdjustedRisk': 'MODERATE',
        'antidoteOrCounter': 'none specific',
        'keyConcerns': const <String>[],
      },
    );
  }

  // ─── Stage 2: Symptom correlation agent ──────────────────────────
  Future<Map<String, dynamic>> _runSymptomCorrelationAgent({
    required GenerativeModel model,
    required String substanceName,
    required List<String> symptoms,
    required PetModel pet,
  }) async {
    final symptomList = symptoms.isEmpty
        ? '(none reported)'
        : symptoms.map((s) => '- $s').join('\n');

    final prompt = '''
You are the SYMPTOM CORRELATION agent in a multi-agent veterinary poisoning pipeline. You compare the symptoms the owner observed to the symptoms expected for $substanceName in a ${pet.species}. You do NOT diagnose or classify risk.

OBSERVED SYMPTOMS:
$symptomList

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "expectedSymptoms": ["<list of symptoms typical for this exposure in this species>"],
  "matchedObserved": ["<observed symptoms that match expected>"],
  "unexplainedObserved": ["<observed symptoms that don't match this exposure>"],
  "missingExpected": ["<expected symptoms the owner has NOT reported, which may appear>"],
  "severityIndicator": "MILD|MODERATE|SEVERE",
  "phase": "early|peak|late|unclear",
  "summary": "<one sentence on the symptom picture>"
}

Be honest. If no symptoms have been observed yet, set severityIndicator to MILD and phase to "early".
''';

    return AgentRunner.runJsonObject(
      model: model,
      prompt: prompt,
      fallback: {
        'expectedSymptoms': const <String>[],
        'matchedObserved': const <String>[],
        'unexplainedObserved': const <String>[],
        'missingExpected': const <String>[],
        'severityIndicator': 'MODERATE',
        'phase': 'unclear',
        'summary': 'Symptom correlation unavailable.',
      },
    );
  }

  // ─── Stage 3: Timeline agent ─────────────────────────────────────
  Future<Map<String, dynamic>> _runTimelineAgent({
    required GenerativeModel model,
    required String substanceName,
    required Duration timeSinceIngestion,
  }) async {
    final minutes = timeSinceIngestion.inMinutes;
    final hours = timeSinceIngestion.inHours;

    final prompt = '''
You are the TIMELINE agent in a multi-agent veterinary poisoning pipeline. Given the substance and elapsed time, you describe the critical action window. You do NOT recommend specific treatments.

SUBSTANCE: $substanceName.
TIME SINCE EXPOSURE: $minutes minutes ($hours hours).

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "phase": "absorption|early-clinical|peak-effect|late-effect|recovery",
  "decontaminationStillUseful": true_or_false,
  "minutesRemainingForDecontamination": <number, 0 if window closed>,
  "expectedNextEvents": ["<what typically happens in the next 0-2 hours>"],
  "treatmentUrgency": "MINUTES|HOURS|DAYS|MONITOR",
  "summary": "<one sentence framing the timeline>"
}

Decontamination (induced vomiting, activated charcoal) is generally only effective within 30-60 minutes of ingestion for most oral toxins. Use this to set decontaminationStillUseful and minutesRemainingForDecontamination.
''';

    return AgentRunner.runJsonObject(
      model: model,
      prompt: prompt,
      fallback: {
        'phase': 'unknown',
        'decontaminationStillUseful': false,
        'minutesRemainingForDecontamination': 0,
        'expectedNextEvents': const <String>[],
        'treatmentUrgency': 'HOURS',
        'summary': 'Timeline analysis unavailable.',
      },
    );
  }

  // ─── Stage 4: Critic agent ───────────────────────────────────────
  Future<Map<String, dynamic>> _runCriticAgent({
    required GenerativeModel model,
    required PetModel pet,
    required String substanceName,
    required Map<String, dynamic> toxicology,
    required Map<String, dynamic> correlation,
    required Map<String, dynamic> timeline,
  }) async {
    final prompt = '''
You are the CRITIC agent in a multi-agent veterinary poisoning pipeline. Your job is to challenge the prior outputs. Find unsupported claims, flag possible hallucinations, and score overall confidence. This is the hallucination guard for the whole pipeline.

PATIENT: ${pet.species}, weight ${pet.weight ?? "unknown"} kg.
SUBSTANCE: $substanceName.

TOXICOLOGY: ${_encodeJson(toxicology)}
SYMPTOM CORRELATION: ${_encodeJson(correlation)}
TIMELINE: ${_encodeJson(timeline)}

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "flags": ["<concrete inconsistency or unsupported claim>"],
  "demoteRisk": true_or_false,
  "elevateRisk": true_or_false,
  "rationale": "<one sentence on why risk should be demoted or elevated>",
  "pipelineConfidence": <number 0..1>,
  "notes": ["<short final notes for the synthesis agent>"]
}

RULES:
- If toxicology says weightAdjustedRisk=MINIMAL but timeline says treatmentUrgency=MINUTES, flag the inconsistency.
- If the species is cat but the toxicology mechanism is dog-only (or vice versa), flag and set elevateRisk to false.
- If symptom correlation shows zero matchedObserved AND many missingExpected, demote slightly (the pet may be in the absorption phase, but be honest about the uncertainty).
- pipelineConfidence:
  - 0.85+: all three agents converge, mechanism is well-known, symptoms match
  - 0.6-0.85: some disagreement or substance is uncommon
  - <0.6: significant gaps or inconsistencies
''';

    return AgentRunner.runJsonObject(
      model: model,
      prompt: prompt,
      fallback: {
        'flags': const <String>[],
        'demoteRisk': false,
        'elevateRisk': false,
        'rationale': '',
        'pipelineConfidence': 0.65,
        'notes': const <String>[],
      },
    );
  }

  // ─── Stage 5: Synthesis agent ────────────────────────────────────
  Future<Map<String, dynamic>> _runSynthesisAgent({
    required GenerativeModel model,
    required PetModel pet,
    required String substanceName,
    required String amountIngested,
    required List<String> symptoms,
    required Duration timeSinceIngestion,
    required Map<String, dynamic> toxicology,
    required Map<String, dynamic> correlation,
    required Map<String, dynamic> timeline,
    required Map<String, dynamic> critique,
  }) async {
    final symptomList = symptoms.isEmpty
        ? '(none reported)'
        : symptoms.map((s) => '- $s').join('\n');

    final prompt = '''
You are the SYNTHESIS agent at the end of a multi-agent veterinary poisoning pipeline. Combine the prior agent outputs into the final owner-facing risk assessment. You do not invent new claims — you draw from the structured outputs below and write the human copy.

PATIENT: ${pet.name}, a ${pet.species}${pet.breed.isNotEmpty ? " (${pet.breed})" : ""}, weight ${pet.weight ?? "unknown"} kg, ${pet.getAge()}.
SUBSTANCE: $substanceName.
AMOUNT: $amountIngested.
TIME SINCE EXPOSURE: ${timeSinceIngestion.inMinutes} minutes (${timeSinceIngestion.inHours} hours).
OWNER SAW: $symptomList

UPSTREAM AGENTS:
TOXICOLOGY: ${_encodeJson(toxicology)}
SYMPTOM CORRELATION: ${_encodeJson(correlation)}
TIMELINE: ${_encodeJson(timeline)}
CRITIC: ${_encodeJson(critique)}

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "riskLevel": "low|moderate|high|emergency",
  "confidenceScore": <integer 0..100>,
  "urgencyMessage": "<1-2 sentence headline. Direct. No em-dashes.>",
  "detailedExplanation": "<3-4 plain-language sentences explaining what happened, why it matters for THIS pet, and what comes next>",
  "immediateActions": [
    "<specific verb-first action 1>",
    "<action 2>",
    "<action 3>"
  ],
  "symptomsToMonitor": ["<symptom 1>", "<symptom 2>", "<symptom 3>"],
  "requiresVetVisit": true_or_false,
  "requiresEmergencyVet": true_or_false,
  "timeWindow": "<plain-language window, e.g. 'Within 30 minutes', 'Next 2 hours', 'Monitor for 24 hours'>",
  "prognosisIfTreated": "<one sentence on expected outcome with prompt vet care>",
  "prognosisIfUntreated": "<one sentence on what may happen without care>",
  "petOwnerGuidance": "<2-3 supportive sentences for the owner. Acknowledge concern, give clear next step.>"
}

RULES:
- Riskboard: weightAdjustedRisk + treatmentUrgency + symptom severityIndicator determine riskLevel. EMERGENCY only if toxicology says HIGH/EXTREME and timeline says MINUTES OR severityIndicator is SEVERE.
- confidenceScore = round(pipelineConfidence * 100). Never above 95.
- If critic.demoteRisk is true, drop one level.
- If critic.elevateRisk is true, raise one level.
- 3-5 immediateActions. Each must be a CONCRETE action. No "see a vet" alone.
- For EMERGENCY: immediateAction[0] must be "Call the emergency vet now while preparing to travel."
- symptomsToMonitor must include the missingExpected items from the correlation agent.
- No em-dashes. No emojis. No markdown. Plain text only.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text ?? '';
    final parsed = AgentRunner.parseJsonObject(raw, fallback: {
      'riskLevel': 'moderate',
      'confidenceScore': 60,
      'urgencyMessage':
          'We need more information to assess this confidently. Contact your vet to be safe.',
      'detailedExplanation':
          'The AI assessor returned an incomplete reading for this exposure. As a precaution, treat this as a moderate-risk incident and consult a licensed veterinarian.',
      'immediateActions': const [
        'Call your veterinarian or an animal poison control line',
        'Keep your pet calm and prevent further exposure',
        'Note the time of exposure and any new symptoms',
      ],
      'symptomsToMonitor': const [
        'Vomiting',
        'Tremors',
        'Difficulty breathing',
        'Lethargy',
      ],
      'requiresVetVisit': true,
      'requiresEmergencyVet': false,
      'timeWindow': 'As soon as possible',
      'prognosisIfTreated': 'Generally good with prompt veterinary care.',
      'prognosisIfUntreated':
          'Outcome depends on the substance and the dose; do not wait.',
      'petOwnerGuidance':
          'We know this is stressful. A quick call to your vet gives you the clearest next step, and they can advise on home monitoring versus a clinic visit.',
    });
    return parsed;
  }

  // ─── Progress plumbing ───────────────────────────────────────────
  void _seedProgress() {
    final p = progress;
    if (p == null) return;
    p.value = OrchestrationProgress(
      stages: List<AgentStage>.from(defaultStages),
      activeIndex: -1,
    );
  }

  void _markRunning(int index) {
    final p = progress;
    if (p == null) return;
    p.value = p.value.markRunning(index);
  }

  void _markCompleted(int index) {
    final p = progress;
    if (p == null) return;
    p.value = p.value.markCompleted(index);
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  String? _encodeJson(Object? v) {
    if (v == null) return null;
    try {
      return v.toString();
    } catch (_) {
      return null;
    }
  }

  List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
