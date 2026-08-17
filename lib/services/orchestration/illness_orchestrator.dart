import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/pet_model.dart';
import '../../models/symptom_model.dart';
import '../gemini_client.dart';
import 'agent_runner.dart';
import 'agent_stage.dart';

/// Orchestrated illness diagnosis pipeline.
///
/// Replaces the single-call `GeminiService.analyzeCondition` with five
/// focused agents. Each agent has one job, a narrow prompt, and a
/// structured JSON output. The downstream `AIAgentService` consumes
/// the same map shape the old monolithic call produced, so urgency,
/// recommendations, and follow-up content generation continue to work
/// unchanged.
///
/// Pipeline:
///   1. VisionAgent       — photo → visible findings (optional)
///   2. SymptomAgent      — symptoms + pet → clinical signals
///   3. DifferentialAgent — candidates with probabilities + evidence
///   4. CriticAgent       — challenges weak candidates, demotes
///                          hallucinations, sets pipeline confidence
///   5. SynthesisAgent    — final condition + urgency + recommendations
///
/// Stages 1 + 2 run in parallel. Stages 3–5 run sequentially because
/// each consumes the previous stage's output.
class IllnessOrchestrator {
  IllnessOrchestrator({this.progress});

  /// Optional progress sink. The caller listens and renders a
  /// multi-stage loading UI. If null, the pipeline runs silently.
  final ValueNotifier<OrchestrationProgress>? progress;

  /// Stage definitions in display order. Exposed so callers can seed
  /// the progress notifier before calling [diagnose].
  static const List<AgentStage> defaultStages = [
    AgentStage(
      key: 'vision',
      title: 'Reading the photo',
      subtitle: 'Visible findings, severity cues.',
    ),
    AgentStage(
      key: 'symptoms',
      title: 'Interpreting symptoms',
      subtitle: 'Clinical signals, affected systems.',
    ),
    AgentStage(
      key: 'differential',
      title: 'Generating candidates',
      subtitle: 'Three most likely conditions, with probability.',
    ),
    AgentStage(
      key: 'critic',
      title: 'Challenging the differential',
      subtitle: 'Demoting weak claims, scoring confidence.',
    ),
    AgentStage(
      key: 'synthesis',
      title: 'Assembling diagnosis',
      subtitle: 'Final call, urgency, recommendations.',
    ),
  ];

  // ─── Public API ──────────────────────────────────────────────────
  /// Run the full pipeline. Returns a map in the same shape as the
  /// legacy `analyzeCondition` so existing call sites keep working:
  ///
  /// ```
  /// {
  ///   'mostLikelyCondition': String,
  ///   'urgencyLevel': 'EMERGENCY' | 'HIGH' | 'MODERATE' | 'LOW',
  ///   'confidence': double 0..1,
  ///   'riskFactors': List<String>,
  ///   'recommendations': List<String>,
  ///   'differential': List<Map>,
  ///   'visionFindings': Map?,
  ///   'symptomReading': Map?,
  ///   'criticNotes': List<String>,
  ///   'rawResponse': String,    // synthesis raw output
  /// }
  /// ```
  Future<Map<String, dynamic>> diagnose({
    required List<SymptomModel> symptoms,
    File? image,
    PetModel? pet,
  }) async {
    final model = GeminiClient.buildModel(
      generationConfig: GenerationConfig(
        temperature: 0.55,
        topK: 32,
        topP: 0.92,
        maxOutputTokens: 1024,
      ),
    );

    _seedProgress();

    // Stage 1 + 2 in parallel. Started together; awaited separately so
    // each return type stays distinct (vision nullable, symptom not).
    _markRunning(0);
    _markRunning(1);
    final visionFuture =
        _runVisionAgent(model: model, image: image, pet: pet);
    final symptomFuture =
        _runSymptomAgent(model: model, symptoms: symptoms, pet: pet);
    final visionFindings = await visionFuture;
    final symptomReading = await symptomFuture;
    _markCompleted(0);
    _markCompleted(1);

    // Stage 3: Differential.
    _markRunning(2);
    final differential = await _runDifferentialAgent(
      model: model,
      pet: pet,
      symptoms: symptoms,
      visionFindings: visionFindings,
      symptomReading: symptomReading,
    );
    _markCompleted(2);

    // Stage 4: Critic.
    _markRunning(3);
    final critique = await _runCriticAgent(
      model: model,
      differential: differential,
      visionFindings: visionFindings,
      symptomReading: symptomReading,
    );
    _markCompleted(3);

    // Stage 5: Synthesis.
    _markRunning(4);
    final synthesis = await _runSynthesisAgent(
      model: model,
      pet: pet,
      differential: differential,
      critique: critique,
      visionFindings: visionFindings,
      symptomReading: symptomReading,
    );
    _markCompleted(4);

    final candidates = (differential['candidates'] as List?) ?? const [];
    return {
      'mostLikelyCondition': synthesis['condition'] ?? _topCandidate(candidates),
      'urgencyLevel': _normalizeUrgency(synthesis['urgencyLevel']),
      'confidence': _clamp01(synthesis['confidence']),
      'riskFactors': _stringList(synthesis['riskFactors']),
      'recommendations': _stringList(synthesis['recommendations']),
      'differential': candidates,
      'visionFindings': visionFindings,
      'symptomReading': symptomReading,
      'criticNotes': _stringList(critique['notes']),
      'mlResults': _toLegacyMlResults(visionFindings),
      'rawResponse': synthesis['rawResponse'] ?? '',
    };
  }

