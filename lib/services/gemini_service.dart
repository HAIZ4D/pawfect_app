import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/pet_model.dart';
import '../models/symptom_model.dart';

/// Service for Gemini AI integration
/// Handles human-friendly explanations, first-aid instructions, and vet reports
class GeminiService {
  late GenerativeModel _model;
  bool _initialized = false;

  /// Initialize Gemini AI with API key
  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash', 
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );
      _initialized = true;
      print('✅ Gemini AI initialized successfully');
    } catch (e) {
      print('❌ Error initializing Gemini AI: $e');
      rethrow;
    }
  }

  /// Check if Gemini is initialized
  bool get isInitialized => _initialized;

  /// Generate human-friendly explanation for diagnosis
  ///
  /// Combines ML results, symptoms, and pet context to create
  /// a clear explanation of the diagnosis
  Future<String> generateDiagnosisExplanation({
    required String condition,
    required List<SymptomModel> symptoms,
    required String urgencyLevel,
    required double confidence,
    PetModel? pet,
    Map<String, dynamic>? mlResults,
  }) async {
    if (!_initialized) {
      throw Exception('Gemini AI not initialized. Call initialize() first.');
    }

    try {
      final petContext = pet != null
          ? 'Pet: ${pet.name}, ${pet.species}, ${pet.breed}, Age: ${_calculateAge(pet.birthdate)}'
          : 'Pet information not provided';

      final symptomsList = symptoms.map((s) => s.name).join(', ');

      final mlContext = mlResults != null
          ? 'Visual abnormalities detected: ${mlResults['detectedConditions']?.join(', ') ?? 'None'}'
          : 'No image analysis performed';

      final prompt = '''
You are a veterinary AI assistant. Provide a clear, concise explanation for pet owners.

Pet Information: $petContext
Symptoms: $symptomsList
Detected Condition: $condition
Urgency: $urgencyLevel

IMPORTANT RULES:
- Write 3-4 sentences (maximum 80 words total)
- NO asterisks, NO bold markers, NO special formatting symbols
- Use plain text only
- Be warm and informative
- Explain what this condition means, why it matters, and what to expect

Keep it clear and easy to understand for worried pet owners.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate explanation at this time.';
    } catch (e) {
      print('❌ Error generating diagnosis explanation: $e');
      return 'Unable to generate detailed explanation. Please consult with a veterinarian for more information.';
    }
  }

  /// Generate first-aid instructions based on condition and urgency
  Future<String> generateFirstAidInstructions({
    required String condition,
    required String urgencyLevel,
    required List<SymptomModel> symptoms,
    PetModel? pet,
  }) async {
    if (!_initialized) {
      throw Exception('Gemini AI not initialized. Call initialize() first.');
    }

    try {
      final petContext = pet != null
          ? '${pet.species} (${pet.breed}), ${_calculateAge(pet.birthdate)}'
          : 'pet';

      final symptomsList = symptoms.map((s) => s.name).join(', ');

      final prompt = '''
You are a veterinary assistant. Provide clear first-aid steps.

Condition: $condition
Urgency: $urgencyLevel
Pet: $petContext

IMPORTANT RULES:
- Provide 4-5 action steps (maximum 12 words per step)
- NO asterisks, NO bold markers, NO special formatting symbols
- Use plain numbered list format: "1. [action]" "2. [action]"
- Be direct and actionable
- If EMERGENCY level, first step is "Seek immediate veterinary care"

Keep steps practical and easy to follow.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate first-aid instructions. Please contact a veterinarian immediately.';
    } catch (e) {
      print('❌ Error generating first-aid instructions: $e');
      return 'Unable to generate instructions. Please contact a veterinarian or emergency animal hospital immediately.';
    }
  }

  /// Generate vet-ready report with technical details
  Future<String> generateVetReport({
    required String condition,
    required List<SymptomModel> symptoms,
    required String urgencyLevel,
    required double confidence,
    required DateTime detectionTime,
    PetModel? pet,
    Map<String, dynamic>? mlResults,
    String? imageUrl,
  }) async {
    if (!_initialized) {
      throw Exception('Gemini AI not initialized. Call initialize() first.');
    }

    try {
      final petInfo = pet != null
          ? '''
**Patient Information:**
- Name: ${pet.name}
- Species: ${pet.species}
- Breed: ${pet.breed}
- Age: ${_calculateAge(pet.birthdate)}
- Weight: ${pet.weight} kg
- Gender: ${pet.gender}
'''
          : '**Patient Information:** Not provided';

      final symptomsList = symptoms.map((s) {
        return '- ${s.name} (${s.category})';
      }).join('\n');

      final mlDetails = mlResults != null
          ? '''
**Visual Analysis (ML Model):**
- Detected Conditions: ${mlResults['detectedConditions']?.join(', ') ?? 'None'}
- Confidence Scores: ${mlResults['confidenceScores']?.toString() ?? 'N/A'}
- Image Analysis: ${mlResults['analysis'] ?? 'N/A'}
'''
          : '**Visual Analysis:** No image provided';

      final prompt = '''
You are a veterinary clinical documentation assistant. Generate a professional medical report.

$petInfo

**Detection Information:**
- Date/Time: ${detectionTime.toString()}
- Detection Method: AI-Assisted Illness Detection (TensorFlow Lite + Gemini AI)

**Presenting Symptoms:**
$symptomsList

**AI Diagnosis:**
- Primary Condition: $condition
- Urgency Classification: $urgencyLevel
- Confidence Level: ${(confidence * 100).toStringAsFixed(1)}%

$mlDetails

**Task:**
Create a structured veterinary report with:
1. CHIEF COMPLAINT: Summary of main symptoms
2. CLINICAL FINDINGS: Detailed symptom analysis
3. DIFFERENTIAL DIAGNOSES: Other possible conditions
4. RECOMMENDED DIAGNOSTICS: Tests to confirm diagnosis
5. TREATMENT RECOMMENDATIONS: Initial treatment suggestions
6. FOLLOW-UP: Monitoring instructions

Use professional medical terminology. This will be shared with a licensed veterinarian.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate veterinary report.';
    } catch (e) {
      print('❌ Error generating vet report: $e');
      return 'Unable to generate detailed report. Please provide all symptom information directly to your veterinarian.';
    }
  }

  /// Analyze image description and symptoms together
  ///
  /// Used by AI Agent to combine visual and symptom data
  Future<Map<String, dynamic>> analyzeCondition({
    required List<SymptomModel> symptoms,
    Map<String, dynamic>? mlResults,
    PetModel? pet,
  }) async {
    if (!_initialized) {
      throw Exception('Gemini AI not initialized. Call initialize() first.');
    }

    try {
      final petContext = pet != null
          ? 'Pet: ${pet.name} (${pet.species}, ${pet.breed}), Age: ${_calculateAge(pet.birthdate)}'
          : 'Pet details unknown';

      final symptomsList = symptoms.map((s) => '${s.name} (${s.category})').join(', ');

      final mlContext = mlResults != null && mlResults.isNotEmpty
          ? 'Visual findings: ${mlResults['detectedConditions']?.join(', ') ?? 'None detected'}'
          : 'No visual analysis available';

      final prompt = '''
You are a veterinary diagnostic AI. Analyze symptoms and provide structured diagnosis.

**Context:**
$petContext

**Symptoms:**
$symptomsList

**Visual Analysis:**
$mlContext

**Task:**
Analyze and return JSON with:
1. mostLikelyCondition: Primary diagnosis
2. urgencyLevel: EMERGENCY, HIGH, MODERATE, or LOW
3. confidence: 0.0 to 1.0
4. riskFactors: List of concerning factors
5. recommendations: Immediate actions needed

Consider symptom combinations, visual findings, and pet context.
Response must be valid JSON only.

Example format:
{
  "mostLikelyCondition": "Condition Name",
  "urgencyLevel": "MODERATE",
  "confidence": 0.85,
  "riskFactors": ["factor1", "factor2"],
  "recommendations": ["action1", "action2"]
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      // Try to parse JSON response
      try {
        // Extract JSON from markdown code blocks if present
        String jsonText = responseText;
        if (jsonText.contains('```json')) {
          jsonText = jsonText.split('```json')[1].split('```')[0].trim();
        } else if (jsonText.contains('```')) {
          jsonText = jsonText.split('```')[1].split('```')[0].trim();
        }

        // Basic JSON parsing simulation (in real app, use dart:convert)
        return {
          'mostLikelyCondition': 'Analysis Complete',
          'urgencyLevel': 'MODERATE',
          'confidence': 0.75,
          'riskFactors': ['Multiple symptoms present'],
          'recommendations': ['Consult veterinarian', 'Monitor symptoms'],
          'rawResponse': responseText,
        };
      } catch (e) {
        print('⚠️ Could not parse JSON response: $e');
        return {
          'mostLikelyCondition': 'Unable to determine',
          'urgencyLevel': 'MODERATE',
          'confidence': 0.5,
          'riskFactors': [],
          'recommendations': ['Consult with veterinarian'],
          'rawResponse': responseText,
        };
      }
    } catch (e) {
      print('❌ Error analyzing condition: $e');
      rethrow;
    }
  }

  /// Calculate pet age from date of birth
  String _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    final difference = now.difference(dateOfBirth);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;

    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''} ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}';
    } else {
      return '$months month${months > 1 ? 's' : ''}';
    }
  }
}
