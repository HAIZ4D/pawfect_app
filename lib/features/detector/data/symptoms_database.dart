import '../../../models/symptom_model.dart';

/// Database of common pet symptoms
class SymptomsDatabase {
  static List<SymptomModel> getAllSymptoms() {
    return [
      // Behavioral Symptoms
      const SymptomModel(
        id: 'lethargy',
        name: 'Lethargy / Weakness',
        category: SymptomCategory.behavioral,
        description: 'Unusual tiredness, lack of energy, or reluctance to move',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'appetite_loss',
        name: 'Loss of Appetite',
        category: SymptomCategory.behavioral,
        description: 'Not eating or eating significantly less than usual',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'excessive_drinking',
        name: 'Excessive Thirst',
        category: SymptomCategory.behavioral,
        description: 'Drinking much more water than normal',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'aggression',
        name: 'Unusual Aggression',
        category: SymptomCategory.behavioral,
        description: 'Sudden aggressive behavior or irritability',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'restlessness',
        name: 'Restlessness / Anxiety',
        category: SymptomCategory.behavioral,
        description: 'Unable to settle, pacing, or excessive whining',
        severity: SeverityLevel.mild,
      ),
      const SymptomModel(
        id: 'hiding',
        name: 'Hiding / Withdrawal',
        category: SymptomCategory.behavioral,
        description: 'Seeking isolation or hiding more than usual',
        severity: SeverityLevel.mild,
      ),

      // Digestive Symptoms
      const SymptomModel(
        id: 'vomiting',
        name: 'Vomiting',
        category: SymptomCategory.digestive,
        description: 'Throwing up food, bile, or other substances',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'diarrhea',
        name: 'Diarrhea',
        category: SymptomCategory.digestive,
        description: 'Loose or watery stools',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'bloody_stool',
        name: 'Blood in Stool',
        category: SymptomCategory.digestive,
        description: 'Visible blood in feces',
        severity: SeverityLevel.severe,
      ),
      const SymptomModel(
        id: 'constipation',
        name: 'Constipation',
        category: SymptomCategory.digestive,
        description: 'Difficulty or inability to defecate',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'bloating',
        name: 'Bloating / Distended Abdomen',
        category: SymptomCategory.digestive,
        description: 'Swollen or enlarged abdomen',
        severity: SeverityLevel.severe,
      ),
      const SymptomModel(
        id: 'drooling',
        name: 'Excessive Drooling',
        category: SymptomCategory.digestive,
        description: 'More saliva production than normal',
        severity: SeverityLevel.mild,
      ),

      // Respiratory Symptoms
      const SymptomModel(
        id: 'coughing',
        name: 'Coughing',
        category: SymptomCategory.respiratory,
        description: 'Persistent or frequent coughing',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'sneezing',
        name: 'Sneezing',
        category: SymptomCategory.respiratory,
        description: 'Frequent sneezing',
        severity: SeverityLevel.mild,
      ),
      const SymptomModel(
        id: 'difficulty_breathing',
        name: 'Difficulty Breathing',
        category: SymptomCategory.respiratory,
        description: 'Labored breathing, wheezing, or gasping',
        severity: SeverityLevel.emergency,
      ),
      const SymptomModel(
        id: 'nasal_discharge',
        name: 'Nasal Discharge',
        category: SymptomCategory.respiratory,
        description: 'Runny nose or mucus from nostrils',
        severity: SeverityLevel.mild,
      ),

      // Skin & Coat Symptoms
      const SymptomModel(
        id: 'itching',
        name: 'Excessive Itching',
        category: SymptomCategory.skin,
        description: 'Constant scratching, licking, or biting skin',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'hair_loss',
        name: 'Hair Loss',
        category: SymptomCategory.skin,
        description: 'Bald patches or thinning coat',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'skin_redness',
        name: 'Red or Inflamed Skin',
        category: SymptomCategory.skin,
        description: 'Redness, rash, or inflammation',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'lumps',
        name: 'Lumps or Bumps',
        category: SymptomCategory.skin,
        description: 'Unusual growths or swellings on body',
        severity: SeverityLevel.severe,
      ),
      const SymptomModel(
        id: 'bad_odor',
        name: 'Unusual Odor',
        category: SymptomCategory.skin,
        description: 'Strong or foul smell from skin or ears',
        severity: SeverityLevel.mild,
      ),

      // Urinary Symptoms
      const SymptomModel(
        id: 'frequent_urination',
        name: 'Frequent Urination',
        category: SymptomCategory.urinary,
        description: 'Urinating more often than usual',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'blood_urine',
        name: 'Blood in Urine',
        category: SymptomCategory.urinary,
        description: 'Pink, red, or brown colored urine',
        severity: SeverityLevel.severe,
      ),
      const SymptomModel(
        id: 'straining_urinate',
        name: 'Straining to Urinate',
        category: SymptomCategory.urinary,
        description: 'Difficulty or pain when urinating',
        severity: SeverityLevel.severe,
      ),
      const SymptomModel(
        id: 'accidents',
        name: 'House Accidents',
        category: SymptomCategory.urinary,
        description: 'Urinating indoors when house-trained',
        severity: SeverityLevel.mild,
      ),

      // Neurological Symptoms
      const SymptomModel(
        id: 'seizures',
        name: 'Seizures',
        category: SymptomCategory.neurological,
        description: 'Convulsions, tremors, or loss of consciousness',
        severity: SeverityLevel.emergency,
      ),
      const SymptomModel(
        id: 'disorientation',
        name: 'Disorientation / Confusion',
        category: SymptomCategory.neurological,
        description: 'Appearing lost, confused, or unresponsive',
        severity: SeverityLevel.severe,
      ),
      const SymptomModel(
        id: 'head_tilt',
        name: 'Head Tilt',
        category: SymptomCategory.neurological,
        description: 'Holding head at an angle',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'tremors',
        name: 'Tremors / Shaking',
        category: SymptomCategory.neurological,
        description: 'Uncontrolled shaking or trembling',
        severity: SeverityLevel.moderate,
      ),

      // Physical Symptoms
      const SymptomModel(
        id: 'limping',
        name: 'Limping / Lameness',
        category: SymptomCategory.physical,
        description: 'Favoring one leg or difficulty walking',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'swelling',
        name: 'Swelling / Inflammation',
        category: SymptomCategory.physical,
        description: 'Swollen joints, paws, or body parts',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'fever',
        name: 'Fever',
        category: SymptomCategory.physical,
        description: 'Hot to touch, warm nose, or elevated temperature',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'weight_loss',
        name: 'Weight Loss',
        category: SymptomCategory.physical,
        description: 'Significant weight loss without diet change',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'weight_gain',
        name: 'Weight Gain',
        category: SymptomCategory.physical,
        description: 'Rapid or unexplained weight increase',
        severity: SeverityLevel.mild,
      ),
      const SymptomModel(
        id: 'pale_gums',
        name: 'Pale Gums',
        category: SymptomCategory.physical,
        description: 'White or very pale gum color',
        severity: SeverityLevel.severe,
      ),
      const SymptomModel(
        id: 'yellow_eyes',
        name: 'Yellow Eyes or Gums',
        category: SymptomCategory.physical,
        description: 'Yellowing of eyes or gums (jaundice)',
        severity: SeverityLevel.severe,
      ),

      // Eye & Ear Symptoms
      const SymptomModel(
        id: 'eye_discharge',
        name: 'Eye Discharge',
        category: SymptomCategory.physical,
        description: 'Mucus or pus from eyes',
        severity: SeverityLevel.mild,
      ),
      const SymptomModel(
        id: 'red_eyes',
        name: 'Red or Bloodshot Eyes',
        category: SymptomCategory.physical,
        description: 'Redness in or around eyes',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'ear_scratching',
        name: 'Ear Scratching',
        category: SymptomCategory.physical,
        description: 'Persistent ear scratching or head shaking',
        severity: SeverityLevel.mild,
      ),
      const SymptomModel(
        id: 'ear_discharge',
        name: 'Ear Discharge',
        category: SymptomCategory.physical,
        description: 'Fluid or debris from ears',
        severity: SeverityLevel.moderate,
      ),

      // Other Symptoms
      const SymptomModel(
        id: 'bad_breath',
        name: 'Bad Breath',
        category: SymptomCategory.other,
        description: 'Unusually strong or foul breath odor',
        severity: SeverityLevel.mild,
      ),
      const SymptomModel(
        id: 'panting',
        name: 'Excessive Panting',
        category: SymptomCategory.other,
        description: 'Heavy panting when not hot or exercising',
        severity: SeverityLevel.moderate,
      ),
      const SymptomModel(
        id: 'collapse',
        name: 'Collapse / Fainting',
        category: SymptomCategory.other,
        description: 'Sudden collapse or loss of consciousness',
        severity: SeverityLevel.emergency,
      ),
    ];
  }

  /// Get symptoms by category
  static List<SymptomModel> getSymptomsByCategory(String category) {
    return getAllSymptoms()
        .where((symptom) => symptom.category == category)
        .toList();
  }

  /// Get all unique categories
  static List<String> getAllCategories() {
    return [
      SymptomCategory.behavioral,
      SymptomCategory.digestive,
      SymptomCategory.respiratory,
      SymptomCategory.skin,
      SymptomCategory.urinary,
      SymptomCategory.neurological,
      SymptomCategory.physical,
      SymptomCategory.other,
    ];
  }

  /// Get emergency symptoms
  static List<SymptomModel> getEmergencySymptoms() {
    return getAllSymptoms()
        .where((symptom) => symptom.severity == SeverityLevel.emergency)
        .toList();
  }
}
