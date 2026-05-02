import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/pet_model.dart';
import '../models/symptom_model.dart';

/// Service for Gemini AI integration
/// Handles multimodal image analysis, human-friendly explanations,
/// first-aid instructions, and vet reports (all powered by Gemini 2.5 Flash).
class GeminiService {
  late GenerativeModel _model;
  bool _initialized = false;

  /// Initialize Gemini AI with API key
  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
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
      final petName = pet?.name ?? 'your pet';
      final petContext = pet != null
          ? '${pet.name} — ${pet.species}, ${pet.breed}, age ${_calculateAge(pet.birthdate)}'
          : 'pet (no profile provided)';

      final symptomsList = symptoms.isNotEmpty
          ? symptoms.map((s) => s.name).join(', ')
          : 'no specific symptoms reported';

      final mlContext = mlResults != null
          ? 'Visible findings on the photo: ${mlResults['detectedConditions']?.join(', ') ?? 'None'}. ${mlResults['analysis'] ?? ''}'
          : 'No photo analysed.';

      final prompt = '''
You are an experienced veterinarian explaining a diagnosis to a worried but capable pet owner. Be warm, specific, and educational. Do NOT defer everything to "see your vet" — first explain the condition fully, then guide them on next steps.

Pet: $petContext
Reported symptoms: $symptomsList
Diagnosed condition: $condition
Urgency level: $urgencyLevel
$mlContext

Write a substantive explanation about "$condition" specifically for $petName. Cover, in this order, as flowing paragraphs:

1. WHAT IT IS — Define $condition in 1–2 plain-language sentences. Avoid jargon; if a medical term is needed, define it briefly.
2. COMMON CAUSES — Name 2–4 specific likely causes for this condition in this species (diet, environment, infection type, allergens, parasites, behavioural triggers, breed predisposition, age, etc.). Be concrete.
3. WHAT TO EXPECT — Describe how this condition typically progresses if cared for properly, and what worsening looks like.
4. WHAT THIS MEANS FOR $petName — Connect the condition back to the symptoms reported. Tell the owner what the symptoms are telling you.

STRICT RULES:
- 200–280 words total.
- Plain text only. NO asterisks, NO markdown, NO bullet points, NO numbered headers in the output.
- Use the pet's name when natural.
- Be specific to "$condition" — generic content is unacceptable.
- End on a calm, action-oriented sentence (not "see a vet immediately" unless urgency is EMERGENCY).
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

      final symptomNote = symptoms.isNotEmpty
          ? 'The owner reports: ${symptoms.map((s) => s.name).join(', ')}.'
          : '';

      final prompt = '''
You are a veterinary first-aid expert. The pet owner has just been told their $petContext likely has "$condition" (urgency: $urgencyLevel). They need specific, practical home-care steps they can do RIGHT NOW with what they have at home.

$symptomNote

Provide 5–6 numbered steps tailored to "$condition". Each step must:
- Begin with a clear action (verb-first).
- Include a brief reason WHY it helps, in the same line.
- Be specific to this condition — not generic pet care.

FORMAT EACH STEP EXACTLY LIKE THIS:
"1. [Action sentence]. [One short clause explaining why this helps]."

LENGTH: 20–40 words per step.

URGENCY RULES:
- If EMERGENCY: Step 1 must be "Get to an emergency vet now. [reason — what's at stake]." Then provide 4 more stabilization steps to do during transport.
- If HIGH: Step 1 should be "Call your vet within the hour. [reason]." Then 4 more home-care steps for tonight.
- Otherwise: All steps are home-care; mention the vet only in the final step if relevant.

OUTPUT RULES:
- Plain text only. NO asterisks, NO markdown, NO headers.
- Use a clean numbered list: "1. ..." "2. ..." each on its own line.
- No preamble before step 1, no closing summary after the last step.
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
- Detection Method: AI-Assisted Illness Detection (Gemini 2.5 Flash multimodal)

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

