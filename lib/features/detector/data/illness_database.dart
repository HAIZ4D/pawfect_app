import '../../../models/diagnosis_model.dart';

/// Database of common pet illnesses with symptom patterns
class IllnessDatabase {
  /// Get all known illnesses
  static List<IllnessPattern> getAllIllnesses() {
    return [
      // Digestive Issues
      IllnessPattern(
        name: 'Gastroenteritis (Upset Stomach)',
        symptoms: ['vomiting', 'diarrhea', 'appetite_loss', 'lethargy'],
        severity: 'moderate',
        description:
            'Inflammation of the stomach and intestines, often caused by dietary indiscretion or infections.',
        possibleCauses: [
          'Eating spoiled food or garbage',
          'Dietary changes',
          'Food intolerance',
          'Viral or bacterial infection',
          'Parasites'
        ],
        recommendations: [
          'Withhold food for 12-24 hours',
          'Provide small amounts of water frequently',
          'Feed bland diet (boiled chicken and rice)',
          'Monitor for dehydration',
          'See vet if symptoms persist beyond 24 hours'
        ],
        treatments: [
          'Anti-nausea medication',
          'Probiotics',
          'Fluid therapy if dehydrated',
          'Bland diet for 3-5 days'
        ],
        requiresVet: false,
        isEmergency: false,
      ),

      IllnessPattern(
        name: 'Gastric Dilatation-Volvulus (GDV/Bloat)',
        symptoms: ['bloating', 'restlessness', 'drooling', 'difficulty_breathing', 'collapse'],
        severity: 'emergency',
        description:
            'Life-threatening condition where the stomach fills with gas and twists, cutting off blood flow.',
        possibleCauses: [
          'Eating too quickly',
          'Exercising after large meal',
          'Breed predisposition (large, deep-chested dogs)'
        ],
        recommendations: [
          'SEEK IMMEDIATE EMERGENCY VET CARE',
          'Do not wait - this is life-threatening',
          'Do not attempt to treat at home',
          'Time is critical for survival'
        ],
        treatments: ['Emergency surgery', 'IV fluids', 'Stomach decompression'],
        requiresVet: true,
        isEmergency: true,
      ),

      // Respiratory Issues
      IllnessPattern(
        name: 'Kennel Cough',
        symptoms: ['coughing', 'sneezing', 'nasal_discharge', 'lethargy'],
        severity: 'mild',
        description:
            'Highly contagious respiratory infection causing a harsh, honking cough.',
        possibleCauses: [
          'Viral infection (parainfluenza, adenovirus)',
          'Bacterial infection (Bordetella)',
          'Exposure to infected dogs',
          'Stress or overcrowding'
        ],
        recommendations: [
          'Isolate from other pets',
          'Use humidifier to ease breathing',
          'Avoid collar pressure on throat',
          'Ensure good hydration',
          'Monitor for worsening symptoms'
        ],
        treatments: [
          'Cough suppressants',
          'Antibiotics if bacterial',
          'Rest and supportive care',
          'Usually resolves in 1-3 weeks'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      IllnessPattern(
        name: 'Upper Respiratory Infection',
        symptoms: ['sneezing', 'nasal_discharge', 'coughing', 'eye_discharge', 'appetite_loss'],
        severity: 'moderate',
        description:
            'Infection of the upper airways, common in cats and dogs, especially in shelters.',
        possibleCauses: [
          'Viral infection (herpesvirus, calicivirus)',
          'Bacterial infection',
          'Weakened immune system',
          'Stress'
        ],
        recommendations: [
          'Keep nasal passages clean',
          'Use humidifier',
          'Encourage eating with warmed, aromatic food',
          'Isolate from other pets',
          'Monitor for difficulty breathing'
        ],
        treatments: [
          'Antibiotics for secondary infections',
          'Eye drops or ointment',
          'L-lysine supplements for cats',
          'Supportive care'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      // Skin & Allergies
      IllnessPattern(
        name: 'Allergic Dermatitis',
        symptoms: ['itching', 'skin_redness', 'hair_loss', 'ear_scratching'],
        severity: 'moderate',
        description:
            'Allergic reaction causing skin inflammation, itching, and secondary infections.',
        possibleCauses: [
          'Food allergies',
          'Environmental allergies (pollen, dust)',
          'Flea allergy dermatitis',
          'Contact allergies'
        ],
        recommendations: [
          'Identify and eliminate allergen if possible',
          'Regular bathing with hypoallergenic shampoo',
          'Keep skin clean and dry',
          'Prevent scratching with cone if needed',
          'Flea prevention'
        ],
        treatments: [
          'Antihistamines',
          'Corticosteroids',
          'Antibiotics for infections',
          'Prescription diet if food allergy',
          'Immunotherapy'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      IllnessPattern(
        name: 'Hot Spots (Acute Moist Dermatitis)',
        symptoms: ['skin_redness', 'itching', 'hair_loss', 'bad_odor'],
        severity: 'moderate',
        description:
            'Localized areas of skin inflammation and infection that develop rapidly.',
        possibleCauses: [
          'Allergies',
          'Insect bites',
          'Poor grooming',
          'Moisture trapped in coat',
          'Excessive licking'
        ],
        recommendations: [
          'Clip hair around affected area',
          'Clean with antiseptic solution',
          'Keep area dry',
          'Prevent licking/scratching',
          'See vet for large or multiple spots'
        ],
        treatments: [
          'Topical antibiotics',
          'Oral antibiotics if severe',
          'Anti-inflammatory medication',
          'Elizabethan collar'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      // Urinary Issues
      IllnessPattern(
        name: 'Urinary Tract Infection (UTI)',
        symptoms: ['frequent_urination', 'straining_urinate', 'blood_urine', 'accidents'],
        severity: 'moderate',
        description:
            'Bacterial infection of the urinary tract causing pain and frequent urination.',
        possibleCauses: [
          'Bacterial infection',
          'Weakened immune system',
          'Bladder stones',
          'Diabetes',
          'Improper hygiene'
        ],
        recommendations: [
          'Increase water intake',
          'Provide frequent bathroom breaks',
          'Clean genital area',
          'Monitor urine color and frequency',
          'Collect urine sample for vet'
        ],
        treatments: [
          'Antibiotics (7-14 days)',
          'Pain medication',
          'Increased hydration',
          'Urinalysis to confirm diagnosis'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      IllnessPattern(
        name: 'Urinary Blockage',
        symptoms: ['straining_urinate', 'frequent_urination', 'vomiting', 'lethargy', 'collapse'],
        severity: 'emergency',
        description:
            'Complete or partial obstruction of urine flow - life-threatening emergency.',
        possibleCauses: [
          'Bladder stones',
          'Urethral plugs',
          'Inflammation',
          'Tumors',
          'More common in male cats'
        ],
        recommendations: [
          'SEEK IMMEDIATE EMERGENCY VET CARE',
          'This is life-threatening',
          'Bladder can rupture',
          'Toxins build up quickly in bloodstream'
        ],
        treatments: [
          'Catheterization to relieve blockage',
          'IV fluids',
          'Pain management',
          'Possible surgery'
        ],
        requiresVet: true,
        isEmergency: true,
      ),

      // Ear Issues
      IllnessPattern(
        name: 'Ear Infection (Otitis)',
        symptoms: ['ear_scratching', 'head_tilt', 'ear_discharge', 'bad_odor'],
        severity: 'moderate',
        description:
            'Inflammation and infection of the ear canal, common in dogs with floppy ears.',
        possibleCauses: [
          'Bacterial infection',
          'Yeast infection',
          'Allergies',
          'Ear mites',
          'Moisture in ears'
        ],
        recommendations: [
          'Keep ears dry',
          'Do not insert cotton swabs deep into ear',
          'Clean outer ear gently',
          'Prevent head shaking',
          'See vet for proper diagnosis'
        ],
        treatments: [
          'Ear cleaning solution',
          'Antibiotic or antifungal ear drops',
          'Oral medications if severe',
          'Address underlying allergies'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      // Parasites
      IllnessPattern(
        name: 'Intestinal Parasites (Worms)',
        symptoms: ['diarrhea', 'vomiting', 'weight_loss', 'bloating', 'appetite_loss'],
        severity: 'moderate',
        description:
            'Infestation of intestinal worms affecting nutrient absorption and health.',
        possibleCauses: [
          'Ingesting contaminated soil or feces',
          'Fleas (tapeworms)',
          'Eating infected prey',
          'Mother to puppy transmission'
        ],
        recommendations: [
          'Regular deworming schedule',
          'Fecal testing',
          'Clean up feces immediately',
          'Prevent hunting behavior',
          'Flea prevention'
        ],
        treatments: [
          'Deworming medication',
          'Repeat treatment in 2-3 weeks',
          'Treat all pets in household',
          'Environmental cleaning'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      // Poisoning
      IllnessPattern(
        name: 'Toxin Ingestion / Poisoning',
        symptoms: ['vomiting', 'diarrhea', 'seizures', 'tremors', 'drooling', 'difficulty_breathing'],
        severity: 'emergency',
        description:
            'Ingestion of toxic substances requiring immediate veterinary attention.',
        possibleCauses: [
          'Chocolate, grapes, xylitol',
          'Household chemicals',
          'Medications',
          'Toxic plants',
          'Antifreeze, rodent poison'
        ],
        recommendations: [
          'CALL POISON CONTROL OR EMERGENCY VET IMMEDIATELY',
          'Identify the toxin if possible',
          'Bring product packaging to vet',
          'Do not induce vomiting unless directed',
          'Time is critical'
        ],
        treatments: [
          'Activated charcoal',
          'Gastric lavage',
          'IV fluids',
          'Antidotes if available',
          'Supportive care'
        ],
        requiresVet: true,
        isEmergency: true,
      ),

      // Arthritis
      IllnessPattern(
        name: 'Arthritis / Joint Pain',
        symptoms: ['limping', 'stiffness', 'reluctance', 'swelling', 'lethargy'],
        severity: 'moderate',
        description:
            'Degenerative joint disease causing pain and reduced mobility.',
        possibleCauses: [
          'Age-related wear and tear',
          'Previous injuries',
          'Obesity',
          'Breed predisposition',
          'Developmental issues'
        ],
        recommendations: [
          'Weight management',
          'Low-impact exercise',
          'Orthopedic bed',
          'Joint supplements',
          'Warm, comfortable environment'
        ],
        treatments: [
          'NSAIDs for pain',
          'Joint supplements (glucosamine)',
          'Physical therapy',
          'Laser therapy',
          'Surgery in severe cases'
        ],
        requiresVet: true,
        isEmergency: false,
      ),

      // Diabetes
      IllnessPattern(
        name: 'Diabetes Mellitus',
        symptoms: ['excessive_drinking', 'frequent_urination', 'weight_loss', 'appetite_increase'],
        severity: 'severe',
        description:
            'Chronic condition where the body cannot properly regulate blood sugar.',
        possibleCauses: [
          'Pancreatic insufficiency',
          'Obesity',
          'Genetics',
          'Certain medications',
          'Other hormonal diseases'
        ],
        recommendations: [
          'Consistent feeding schedule',
          'Regular exercise routine',
          'Monitor water intake',
          'Watch for signs of hypoglycemia',
          'Regular vet checkups'
        ],
        treatments: [
          'Insulin injections',
          'Prescription diet',
          'Blood glucose monitoring',
          'Weight management',
          'Lifelong management'
        ],
        requiresVet: true,
        isEmergency: false,
      ),
    ];
  }

  /// Analyze symptoms and return possible diagnoses
  static List<DiagnosisModel> analyzeSymptoms(List<String> selectedSymptomIds) {
    final illnesses = getAllIllnesses();
    final diagnoses = <DiagnosisModel>[];

    for (final illness in illnesses) {
      // Calculate how many symptoms match
      final matchedSymptoms = illness.symptoms
          .where((symptom) => selectedSymptomIds.contains(symptom))
          .toList();

      if (matchedSymptoms.isEmpty) continue;

      // Calculate confidence score
      final confidence = matchedSymptoms.length / illness.symptoms.length;

      // Only include if confidence is reasonable (at least 30% match)
      if (confidence >= 0.3) {
        diagnoses.add(DiagnosisModel(
          condition: illness.name,
          explanation: illness.description,
          confidence: confidence,
          urgencyLevel: illness.severity,
          symptoms: matchedSymptoms,
          riskFactors: illness.possibleCauses,
          recommendations: illness.recommendations,
          firstAidInstructions: illness.treatments.join('\n'),
          vetReport: '',
          timestamp: DateTime.now(),
        ));
      }
    }

    // Sort by confidence score (highest first)
    diagnoses.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    return diagnoses;
  }
}

/// Pattern for matching symptoms to illnesses
class IllnessPattern {
  final String name;
  final List<String> symptoms; // Symptom IDs
  final String severity;
  final String description;
  final List<String> possibleCauses;
  final List<String> recommendations;
  final List<String> treatments;
  final bool requiresVet;
  final bool isEmergency;

  IllnessPattern({
    required this.name,
    required this.symptoms,
    required this.severity,
    required this.description,
    required this.possibleCauses,
    required this.recommendations,
    required this.treatments,
    required this.requiresVet,
    required this.isEmergency,
  });
}
