import 'dart:io';
import '../models/pet_model.dart';
import '../models/symptom_model.dart';
import '../models/diagnosis_model.dart';
import 'gemini_service.dart';

/// AI Agent Decision Engine
/// Combines Gemini multimodal image analysis + symptom data
/// to provide comprehensive illness detection and recommendations.
class AIAgentService {
  final GeminiService _geminiService;

  AIAgentService({required GeminiService geminiService})
      : _geminiService = geminiService;

  /// Main diagnosis method - combines all AI components
  ///
  /// This is the core decision engine that:
  /// 1. Analyzes image with Gemini vision (if provided)
  /// 2. Processes symptoms
  /// 3. Uses Gemini to combine results into a structured diagnosis
  /// 4. Calculates urgency level
  /// 5. Generates recommendations
  Future<DiagnosisModel> diagnose({
    required List<SymptomModel> symptoms,
    File? image,
    PetModel? pet,
  }) async {
    try {
      print('AI Agent: Starting diagnosis...');
      print('Symptoms: ${symptoms.length}');
      print('Image: ${image != null ? 'Provided' : 'Not provided'}');
      print('Pet: ${pet?.name ?? 'Not specified'}');

      // Step 1: Analyze image with Gemini vision (if provided)
      Map<String, dynamic>? mlResults;
      if (image != null && _geminiService.isInitialized) {
        print('Step 1: Running Gemini vision analysis...');
        mlResults = await _geminiService.analyzeImage(image, pet: pet);
        print('Vision analysis complete: ${mlResults['detectedConditions']}');
      } else {
        print('Step 1: Skipping image analysis (no image provided)');
      }

      // Step 2: Use Gemini AI to analyze condition
      print('🔄 Step 2: Running Gemini AI analysis...');
      final aiAnalysis = await _geminiService.analyzeCondition(
        symptoms: symptoms,
        mlResults: mlResults,
        pet: pet,
      );
      print('✅ Gemini analysis complete: ${aiAnalysis['mostLikelyCondition']}');

      // Step 3: Calculate urgency level
      print('🔄 Step 3: Calculating urgency level...');
      final urgencyLevel = _calculateUrgencyLevel(
        symptoms: symptoms,
        mlResults: mlResults,
        aiAnalysis: aiAnalysis,
      );
      print('✅ Urgency level: $urgencyLevel');

      // Step 4: Calculate confidence score
      final confidence = _calculateConfidence(
        symptoms: symptoms,
        mlResults: mlResults,
        aiAnalysis: aiAnalysis,
      );
      print('✅ Confidence: ${(confidence * 100).toStringAsFixed(1)}%');

      // Step 5: Generate human-friendly explanation
      print('🔄 Step 5: Generating explanation...');
      final explanation = await _geminiService.generateDiagnosisExplanation(
        condition: aiAnalysis['mostLikelyCondition'] ?? 'Unknown condition',
        symptoms: symptoms,
        urgencyLevel: urgencyLevel,
        confidence: confidence,
        pet: pet,
        mlResults: mlResults,
      );
      print('✅ Explanation generated');

      // Step 6: Generate first-aid instructions
      print('🔄 Step 6: Generating first-aid instructions...');
      final firstAid = await _geminiService.generateFirstAidInstructions(
        condition: aiAnalysis['mostLikelyCondition'] ?? 'Unknown condition',
        urgencyLevel: urgencyLevel,
        symptoms: symptoms,
        pet: pet,
      );
      print('✅ First-aid instructions generated');

      // Step 7: Generate vet report
      print('🔄 Step 7: Generating vet report...');
      final vetReport = await _geminiService.generateVetReport(
        condition: aiAnalysis['mostLikelyCondition'] ?? 'Unknown condition',
        symptoms: symptoms,
        urgencyLevel: urgencyLevel,
        confidence: confidence,
        detectionTime: DateTime.now(),
        pet: pet,
        mlResults: mlResults,
      );
      print('✅ Vet report generated');

      // Step 8: Compile recommendations
      final recommendations = _generateRecommendations(
        urgencyLevel: urgencyLevel,
        aiAnalysis: aiAnalysis,
        mlResults: mlResults,
      );

      // Create comprehensive diagnosis result
      final diagnosis = DiagnosisModel(
        condition: aiAnalysis['mostLikelyCondition'] ?? 'Condition requires veterinary evaluation',
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
        mlDetections: mlResults?['detectedConditions'] ?? [],
        mlAnalysis: mlResults?['analysis'],
        riskFactors: List<String>.from(aiAnalysis['riskFactors'] ?? []),
      );

      print('🎉 AI Agent: Diagnosis complete!');
      return diagnosis;
    } catch (e) {
      print('❌ AI Agent error: $e');

      // Return fallback diagnosis
      return DiagnosisModel(
        condition: 'Analysis incomplete - Please consult veterinarian',
        symptoms: symptoms.map((s) => s.name).toList(),
        urgencyLevel: 'MODERATE',
        confidence: 0.5,
        explanation: 'We encountered an issue analyzing the symptoms. Please consult with a veterinarian for proper diagnosis.',
        recommendations: ['Consult veterinarian', 'Monitor symptoms', 'Keep pet comfortable'],
        firstAidInstructions: 'Ensure pet is comfortable and safe. Contact your veterinarian for guidance.',
        vetReport: 'Automatic report generation unavailable. Please describe symptoms to your veterinarian.',
        timestamp: DateTime.now(),
        petId: pet?.id,
        petName: pet?.name,
        mlDetections: [],
        riskFactors: ['Analysis error occurred'],
      );
    }
  }

