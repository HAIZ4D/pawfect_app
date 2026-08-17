import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/pet_model.dart';
import '../models/symptom_model.dart';
import '../models/diagnosis_model.dart';
import 'gemini_service.dart';
import 'orchestration/illness_orchestrator.dart';
import 'orchestration/agent_stage.dart';

/// AI Agent Decision Engine — orchestrated edition.
///
/// The diagnostic reasoning is now produced by [IllnessOrchestrator]
/// (five specialised agents in series + parallel). This service stitches
/// the orchestrator's structured output together with Gemini's
/// content-generation calls (explanation, first aid, vet report) and
/// the deterministic urgency / confidence / recommendation logic that
/// existed before, producing a complete [DiagnosisModel].
class AIAgentService {
  final GeminiService _geminiService;

  AIAgentService({required GeminiService geminiService})
      : _geminiService = geminiService;

  /// Diagnose using the orchestrated pipeline.
  ///
  /// [progress] is an optional [ValueNotifier] the caller renders in a
  /// multi-stage loading UI. Eight stages: 5 orchestrator agents
  /// followed by 3 content-generation agents running in parallel.
  Future<DiagnosisModel> diagnose({
    required List<SymptomModel> symptoms,
    File? image,
    PetModel? pet,
    ValueNotifier<OrchestrationProgress>? progress,
  }) async {
    try {
      _seedFullPipeline(progress);

      // Stages 0-4: orchestrated diagnosis.
      final orchestrator = IllnessOrchestrator(progress: progress);
      final aiAnalysis = await orchestrator.diagnose(
        symptoms: symptoms,
        image: image,
        pet: pet,
      );

      final mlResults = aiAnalysis['mlResults'] as Map<String, dynamic>?;
      final condition = (aiAnalysis['mostLikelyCondition'] as String?) ??
          'Condition requires veterinary evaluation';

      // Safety net: deterministic urgency over Gemini's call so a
      // critical red flag (seizures, bloat, paralysis) escalates even
      // if the synthesis agent under-classifies it.
      final urgencyLevel = _calculateUrgencyLevel(
        symptoms: symptoms,
        mlResults: mlResults,
        aiAnalysis: aiAnalysis,
      );

      final confidence = _calculateConfidence(
        symptoms: symptoms,
        mlResults: mlResults,
        aiAnalysis: aiAnalysis,
      );

      // Stage 5: explanation + first aid + vet report in parallel so
      // the slow steps don't compound. Reflected as one "Finalising"
      // stage in the progress UI.
      _markStageRunning(progress, 5);
      final contentResults = await Future.wait([
        _geminiService.generateDiagnosisExplanation(
          condition: condition,
          symptoms: symptoms,
          urgencyLevel: urgencyLevel,
          confidence: confidence,
          pet: pet,
          mlResults: mlResults,
        ),
        _geminiService.generateFirstAidInstructions(
          condition: condition,
          urgencyLevel: urgencyLevel,
          symptoms: symptoms,
          pet: pet,
        ),
        _geminiService.generateVetReport(
          condition: condition,
          symptoms: symptoms,
          urgencyLevel: urgencyLevel,
          confidence: confidence,
          detectionTime: DateTime.now(),
          pet: pet,
          mlResults: mlResults,
        ),
      ]);
      _markStageCompleted(progress, 5);

      final explanation = contentResults[0];
      final firstAid = contentResults[1];
      final vetReport = contentResults[2];

      final recommendations = _generateRecommendations(
        urgencyLevel: urgencyLevel,
        aiAnalysis: aiAnalysis,
        mlResults: mlResults,
      );

      return DiagnosisModel(
        condition: condition,
        symptoms: symptoms.map((s) => s.name).toList(),
        urgencyLevel: urgencyLevel,
        confidence: confidence,
        explanation: explanation,
        recommendations: recommendations,
        firstAidInstructions: firstAid,
        vetReport: vetReport,
        timestamp: DateTime.now(),
        petId: pet?.id,
        petName: pet?.name,
        mlDetections: mlResults?['detectedConditions'] is List
            ? List<String>.from(mlResults!['detectedConditions'] as List)
            : <String>[],
        mlAnalysis: mlResults?['analysis'] as String?,
        riskFactors: List<String>.from(aiAnalysis['riskFactors'] ?? const []),
      );
    } catch (_) {
      return DiagnosisModel(
        condition: 'Analysis incomplete - Please consult veterinarian',
        symptoms: symptoms.map((s) => s.name).toList(),
        urgencyLevel: 'MODERATE',
        confidence: 0.5,
        explanation:
            'We encountered an issue analysing the symptoms. Please consult with a veterinarian for proper diagnosis.',
        recommendations: const [
          'Consult veterinarian',
          'Monitor symptoms',
          'Keep pet comfortable',
        ],
        firstAidInstructions:
            'Ensure pet is comfortable and safe. Contact your veterinarian for guidance.',
        vetReport:
            'Automatic report generation unavailable. Please describe symptoms to your veterinarian.',
        timestamp: DateTime.now(),
        petId: pet?.id,
        petName: pet?.name,
        mlDetections: const [],
        riskFactors: const ['Analysis error occurred'],
      );
    }
  }

  // ─── Progress plumbing ───────────────────────────────────────────
  /// Seed the progress notifier with all 6 visible stages: 5 from the
  /// orchestrator + 1 "Finalising" for the parallel content gen.
  void _seedFullPipeline(ValueNotifier<OrchestrationProgress>? progress) {
    if (progress == null) return;
    progress.value = OrchestrationProgress(
      stages: [
        ...IllnessOrchestrator.defaultStages,
        const AgentStage(
          key: 'finalising',
          title: 'Finalising care plan',
          subtitle: 'Explanation, first aid, vet report.',
        ),
      ],
      activeIndex: -1,
    );
  }

