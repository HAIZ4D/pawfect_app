import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/pet_model.dart';
import '../models/poison_substance_model.dart';

class AIPoisoningAssessmentService {
  late final GenerativeModel _model;

  AIPoisoningAssessmentService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  /// AI-powered poisoning risk assessment
  Future<PoisoningAssessmentResult> assessPoisoningRisk({
    required String substanceName,
    required String substanceDescription,
    required PetModel pet,
    required List<String> symptoms,
    required String amountIngested,
    required Duration timeSinceIngestion,
  }) async {
    try {
      final prompt = '''
You are a veterinary AI assistant specializing in pet poisoning emergencies. Analyze this poisoning incident and provide a comprehensive risk assessment.

PET INFORMATION:
- Name: ${pet.name}
- Species: ${pet.species}
- Breed: ${pet.breed ?? 'Unknown'}
- Age: ${pet.getAge()}
- Weight: ${pet.weight != null ? '${pet.weight} kg' : 'Unknown'}
- Gender: ${pet.gender}

SUBSTANCE INGESTED:
- Name: $substanceName
- Description: $substanceDescription
- Amount: $amountIngested
- Time Since Ingestion: ${timeSinceIngestion.inMinutes} minutes ago (${timeSinceIngestion.inHours} hours)

OBSERVED SYMPTOMS:
${symptoms.map((s) => '- $s').join('\n')}

TASK:
Analyze this poisoning incident and provide a detailed assessment in JSON format with the following structure:

{
  "riskLevel": "low|moderate|high|emergency",
  "confidenceScore": 0-100,
  "urgencyMessage": "Brief urgent message (1-2 sentences)",
  "detailedExplanation": "Easy-to-understand explanation for pet owner (3-4 sentences)",
  "immediateActions": [
    "Action 1 - specific instruction",
    "Action 2 - specific instruction",
    "Action 3 - specific instruction"
  ],
  "symptoms ToMonitor": [
    "Symptom 1 to watch for",
    "Symptom 2 to watch for"
  ],
  "requiresVetVisit": true/false,
  "requiresEmergencyVet": true/false,
  "timeWindow": "How quickly to act (e.g., 'Within 30 minutes', 'Within 2 hours')",
  "prognosisIfTreated": "Expected outcome with treatment",
  "prognosisIfUntreated": "Potential consequences without treatment",
  "petOwnerGuidance": "Comforting and practical advice for the pet owner (2-3 sentences)"
}

IMPORTANT GUIDELINES:
1. Consider pet's size/weight - smaller pets are at higher risk
2. Consider time elapsed - recent ingestion may require immediate action
3. Consider symptom severity - active symptoms increase risk
4. Use clear, non-technical language that pet owners can understand
5. Be empathetic but direct about serious risks
6. Provide specific, actionable steps
7. If emergency, emphasize IMMEDIATE action needed

Respond ONLY with valid JSON, no other text.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';

      // Clean response (remove markdown code blocks if present)
      String cleanedResponse = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonResponse = json.decode(cleanedResponse);

      return PoisoningAssessmentResult.fromJson(jsonResponse);
    } catch (e) {
      print('❌ AI Assessment Error: $e');
      // Fallback to conservative assessment
      return PoisoningAssessmentResult.emergency(
        urgencyMessage: 'Unable to complete AI analysis. Please contact your veterinarian immediately as a precaution.',
        detailedExplanation: 'We encountered an issue analyzing this incident. When in doubt, it\'s always best to consult with a veterinarian, especially if your pet is showing concerning symptoms.',
      );
    }
  }

  /// Get AI-powered first aid instructions
  Future<List<String>> getFirstAidInstructions({
    required String substanceName,
    required PetModel pet,
    required RiskLevel riskLevel,
  }) async {
    try {
      final prompt = '''
You are a veterinary first aid expert. Provide step-by-step first aid instructions for a pet owner dealing with poisoning.

SITUATION:
- Pet: ${pet.name} (${pet.species}, ${pet.breed ?? 'mixed'})
- Weight: ${pet.weight ?? 'unknown'} kg
- Substance: $substanceName
- Risk Level: ${riskLevel.name.toUpperCase()}

CRITICAL FORMATTING RULES:
1. Provide 5-7 clear first aid steps
2. Each step should be SHORT and DIRECT (maximum 2 sentences)
3. Use simple everyday language
4. DO NOT use asterisks (**) or special formatting symbols
5. DO NOT use markdown formatting
6. Write in plain text only
7. Be specific and actionable
8. Focus on what the owner CAN do safely at home

Respond as a JSON array of strings:
["Step description", "Step description", ...]

Example good format:
["Move your pet away from the chocolate to prevent further ingestion", "Check if your pet is alert and breathing normally", "Call your veterinarian immediately for guidance"]

Respond ONLY with a valid JSON array, no other text or formatting.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';

      String cleanedResponse = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('**', '')
          .replaceAll('*', '')
          .trim();

      final List<dynamic> instructions = json.decode(cleanedResponse);

      // Additional cleaning of each instruction
      return instructions.map((instruction) {
        String cleaned = instruction.toString()
            .replaceAll('**', '')
            .replaceAll('*', '')
            .replaceAll('  ', ' ')
            .trim();
        return cleaned;
      }).toList();
    } catch (e) {
      print('❌ First Aid Instructions Error: $e');
      return [
        'Contact your veterinarian or emergency animal hospital immediately',
        'Do NOT induce vomiting unless instructed by a veterinarian',
        'Keep your pet calm and comfortable in a quiet area',
        'Bring the substance container or packaging to the vet if possible',
        'Note the time of ingestion and symptoms you observe',
      ];
    }
  }