  /// Multimodal image analysis using Gemini 2.5 Flash vision.
  ///
  /// Sends the pet photo to Gemini and asks it to detect visible
  /// health issues (skin infections, wounds, parasites, eye abnormalities).
  /// Returns a map shaped like the old ML inference output so downstream
  /// code can consume it unchanged.
  Future<Map<String, dynamic>> analyzeImage(File imageFile, {PetModel? pet}) async {
    if (!_initialized) {
      throw Exception('Gemini AI not initialized. Call initialize() first.');
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final petContext = pet != null
          ? '${pet.species} (${pet.breed}), age ${_calculateAge(pet.birthdate)}'
          : 'pet (species unknown)';

      final prompt = '''
You are a veterinary vision AI. Analyze this photo of a $petContext and
identify any visible health issues in these categories:
- Skin Infection
- Wound/Injury
- Parasites (Fleas/Ticks)
- Eye Abnormality

Respond with ONLY valid JSON, no markdown fences, in this exact shape:
{
  "detections": [
    {"condition": "<one of the four categories>", "confidence": 0.0-1.0, "severity": "LOW|MODERATE|HIGH"}
  ],
  "analysis": "<one short sentence describing what you observed>"
}

If nothing abnormal is visible, return an empty "detections" array and an
analysis sentence saying so. Only include a detection if confidence >= 0.6.
''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      return _parseVisionResponse(response.text ?? '');
    } catch (e) {
      print('Error during Gemini vision analysis: $e');
      return _emptyVisionResult('Image analysis failed. Diagnosis based on symptoms only.');
    }
  }

  Map<String, dynamic> _parseVisionResponse(String raw) {
    try {
      var text = raw.trim();
      if (text.contains('```json')) {
        text = text.split('```json')[1].split('```')[0].trim();
      } else if (text.contains('```')) {
        text = text.split('```')[1].split('```')[0].trim();
      }

      final decoded = json.decode(text) as Map<String, dynamic>;
      final detections = (decoded['detections'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final detectedConditions = detections
          .map((d) => d['condition']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toList();
      final confidenceScores = <String, double>{};
      for (final d in detections) {
        final c = d['condition']?.toString();
        final conf = (d['confidence'] as num?)?.toDouble();
        if (c != null && conf != null) confidenceScores[c] = conf;
      }

      detections.sort((a, b) =>
          ((b['confidence'] as num?) ?? 0).compareTo((a['confidence'] as num?) ?? 0));

      return {
        'hasDetections': detections.isNotEmpty,
        'detectedConditions': detectedConditions,
        'detections': detections,
        'confidenceScores': confidenceScores,
        'topCondition': detections.isNotEmpty ? detections.first['condition'] : null,
        'topConfidence': detections.isNotEmpty
            ? ((detections.first['confidence'] as num?)?.toDouble() ?? 0.0)
            : 0.0,
        'analysis': decoded['analysis']?.toString() ??
            'No significant visual abnormalities detected.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Could not parse Gemini vision JSON: $e');
      return _emptyVisionResult('Unable to parse image analysis response.');
    }
  }

  Map<String, dynamic> _emptyVisionResult(String note) => {
        'hasDetections': false,
        'detectedConditions': <String>[],
        'detections': <Map<String, dynamic>>[],
        'confidenceScores': <String, double>{},
        'topCondition': null,
        'topConfidence': 0.0,
        'analysis': note,
        'timestamp': DateTime.now().toIso8601String(),
      };

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

      final symptomsList = symptoms.isNotEmpty
          ? symptoms.map((s) => '${s.name} (${s.category})').join(', ')
          : 'No specific symptoms reported';

      final mlContext = mlResults != null && mlResults.isNotEmpty
          ? 'Visual findings: ${mlResults['detectedConditions']?.join(', ') ?? 'None detected'}. Notes: ${mlResults['analysis'] ?? 'N/A'}'
          : 'No visual analysis available';

      final prompt = '''
You are a veterinary diagnostic AI. Identify the SPECIFIC most likely condition. Generic answers are unacceptable — never return "Skin Issue", "Unknown", "Analysis Complete", or "Condition Detected". Always commit to a named veterinary condition.

Context: $petContext
Symptoms: $symptomsList
$mlContext

Return ONLY valid JSON. No prose. No markdown fences. No commentary.

Schema:
{
  "mostLikelyCondition": "<specific named condition, e.g. 'Feline Acne', 'Otitis Externa', 'Allergic Contact Dermatitis', 'Flea Allergy Dermatitis'>",
  "urgencyLevel": "EMERGENCY" | "HIGH" | "MODERATE" | "LOW",
  "confidence": <number between 0.0 and 1.0>,
  "riskFactors": ["<specific concerning sign>", "<another>", ...],
  "recommendations": ["<specific actionable home-care or vet step — NOT 'see a vet' or 'monitor symptoms' alone>", ...]
}

Rules:
- "mostLikelyCondition" must be a real veterinary condition name. If uncertain between two, pick the more probable one.
- Recommendations must be SPECIFIC and useful (e.g. "Clean the affected ear daily with a vet-approved otic solution", not "monitor symptoms"). Provide 4–6 recommendations.
- riskFactors should call out specific symptoms or visual findings that escalate concern.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      try {
        String jsonText = responseText.trim();
        if (jsonText.contains('```json')) {
          jsonText = jsonText.split('```json')[1].split('```')[0].trim();
        } else if (jsonText.contains('```')) {
          jsonText = jsonText.split('```')[1].split('```')[0].trim();
        }

        final decoded = json.decode(jsonText) as Map<String, dynamic>;
        final condition = decoded['mostLikelyCondition']?.toString().trim();
        final urgency = decoded['urgencyLevel']?.toString().toUpperCase().trim();

        return {
          'mostLikelyCondition': (condition == null || condition.isEmpty)
              ? 'Condition needs clinical evaluation'
              : condition,
          'urgencyLevel': _normalizeUrgency(urgency),
          'confidence': (decoded['confidence'] as num?)?.toDouble() ?? 0.6,
          'riskFactors': (decoded['riskFactors'] as List? ?? [])
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList(),
          'recommendations': (decoded['recommendations'] as List? ?? [])
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList(),
          'rawResponse': responseText,
        };
      } catch (e) {
        print('⚠️ analyzeCondition JSON parse failed: $e');
        return {
          'mostLikelyCondition': 'Condition needs clinical evaluation',
          'urgencyLevel': 'MODERATE',
          'confidence': 0.5,
          'riskFactors': <String>[],
          'recommendations': <String>[],
          'rawResponse': responseText,
        };
      }
    } catch (e) {
      print('❌ Error analyzing condition: $e');
      rethrow;
    }
  }

  String _normalizeUrgency(String? raw) {
    if (raw == null) return 'MODERATE';
    const allowed = {'EMERGENCY', 'HIGH', 'MODERATE', 'LOW'};
    return allowed.contains(raw) ? raw : 'MODERATE';
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