  void _markStageRunning(
    ValueNotifier<OrchestrationProgress>? progress,
    int index,
  ) {
    if (progress == null) return;
    progress.value = progress.value.markRunning(index);
  }

  void _markStageCompleted(
    ValueNotifier<OrchestrationProgress>? progress,
    int index,
  ) {
    if (progress == null) return;
    progress.value = progress.value.markCompleted(index);
  }

  // ─── Deterministic urgency safety net ────────────────────────────
  String _calculateUrgencyLevel({
    required List<SymptomModel> symptoms,
    Map<String, dynamic>? mlResults,
    Map<String, dynamic>? aiAnalysis,
  }) {
    String urgency = aiAnalysis?['urgencyLevel'] ?? 'MODERATE';

    const emergencySymptoms = [
      'difficulty breathing',
      'seizures',
      'collapse',
      'severe bleeding',
      'poisoning',
      'unconscious',
      'bloat',
      'unable to urinate',
      'paralysis',
    ];
    for (final symptom in symptoms) {
      if (emergencySymptoms
          .any((e) => symptom.name.toLowerCase().contains(e))) {
        return 'EMERGENCY';
      }
    }

    const highRiskSymptoms = [
      'blood in stool',
      'blood in urine',
      'vomiting blood',
      'severe pain',
      'rapid breathing',
      'pale gums',
      'high fever',
    ];
    for (final symptom in symptoms) {
      if (highRiskSymptoms
          .any((h) => symptom.name.toLowerCase().contains(h))) {
        if (urgency != 'EMERGENCY') urgency = 'HIGH';
      }
    }

    if (mlResults != null && mlResults['hasDetections'] == true) {
      final detections = mlResults['detections'] as List<dynamic>;
      for (final detection in detections) {
        if (detection['severity'] == 'HIGH') {
          if (urgency == 'MODERATE' || urgency == 'LOW') urgency = 'HIGH';
        }
      }
    }

    if (symptoms.length >= 5 && urgency == 'LOW') urgency = 'MODERATE';
    return urgency;
  }

  // ─── Confidence blend ────────────────────────────────────────────
  double _calculateConfidence({
    required List<SymptomModel> symptoms,
    Map<String, dynamic>? mlResults,
    Map<String, dynamic>? aiAnalysis,
  }) {
    double confidence = 0.5;
    final symptomScore = (symptoms.length / 10).clamp(0.0, 0.3);
    confidence += symptomScore;

    if (mlResults != null && mlResults['topConfidence'] != null) {
      final mlScore = (mlResults['topConfidence'] as num).toDouble() * 0.35;
      confidence += mlScore;
    }

    if (aiAnalysis != null && aiAnalysis['confidence'] != null) {
      final aiScore = (aiAnalysis['confidence'] as num).toDouble() * 0.35;
      confidence += aiScore;
    }

    return confidence.clamp(0.0, 1.0);
  }

  // ─── Recommendations ─────────────────────────────────────────────
  List<String> _generateRecommendations({
    required String urgencyLevel,
    Map<String, dynamic>? aiAnalysis,
    Map<String, dynamic>? mlResults,
  }) {
    final ordered = <String>[];

    if (aiAnalysis != null && aiAnalysis['recommendations'] is List) {
      for (final rec in aiAnalysis['recommendations'] as List) {
        final s = rec.toString().trim();
        if (s.isNotEmpty) ordered.add(s);
      }
    }

    if (mlResults != null && mlResults['hasDetections'] == true) {
      ordered.add('Share the captured photo with your veterinarian');
      final detections = mlResults['detectedConditions'] as List<dynamic>;
      if (detections.contains('Wound/Injury')) {
        ordered.add('Keep the wound clean and prevent your pet from licking it');
      }
      if (detections.contains('Parasites (Fleas/Ticks)')) {
        ordered.add('Isolate from other pets and treat the home environment');
      }
      if (detections.contains('Eye Abnormality')) {
        ordered.add('Avoid touching the eye and prevent rubbing or scratching');
      }
      if (detections.contains('Skin Infection')) {
        ordered.add('Avoid bathing with regular shampoo until a vet advises');
      }
    }

    final fallback = switch (urgencyLevel) {
      'EMERGENCY' => const [
          'Seek immediate veterinary care',
          'Call the emergency vet before travelling',
          'Keep your pet calm and still during transport',
        ],
      'HIGH' => const [
          'Schedule a vet appointment within 24 hours',
          'Monitor symptoms closely and note any changes',
        ],
      'MODERATE' => const [
          'Schedule a vet appointment within 2-3 days',
          'Keep your pet comfortable and well hydrated',
        ],
      'LOW' => const [
          'Monitor symptoms over the next few days',
          'Maintain normal diet and routine',
        ],
      _ => const <String>[],
    };
    ordered.addAll(fallback);

    final seen = <String>{};
    final result = <String>[];
    for (final r in ordered) {
      final key = r.toLowerCase();
      if (seen.add(key)) result.add(r);
    }
    return result;
  }

  /// Symptom-only diagnosis (no image).
  Future<DiagnosisModel> analyzeSymptoms({
    required List<SymptomModel> symptoms,
    PetModel? pet,
    ValueNotifier<OrchestrationProgress>? progress,
  }) {
    return diagnose(
      symptoms: symptoms,
      image: null,
      pet: pet,
      progress: progress,
    );
  }

  /// Image-only diagnosis (no symptoms).
  Future<DiagnosisModel> analyzeImage({
    required File image,
    PetModel? pet,
    ValueNotifier<OrchestrationProgress>? progress,
  }) {
    return diagnose(
      symptoms: const [],
      image: image,
      pet: pet,
      progress: progress,
    );
  }
}