  /// Get personalized pet owner guidance
  Future<String> getPersonalizedGuidance({
    required String substanceName,
    required PetModel pet,
    required List<String> symptoms,
    required RiskLevel riskLevel,
  }) async {
    try {
      final prompt = '''
You are a compassionate veterinary advisor. A pet owner is worried about their pet who ingested something toxic.

PET: ${pet.name}, a ${pet.getAge()} ${pet.species} (${pet.breed ?? 'mixed breed'})
SUBSTANCE: $substanceName
SYMPTOMS: ${symptoms.join(', ')}
RISK LEVEL: ${riskLevel.name.toUpperCase()}

Write a brief, empathetic message (2-3 sentences) for the pet owner that:
1. Acknowledges their concern
2. Provides reassurance appropriate to the risk level
3. Gives clear guidance on next steps
4. Uses warm, supportive tone

Keep it concise and focused. Speak directly to the pet owner.
Respond with ONLY the message text, no formatting or labels.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? 'Please monitor your pet closely and contact your veterinarian for guidance.';
    } catch (e) {
      print('❌ Personalized Guidance Error: $e');
      return 'We understand how concerning this is. Please monitor your pet closely and don\'t hesitate to contact your veterinarian if you have any worries.';
    }
  }
}

class PoisoningAssessmentResult {
  final RiskLevel riskLevel;
  final int confidenceScore;
  final String urgencyMessage;
  final String detailedExplanation;
  final List<String> immediateActions;
  final List<String> symptomsToMonitor;
  final bool requiresVetVisit;
  final bool requiresEmergencyVet;
  final String timeWindow;
  final String prognosisIfTreated;
  final String prognosisIfUntreated;
  final String petOwnerGuidance;

  PoisoningAssessmentResult({
    required this.riskLevel,
    required this.confidenceScore,
    required this.urgencyMessage,
    required this.detailedExplanation,
    required this.immediateActions,
    required this.symptomsToMonitor,
    required this.requiresVetVisit,
    required this.requiresEmergencyVet,
    required this.timeWindow,
    required this.prognosisIfTreated,
    required this.prognosisIfUntreated,
    required this.petOwnerGuidance,
  });

  factory PoisoningAssessmentResult.fromJson(Map<String, dynamic> json) {
    return PoisoningAssessmentResult(
      riskLevel: _parseRiskLevel(json['riskLevel'] ?? 'moderate'),
      confidenceScore: json['confidenceScore'] ?? 75,
      urgencyMessage: json['urgencyMessage'] ?? '',
      detailedExplanation: json['detailedExplanation'] ?? '',
      immediateActions: List<String>.from(json['immediateActions'] ?? []),
      symptomsToMonitor: List<String>.from(json['symptomsToMonitor'] ?? []),
      requiresVetVisit: json['requiresVetVisit'] ?? true,
      requiresEmergencyVet: json['requiresEmergencyVet'] ?? false,
      timeWindow: json['timeWindow'] ?? 'As soon as possible',
      prognosisIfTreated: json['prognosisIfTreated'] ?? '',
      prognosisIfUntreated: json['prognosisIfUntreated'] ?? '',
      petOwnerGuidance: json['petOwnerGuidance'] ?? '',
    );
  }

  static RiskLevel _parseRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'moderate':
        return RiskLevel.moderate;
      case 'high':
        return RiskLevel.high;
      case 'emergency':
        return RiskLevel.emergency;
      default:
        return RiskLevel.moderate;
    }
  }

  factory PoisoningAssessmentResult.emergency({
    required String urgencyMessage,
    required String detailedExplanation,
  }) {
    return PoisoningAssessmentResult(
      riskLevel: RiskLevel.emergency,
      confidenceScore: 90,
      urgencyMessage: urgencyMessage,
      detailedExplanation: detailedExplanation,
      immediateActions: [
        'Contact your veterinarian or emergency animal hospital immediately',
        'Do not wait for symptoms to worsen',
        'Bring the substance container if possible',
      ],
      symptomsToMonitor: [
        'Difficulty breathing',
        'Loss of consciousness',
        'Seizures',
        'Severe vomiting or diarrhea',
      ],
      requiresVetVisit: true,
      requiresEmergencyVet: true,
      timeWindow: 'IMMEDIATELY',
      prognosisIfTreated: 'Good with immediate veterinary care',
      prognosisIfUntreated: 'Potentially life-threatening',
      petOwnerGuidance: 'Please seek veterinary care immediately. Time is critical.',
    );
  }
}
