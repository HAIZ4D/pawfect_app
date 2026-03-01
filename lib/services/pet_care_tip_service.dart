import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/pet_model.dart';

/// Service for generating pet care tips using Gemini AI
class PetCareTipService {
  late GenerativeModel _model;
  bool _initialized = false;

  /// Initialize Gemini AI with API key
  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.9,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 256,
        ),
      );
      _initialized = true;
    } catch (e) {
      print('Error initializing PetCareTipService: $e');
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Generate a pet care tip based on pet information
  Future<String> generatePetCareTip(PetModel pet) async {
    if (!_initialized) {
      return _getDefaultTip(pet.species);
    }

    try {
      final ageInYears = pet.getAgeInYears();
      final ageCategory = ageInYears < 1
          ? 'young/puppy/kitten'
          : ageInYears < 7
              ? 'adult'
              : 'senior';

      final prompt = '''
You are a friendly pet care expert. Generate ONE short, helpful pet care tip.

Pet Information:
- Species: ${pet.species}
- Breed: ${pet.breed}
- Age: ${pet.getAge()} ($ageCategory)
- Weight: ${pet.weight != null ? '${pet.weight} kg' : 'unknown'}

RULES:
- Write exactly ONE tip in 1-2 sentences (max 25 words)
- Be specific to the pet's species, breed, and age
- Make it actionable and practical
- Be warm and friendly
- NO asterisks, NO bullet points, NO special formatting
- Do NOT start with "Tip:" or similar prefixes
- Just provide the tip directly

Examples of good tips:
"Regular brushing helps keep your Golden Retriever's coat shiny and reduces shedding around the house."
"Senior cats benefit from raised food bowls to reduce neck strain during meals."
"Young puppies need short, frequent play sessions to avoid overtiring."
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final tip = response.text?.trim() ?? _getDefaultTip(pet.species);

      // Clean up any formatting issues
      return tip
          .replaceAll('*', '')
          .replaceAll('Tip:', '')
          .replaceAll('tip:', '')
          .trim();
    } catch (e) {
      print('Error generating pet care tip: $e');
      return _getDefaultTip(pet.species);
    }
  }

  /// Generate a general pet care tip when no pet is selected
  Future<String> generateGeneralTip() async {
    if (!_initialized) {
      return 'Regular vet checkups help catch health issues early. Schedule one today!';
    }

    try {
      final prompt = '''
You are a friendly pet care expert. Generate ONE short, general pet care tip.

RULES:
- Write exactly ONE tip in 1-2 sentences (max 25 words)
- Make it applicable to cats or dogs
- Make it actionable and practical
- Be warm and friendly
- NO asterisks, NO bullet points, NO special formatting
- Do NOT start with "Tip:" or similar prefixes
- Just provide the tip directly
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final tip = response.text?.trim() ?? 'Fresh water and regular exercise keep your pet happy and healthy!';

      return tip
          .replaceAll('*', '')
          .replaceAll('Tip:', '')
          .replaceAll('tip:', '')
          .trim();
    } catch (e) {
      print('Error generating general tip: $e');
      return 'Fresh water and regular exercise keep your pet happy and healthy!';
    }
  }

  /// Get a default tip based on species
  String _getDefaultTip(String species) {
    final tips = {
      'Dog': [
        'Daily walks keep your dog mentally stimulated and physically fit.',
        'Regular teeth brushing prevents dental disease in dogs.',
        'Interactive toys help prevent boredom and destructive behavior.',
      ],
      'Cat': [
        'Cats need vertical space - consider adding cat shelves or a tall cat tree.',
        'Multiple water stations encourage cats to stay hydrated.',
        'Regular play sessions help maintain your cat\'s healthy weight.',
      ],
    };

    final speciesTips = tips[species] ?? tips['Dog']!;
    final index = DateTime.now().millisecond % speciesTips.length;
    return speciesTips[index];
  }
}