  /// Calculate urgency level based on all available data
  ///
  /// Returns: EMERGENCY, HIGH, MODERATE, or LOW
  String _calculateUrgencyLevel({
    required List<SymptomModel> symptoms,
    Map<String, dynamic>? mlResults,
    Map<String, dynamic>? aiAnalysis,
  }) {
    // Start with AI's recommendation if available
    String urgency = aiAnalysis?['urgencyLevel'] ?? 'MODERATE';

    // Critical symptoms that override to EMERGENCY
    final emergencySymptoms = [
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
      if (emergencySymptoms.any((emergency) =>
          symptom.name.toLowerCase().contains(emergency))) {
        return 'EMERGENCY';
      }
    }

    // High-risk symptoms
    final highRiskSymptoms = [
      'blood in stool',
      'blood in urine',
      'vomiting blood',
      'severe pain',
      'rapid breathing',
      'pale gums',
      'high fever',
    ];

    for (final symptom in symptoms) {
      if (highRiskSymptoms.any((high) =>
          symptom.name.toLowerCase().contains(high))) {
        if (urgency != 'EMERGENCY') {
          urgency = 'HIGH';
        }
      }
    }

    // ML detection severity
    if (mlResults != null && mlResults['hasDetections'] == true) {
      final detections = mlResults['detections'] as List<dynamic>;
      for (final detection in detections) {
        if (detection['severity'] == 'HIGH') {
          if (urgency == 'MODERATE' || urgency == 'LOW') {
            urgency = 'HIGH';
          }
        }
      }
    }

    // Multiple symptoms increase urgency
    if (symptoms.length >= 5 && urgency == 'LOW') {
      urgency = 'MODERATE';
    }

    return urgency;
  }

  /// Calculate confidence score
  ///
  /// Combines:
  /// - Number of symptoms
  /// - ML detection confidence
  /// - AI analysis confidence
  double _calculateConfidence({
    required List<SymptomModel> symptoms,
    Map<String, dynamic>? mlResults,
    Map<String, dynamic>? aiAnalysis,
  }) {
    double confidence = 0.5; // Base confidence

    // Symptom count contribution (0.0 to 0.3)
    final symptomScore = (symptoms.length / 10).clamp(0.0, 0.3);
    confidence += symptomScore;

    // ML detection contribution (0.0 to 0.35)
    if (mlResults != null && mlResults['topConfidence'] != null) {
      final mlScore = (mlResults['topConfidence'] as double) * 0.35;
      confidence += mlScore;
    }

    // AI analysis contribution (0.0 to 0.35)
    if (aiAnalysis != null && aiAnalysis['confidence'] != null) {
      final aiScore = (aiAnalysis['confidence'] as double) * 0.35;
      confidence += aiScore;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Generate actionable recommendations.
  ///
  /// Order:
  ///   1. Gemini's condition-specific recommendations (most useful — these
  ///      name the actual condition).
  ///   2. ML-derived recommendations (only when image showed something).
  ///   3. Urgency-tier boilerplate as a fallback so the list is never empty.
  /// Duplicates are stripped case-insensitively while preserving order.
  List<String> _generateRecommendations({
    required String urgencyLevel,
    Map<String, dynamic>? aiAnalysis,
    Map<String, dynamic>? mlResults,
  }) {
    final ordered = <String>[];

    // 1. Gemini's specific recommendations lead.
    if (aiAnalysis != null && aiAnalysis['recommendations'] is List) {
      for (final rec in aiAnalysis['recommendations'] as List) {
        final s = rec.toString().trim();
        if (s.isNotEmpty) ordered.add(s);
      }
    }

    // 2. ML-derived condition-specific recommendations.
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

    // 3. Urgency-tier boilerplate at the end (only adds what's missing).
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
          'Schedule a vet appointment within 2–3 days',
          'Keep your pet comfortable and well hydrated',
        ],
      'LOW' => const [
          'Monitor symptoms over the next few days',
          'Maintain normal diet and routine',
        ],
      _ => const <String>[],
    };
    ordered.addAll(fallback);

    // Dedupe case-insensitively, preserving first occurrence.
    final seen = <String>{};
    final result = <String>[];
    for (final r in ordered) {
      final key = r.toLowerCase();
      if (seen.add(key)) result.add(r);
    }
    return result;
  }

  /// Quick symptom-only analysis (when no image available)
  Future<DiagnosisModel> analyzeSymptoms({
    required List<SymptomModel> symptoms,
    PetModel? pet,
  }) async {
    return diagnose(symptoms: symptoms, image: null, pet: pet);
  }

  /// Quick image-only analysis (when no symptoms reported)
  Future<DiagnosisModel> analyzeImage({
    required File image,
    PetModel? pet,
  }) async {
    return diagnose(symptoms: [], image: image, pet: pet);
  }
}