  /// Convert the vision agent's structured findings into the legacy
  /// `mlResults` shape that downstream `AIAgentService` code still
  /// consumes (urgency calc, recommendations, vet report context).
  /// Returns null when there was no image to read.
  Map<String, dynamic>? _toLegacyMlResults(Map<String, dynamic>? vision) {
    if (vision == null) return null;
    final findings = (vision['findings'] as List?) ?? const [];
    if (findings.isEmpty) {
      return {
        'hasDetections': false,
        'detectedConditions': const <String>[],
        'detections': const <Map<String, dynamic>>[],
        'confidenceScores': const <String, double>{},
        'topCondition': null,
        'topConfidence': 0.0,
        'analysis':
            vision['summary']?.toString() ?? 'No significant findings detected.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    final mapped = <Map<String, dynamic>>[];
    for (final f in findings) {
      if (f is! Map) continue;
      final area = f['area']?.toString() ?? 'other';
      final severity = (f['severity']?.toString() ?? 'MILD').toUpperCase();
      final condition = _areaToLegacyCondition(area);
      final conf = switch (severity) {
        'SEVERE' => 0.92,
        'MODERATE' => 0.78,
        _ => 0.65,
      };
      mapped.add({
        'condition': condition,
        'confidence': conf,
        'severity': severity == 'SEVERE' ? 'HIGH' : (severity == 'MODERATE' ? 'MODERATE' : 'LOW'),
        'description': f['description']?.toString() ?? '',
      });
    }

    mapped.sort((a, b) => (b['confidence'] as double)
        .compareTo(a['confidence'] as double));

    final detectedConditions = mapped
        .map((d) => d['condition']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final confidenceScores = <String, double>{};
    for (final d in mapped) {
      final c = d['condition']?.toString();
      final conf = (d['confidence'] as num?)?.toDouble();
      if (c != null && conf != null) confidenceScores[c] = conf;
    }

    return {
      'hasDetections': true,
      'detectedConditions': detectedConditions,
      'detections': mapped,
      'confidenceScores': confidenceScores,
      'topCondition': mapped.first['condition'],
      'topConfidence': mapped.first['confidence'],
      'analysis': vision['summary']?.toString() ??
          '${detectedConditions.length} visible finding(s).',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Map the vision agent's area enum to the four legacy condition
  /// labels the rest of the app already knows how to render.
  String _areaToLegacyCondition(String area) {
    switch (area.toLowerCase()) {
      case 'skin':
        return 'Skin Infection';
      case 'wound':
        return 'Wound/Injury';
      case 'parasites':
        return 'Parasites (Fleas/Ticks)';
      case 'eye':
        return 'Eye Abnormality';
      default:
        return 'Visible Finding';
    }
  }

  // ─── Stage 1: Vision agent ───────────────────────────────────────
  Future<Map<String, dynamic>?> _runVisionAgent({
    required GenerativeModel model,
    File? image,
    PetModel? pet,
  }) async {
    if (image == null) return null;
    final speciesLine = pet == null
        ? 'Pet species and breed unknown.'
        : 'Subject: ${pet.species}${pet.breed.isNotEmpty ? " (${pet.breed})" : ""}.';

    final prompt = '''
You are the VISION agent in a multi-agent veterinary diagnostic pipeline. You only describe what is visible. You do NOT diagnose. You do NOT recommend treatment. Other agents handle those.

$speciesLine

Examine the attached photo. Identify visible findings in these categories:
- Skin (lesions, redness, hair loss, dandruff)
- Wounds (cuts, abrasions, swelling, bleeding)
- Parasites (visible fleas, ticks, mites)
- Eyes (discharge, redness, cloudiness, swelling)
- Mouth and gums (color, lesions, dental issues)
- Posture and body condition (limping, lethargy, weight)

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "findings": [
    {
      "area": "skin|wound|parasites|eye|mouth|posture|other",
      "description": "<concrete observation, e.g. 'crusty lesion behind left ear, ~1cm'>",
      "severity": "MILD|MODERATE|SEVERE"
    }
  ],
  "imageQuality": "GOOD|ACCEPTABLE|POOR",
  "summary": "<one sentence overall impression>"
}

If nothing abnormal is visible, return an empty findings array and say so in summary.
''';

    try {
      final bytes = await image.readAsBytes();
      return await AgentRunner.runVisionJsonObject(
        model: model,
        prompt: prompt,
        imageBytes: bytes,
        fallback: {
          'findings': const [],
          'imageQuality': 'POOR',
          'summary': 'Vision analysis unavailable.',
        },
      );
    } catch (_) {
      _markFailed(0, 'Vision agent could not read the image.');
      return null;
    }
  }

  // ─── Stage 2: Symptom agent ──────────────────────────────────────
  Future<Map<String, dynamic>> _runSymptomAgent({
    required GenerativeModel model,
    required List<SymptomModel> symptoms,
    PetModel? pet,
  }) async {
    final petLine = pet == null
        ? 'Pet profile unavailable.'
        : 'Subject: ${pet.species}${pet.breed.isNotEmpty ? " (${pet.breed})" : ""}, weight ${pet.weight ?? "unknown"} kg.';

    final symptomList = symptoms.isEmpty
        ? '(none reported)'
        : symptoms.map((s) => '- ${s.name} [${s.category}]').join('\n');

    final prompt = '''
You are the SYMPTOM agent in a multi-agent veterinary diagnostic pipeline. You translate raw owner-reported symptoms into clinical signals. You do NOT diagnose. You do NOT recommend treatment.

$petLine

Owner reports:
$symptomList

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "clinicalSignals": [
    {
      "signal": "<clinical interpretation, e.g. 'lethargy with reduced appetite suggests systemic illness'>",
      "supportingSymptoms": ["<symptom name>"],
      "severity": "MILD|MODERATE|SEVERE"
    }
  ],
  "systemsAffected": ["digestive", "respiratory", "neurological", "dermatologic", "musculoskeletal", "urinary", "behavioural"],
  "redFlags": ["<symptom that requires immediate attention, e.g. 'pale gums'>"],
  "summary": "<one sentence overall clinical impression>"
}

Be honest. If the symptoms are vague (e.g. just "low energy"), say so in summary.
''';

    return AgentRunner.runJsonObject(
      model: model,
      prompt: prompt,
      fallback: {
        'clinicalSignals': const [],
        'systemsAffected': const [],
        'redFlags': const [],
        'summary': 'No clinical signals could be derived from the input.',
      },
    );
  }

  // ─── Stage 3: Differential agent ─────────────────────────────────
  Future<Map<String, dynamic>> _runDifferentialAgent({
    required GenerativeModel model,
    required PetModel? pet,
    required List<SymptomModel> symptoms,
    required Map<String, dynamic>? visionFindings,
    required Map<String, dynamic> symptomReading,
  }) async {
    final petLine = pet == null
        ? 'Subject: species unknown.'
        : 'Subject: ${pet.species}${pet.breed.isNotEmpty ? " (${pet.breed})" : ""}, ${pet.getAge()}.';

    final prompt = '''
You are the DIFFERENTIAL DIAGNOSIS agent in a multi-agent veterinary pipeline. Your job is to propose the three most likely SPECIFIC veterinary conditions consistent with the evidence below.

$petLine

VISION FINDINGS (from the vision agent):
${_encodeJson(visionFindings) ?? '(no image provided)'}

CLINICAL SIGNALS (from the symptom agent):
${_encodeJson(symptomReading)}

OWNER-REPORTED SYMPTOMS (raw):
${symptoms.isEmpty ? '(none reported)' : symptoms.map((s) => '- ${s.name}').join('\n')}

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "candidates": [
    {
      "condition": "<specific named veterinary condition, e.g. 'Otitis Externa', 'Feline Acne', 'Flea Allergy Dermatitis'>",
      "probability": <number 0..1>,
      "supportingEvidence": ["<specific symptom or visible finding>"],
      "contradictoryEvidence": ["<specific symptom that argues against this>"],
      "rationale": "<one sentence on why this condition matches>"
    }
  ]
}

RULES:
- Three candidates max, ordered by probability descending.
- Probabilities sum to <= 1.0.
- "condition" must be a real named veterinary condition. NO generic labels like "Skin Issue" or "Condition Detected".
- supportingEvidence and contradictoryEvidence are pulled from the evidence above. Quote it accurately.
- If evidence is too thin for three candidates, return fewer (one or two is fine).
''';

    return AgentRunner.runJsonObject(
      model: model,
      prompt: prompt,
      fallback: {
        'candidates': const [],
      },
    );
  }

  // ─── Stage 4: Critic agent ───────────────────────────────────────
  Future<Map<String, dynamic>> _runCriticAgent({
    required GenerativeModel model,
    required Map<String, dynamic> differential,
    required Map<String, dynamic>? visionFindings,
    required Map<String, dynamic> symptomReading,
  }) async {
    final prompt = '''
You are the CRITIC agent in a multi-agent veterinary pipeline. Your job is to challenge the differential below. Find unsupported claims, flag possible hallucinations, and adjust confidence accordingly. This is the hallucination guard for the whole pipeline.

DIFFERENTIAL (from the differential agent):
${_encodeJson(differential)}

VISION FINDINGS:
${_encodeJson(visionFindings) ?? '(no image)'}

CLINICAL SIGNALS:
${_encodeJson(symptomReading)}

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "rankedCandidates": [
    {
      "condition": "<copy from differential>",
      "adjustedProbability": <number 0..1>,
      "issues": ["<concern, e.g. 'no symptom supports this'>"]
    }
  ],
  "notes": ["<short note on the overall reasoning>"],
  "pipelineConfidence": <number 0..1>
}

RULES:
- If a candidate has zero genuine supportingEvidence, drop its probability sharply.
- If a candidate is inconsistent with the species or age (e.g. condition that doesn't occur in cats applied to a cat), flag it in issues and zero out its probability.
- If the differential is empty or thin, set pipelineConfidence low (0.3 or below) and note "insufficient evidence" in notes.
- Be skeptical. False confidence is the enemy.
''';

    return AgentRunner.runJsonObject(
      model: model,
      prompt: prompt,
      fallback: {
        'rankedCandidates': const [],
        'notes': const ['Critic agent unavailable, accepting differential as-is.'],
        'pipelineConfidence': 0.55,
      },
    );
  }

  // ─── Stage 5: Synthesis agent ────────────────────────────────────
  Future<Map<String, dynamic>> _runSynthesisAgent({
    required GenerativeModel model,
    required PetModel? pet,
    required Map<String, dynamic> differential,
    required Map<String, dynamic> critique,
    required Map<String, dynamic>? visionFindings,
    required Map<String, dynamic> symptomReading,
  }) async {
    final petLine = pet == null
        ? 'Pet profile unavailable.'
        : 'Subject: ${pet.species}${pet.breed.isNotEmpty ? " (${pet.breed})" : ""}, ${pet.getAge()}, weight ${pet.weight ?? "unknown"} kg.';

    final prompt = '''
You are the SYNTHESIS agent at the end of a multi-agent veterinary pipeline. Combine the prior outputs into a single final assessment. You do not generate new claims — you pick the strongest candidate from the critic-adjusted ranking and assemble the structured output.

$petLine

DIFFERENTIAL: ${_encodeJson(differential)}
CRITIC ADJUSTMENTS: ${_encodeJson(critique)}
VISION: ${_encodeJson(visionFindings) ?? '(no image)'}
SYMPTOMS: ${_encodeJson(symptomReading)}

Return ONLY valid JSON in this exact shape. No prose. No fences.

{
  "condition": "<the highest critic-adjusted-probability condition; never invent a new one>",
  "urgencyLevel": "EMERGENCY|HIGH|MODERATE|LOW",
  "confidence": <number 0..1 — multiply top candidate adjustedProbability by pipelineConfidence>,
  "riskFactors": ["<specific concerning sign drawn from the evidence>"],
  "recommendations": [
    "<specific actionable home-care or vet step. Verb-first. 4-6 items.>"
  ]
}

URGENCY RULES:
- EMERGENCY if redFlags include breathing difficulty, seizures, collapse, severe bleeding, poisoning, or paralysis.
- HIGH if multiple SEVERE clinical signals or vision findings.
- MODERATE if condition is treatable but needs vet attention.
- LOW if home monitoring is the right next step.

RECOMMENDATION RULES:
- No "see a vet" boilerplate alone. Every recommendation must include a specific action or rationale.
- 4-6 items.
- Verb-first ("Clean the affected ear daily with…", "Withhold food for 12 hours and offer water in small amounts…").
- If urgency is EMERGENCY, recommendation 1 must be "Get to an emergency vet now."

If the critic returned no candidates, set condition to "Condition needs clinical evaluation" and urgencyLevel to "MODERATE" with confidence 0.4.
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';
      final parsed = AgentRunner.parseJsonObject(raw, fallback: {
        'condition': 'Condition needs clinical evaluation',
        'urgencyLevel': 'MODERATE',
        'confidence': 0.5,
        'riskFactors': const <String>[],
        'recommendations': const <String>[],
      });
      parsed['rawResponse'] = raw;
      return parsed;
    } catch (_) {
      return {
        'condition': 'Condition needs clinical evaluation',
        'urgencyLevel': 'MODERATE',
        'confidence': 0.5,
        'riskFactors': const <String>[],
        'recommendations': const <String>[],
        'rawResponse': '',
      };
    }
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

  void _markFailed(int index, String reason) {
    final p = progress;
    if (p == null) return;
    p.value = p.value.markFailed(index, reason);
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

  String _topCandidate(List<dynamic> candidates) {
    if (candidates.isEmpty) return 'Condition needs clinical evaluation';
    final first = candidates.first;
    if (first is Map<String, dynamic>) {
      return first['condition']?.toString() ??
          'Condition needs clinical evaluation';
    }
    return 'Condition needs clinical evaluation';
  }

  String _normalizeUrgency(dynamic raw) {
    final v = raw?.toString().toUpperCase().trim();
    const allowed = {'EMERGENCY', 'HIGH', 'MODERATE', 'LOW'};
    if (v != null && allowed.contains(v)) return v;
    return 'MODERATE';
  }

  double _clamp01(dynamic raw) {
    if (raw is num) return raw.toDouble().clamp(0.0, 1.0);
    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed == null) return 0.5;
    return parsed.clamp(0.0, 1.0);
  }

  List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
