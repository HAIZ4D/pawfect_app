import '../../../models/toxic_substance_model.dart';

/// Comprehensive database of toxic substances for pets
class ToxicSubstancesDatabase {
  /// Get all toxic substances
  static List<ToxicSubstanceModel> getAllSubstances() {
    return [
      // ==================== HUMAN FOODS ====================

      // Chocolate
      ToxicSubstanceModel(
        id: 'chocolate',
        name: 'Chocolate',
        category: SubstanceCategory.food,
        description: 'Contains theobromine and caffeine which are toxic to pets. Dark chocolate and baking chocolate are most dangerous.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Vomiting',
          'Diarrhea',
          'Rapid breathing',
          'Increased heart rate',
          'Seizures',
          'Tremors',
          'Restlessness'
        ],
        immediateActions: [
          'Call Pet Poison Helpline immediately',
          'Note the type and amount consumed',
          'Do NOT induce vomiting without vet approval',
          'Take pet to emergency vet',
          'Bring chocolate packaging if possible'
        ],
        whatNotToDo: [
          'Do not wait for symptoms to appear',
          'Do not induce vomiting without guidance',
          'Do not give any home remedies'
        ],
        treatment: 'Veterinary treatment may include induced vomiting, activated charcoal, IV fluids, and monitoring.',
        induceVomiting: false, // Only under vet supervision
        timeToReact: 30,
        alternativeNames: ['Cocoa', 'Cacao'],
        keywords: ['chocolate', 'cocoa', 'cacao', 'brownie', 'candy'],
      ),

      // Grapes & Raisins
      ToxicSubstanceModel(
        id: 'grapes',
        name: 'Grapes & Raisins',
        category: SubstanceCategory.food,
        description: 'Can cause sudden kidney failure in dogs. Even small amounts can be fatal.',
        toxicityLevel: ToxicityLevel.fatal,
        symptoms: [
          'Vomiting',
          'Diarrhea',
          'Lethargy',
          'Loss of appetite',
          'Decreased urination',
          'Abdominal pain'
        ],
        immediateActions: [
          'CALL EMERGENCY VET IMMEDIATELY',
          'Induce vomiting if instructed by vet',
          'Take pet to emergency clinic within 2 hours',
          'Note amount consumed',
          'Act quickly - kidney failure can happen fast'
        ],
        whatNotToDo: [
          'Do not wait to see if symptoms develop',
          'Do not give home treatments first'
        ],
        treatment: 'Induced vomiting, activated charcoal, IV fluids, kidney function monitoring.',
        induceVomiting: true, // Under vet guidance
        timeToReact: 15,
        alternativeNames: ['Raisins', 'Sultanas', 'Currants'],
        keywords: ['grape', 'raisin', 'sultana', 'currant', 'fruit'],
      ),

      // Xylitol
      ToxicSubstanceModel(
        id: 'xylitol',
        name: 'Xylitol (Artificial Sweetener)',
        category: SubstanceCategory.food,
        description: 'Sugar-free sweetener found in gum, candy, peanut butter, and baked goods. Causes rapid insulin release.',
        toxicityLevel: ToxicityLevel.fatal,
        symptoms: [
          'Vomiting',
          'Weakness',
          'Lethargy',
          'Collapse',
          'Seizures',
          'Tremors',
          'Loss of coordination'
        ],
        immediateActions: [
          'EMERGENCY - Call vet immediately',
          'Take pet to emergency clinic NOW',
          'Bring product packaging',
          'Note time of ingestion',
          'This is life-threatening'
        ],
        whatNotToDo: [
          'Do not delay treatment',
          'Do not induce vomiting without vet guidance'
        ],
        treatment: 'IV dextrose, liver protectants, hospitalization for monitoring.',
        induceVomiting: false,
        timeToReact: 15,
        alternativeNames: ['Birch sugar', 'E967'],
        keywords: ['xylitol', 'sugar-free', 'gum', 'candy', 'sweetener'],
      ),

      // Onions & Garlic
      ToxicSubstanceModel(
        id: 'onions_garlic',
        name: 'Onions & Garlic',
        category: SubstanceCategory.food,
        description: 'Damages red blood cells and can cause anemia. All forms (raw, cooked, powder) are toxic.',
        toxicityLevel: ToxicityLevel.moderate,
        symptoms: [
          'Weakness',
          'Lethargy',
          'Pale gums',
          'Red or brown urine',
          'Vomiting',
          'Diarrhea',
          'Rapid breathing'
        ],
        immediateActions: [
          'Call your veterinarian',
          'Note the amount consumed',
          'Monitor for symptoms over next 24-48 hours',
          'Seek vet care if symptoms appear'
        ],
        whatNotToDo: [
          'Do not feed onion-containing foods',
          'Do not ignore symptoms'
        ],
        treatment: 'Supportive care, possible blood transfusion if severe.',
        induceVomiting: false,
        timeToReact: 120,
        alternativeNames: ['Garlic powder', 'Onion powder', 'Leeks', 'Chives'],
        keywords: ['onion', 'garlic', 'leek', 'chive', 'scallion'],
      ),

      // Avocado
      ToxicSubstanceModel(
        id: 'avocado',
        name: 'Avocado',
        category: SubstanceCategory.food,
        description: 'Contains persin which is toxic to many animals. The pit also poses choking hazard.',
        toxicityLevel: ToxicityLevel.moderate,
        symptoms: [
          'Vomiting',
          'Diarrhea',
          'Difficulty breathing (in birds)',
          'Fluid around heart (in birds)'
        ],
        immediateActions: [
          'Remove access to avocado',
          'Call vet if large amount consumed',
          'Monitor for symptoms',
          'Seek immediate care if pit was swallowed'
        ],
        whatNotToDo: [
          'Do not let pet chew on avocado pit'
        ],
        treatment: 'Supportive care, monitoring.',
        induceVomiting: false,
        timeToReact: 60,
        keywords: ['avocado', 'guacamole'],
      ),

      // Macadamia Nuts
      ToxicSubstanceModel(
        id: 'macadamia',
        name: 'Macadamia Nuts',
        category: SubstanceCategory.food,
        description: 'Causes weakness, tremors, and hyperthermia in dogs.',
        toxicityLevel: ToxicityLevel.moderate,
        symptoms: [
          'Weakness (especially hind legs)',
          'Vomiting',
          'Tremors',
          'Fever',
          'Depression'
        ],
        immediateActions: [
          'Call your veterinarian',
          'Note amount consumed',
          'Monitor symptoms',
          'Usually resolves in 12-48 hours'
        ],
        whatNotToDo: [
          'Do not panic - rarely fatal',
          'Do not skip vet consultation'
        ],
        treatment: 'Supportive care, pain management if needed.',
        induceVomiting: false,
        timeToReact: 60,
        keywords: ['macadamia', 'nut', 'cookie'],
      ),

      // Alcohol
      ToxicSubstanceModel(
        id: 'alcohol',
        name: 'Alcohol (Ethanol)',
        category: SubstanceCategory.food,
        description: 'Found in drinks, fermenting dough, hand sanitizer. Very dangerous for pets.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Vomiting',
          'Disorientation',
          'Loss of coordination',
          'Difficulty breathing',
          'Tremors',
          'Seizures',
          'Coma'
        ],
        immediateActions: [
          'CALL EMERGENCY VET IMMEDIATELY',
          'Do NOT induce vomiting',
          'Take pet to emergency clinic',
          'Note type and amount consumed',
          'Keep pet warm'
        ],
        whatNotToDo: [
          'Do not induce vomiting',
          'Do not give coffee or stimulants'
        ],
        treatment: 'IV fluids, monitoring, supportive care, warming.',
        induceVomiting: false,
        timeToReact: 15,
        alternativeNames: ['Beer', 'Wine', 'Liquor', 'Hand sanitizer'],
        keywords: ['alcohol', 'beer', 'wine', 'vodka', 'sanitizer'],
      ),

      // Caffeine
      ToxicSubstanceModel(
        id: 'caffeine',
        name: 'Caffeine',
        category: SubstanceCategory.food,
        description: 'Found in coffee, tea, energy drinks, diet pills. Similar to chocolate toxicity.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Restlessness',
          'Rapid breathing',
          'Heart palpitations',
          'Tremors',
          'Seizures',
          'Vomiting'
        ],
        immediateActions: [
          'Call emergency vet',
          'Take pet to clinic',
          'Bring product packaging',
          'Note time and amount consumed'
        ],
        whatNotToDo: [
          'Do not give more stimulants',
          'Do not wait for symptoms'
        ],
        treatment: 'Similar to chocolate poisoning - supportive care, IV fluids.',
        induceVomiting: false,
        timeToReact: 30,
        alternativeNames: ['Coffee', 'Tea', 'Energy drinks'],
        keywords: ['caffeine', 'coffee', 'tea', 'energy drink'],
      ),

      // ==================== PLANTS & FLOWERS ====================

      // Lilies
      ToxicSubstanceModel(
        id: 'lilies',
        name: 'Lilies',
        category: SubstanceCategory.plants,
        description: 'EXTREMELY toxic to cats. All parts including pollen can cause fatal kidney failure.',
        toxicityLevel: ToxicityLevel.fatal,
        symptoms: [
          'Vomiting',
          'Lethargy',
          'Loss of appetite',
          'Kidney failure',
          'Seizures',
          'Death'
        ],
        immediateActions: [
          'EMERGENCY FOR CATS - Call vet immediately',
          'Take cat to emergency clinic NOW',
          'Remove all lily material from mouth',
          'Treatment must start within 18 hours',
          'This is life-threatening'
        ],
        whatNotToDo: [
          'Do not delay - every minute counts',
          'Do not wait for symptoms'
        ],
        treatment: 'Decontamination, IV fluids for 48-72 hours, kidney monitoring.',
        induceVomiting: true,
        timeToReact: 15,
        alternativeNames: ['Easter lily', 'Tiger lily', 'Stargazer lily'],
        keywords: ['lily', 'flower', 'bouquet'],
      ),

      // Sago Palm
      ToxicSubstanceModel(
        id: 'sago_palm',
        name: 'Sago Palm',
        category: SubstanceCategory.plants,
        description: 'All parts are toxic, especially seeds. Causes liver failure.',
        toxicityLevel: ToxicityLevel.fatal,
        symptoms: [
          'Vomiting',
          'Diarrhea',
          'Seizures',
          'Liver failure',
          'Death'
        ],
        immediateActions: [
          'EMERGENCY - Call vet immediately',
          'Take pet to emergency clinic',
          'Induce vomiting if instructed',
          'Bring plant sample',
          '50% fatality rate even with treatment'
        ],
        whatNotToDo: [
          'Do not delay treatment',
          'Do not underestimate severity'
        ],
        treatment: 'Decontamination, aggressive IV fluids, liver support.',
        induceVomiting: true,
        timeToReact: 15,
        alternativeNames: ['Cycad palm'],
        keywords: ['sago', 'palm', 'cycad', 'plant'],
      ),

      // Tulips & Daffodils
      ToxicSubstanceModel(
        id: 'tulips_daffodils',
        name: 'Tulips & Daffodils',
        category: SubstanceCategory.plants,
        description: 'Bulbs are most toxic. Can cause serious gastrointestinal and cardiac issues.',
        toxicityLevel: ToxicityLevel.moderate,
        symptoms: [
          'Vomiting',
          'Diarrhea',
          'Drooling',
          'Cardiac arrhythmias',
          'Difficulty breathing'
        ],
        immediateActions: [
          'Remove plant material',
          'Call veterinarian',
          'Monitor for symptoms',
          'Seek care if bulb was ingested'
        ],
        whatNotToDo: [
          'Do not ignore bulb ingestion'
        ],
        treatment: 'Supportive care, cardiac monitoring if needed.',
        induceVomiting: false,
        timeToReact: 60,
        keywords: ['tulip', 'daffodil', 'narcissus', 'bulb', 'flower'],
      ),

      // Azalea & Rhododendron
      ToxicSubstanceModel(
        id: 'azalea',
        name: 'Azalea & Rhododendron',
        category: SubstanceCategory.plants,
        description: 'Contains grayanotoxins affecting heart and nervous system.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Vomiting',
          'Diarrhea',
          'Drooling',
          'Weakness',
          'Cardiac failure',
          'Coma'
        ],
        immediateActions: [
          'Call emergency vet',
          'Take pet to clinic',
          'Note amount consumed',
          'Bring plant sample'
        ],
        whatNotToDo: [
          'Do not delay treatment'
        ],
        treatment: 'Decontamination, IV fluids, cardiac monitoring.',
        induceVomiting: false,
        timeToReact: 30,
        keywords: ['azalea', 'rhododendron', 'shrub'],
      ),

      // ==================== HOUSEHOLD CHEMICALS ====================

      // Antifreeze
      ToxicSubstanceModel(
        id: 'antifreeze',
        name: 'Antifreeze (Ethylene Glycol)',
        category: SubstanceCategory.automotive,
        description: 'Sweet taste attracts pets. EXTREMELY TOXIC. Causes kidney failure.',
        toxicityLevel: ToxicityLevel.fatal,
        symptoms: [
          'Appearing drunk',
          'Vomiting',
          'Seizures',
          'Lethargy',
          'Kidney failure',
          'Death'
        ],
        immediateActions: [
          'EMERGENCY - Go to vet immediately',
          'Treatment must start within 3-8 hours',
          'Even small amounts are fatal',
          'Bring product container',
          'This is life-threatening'
        ],
        whatNotToDo: [
          'Do not wait - time is critical',
          'Do not try home treatment'
        ],
        treatment: 'Antidote (ethanol or fomepizole), IV fluids, dialysis.',
        induceVomiting: true,
        timeToReact: 15,
        alternativeNames: ['Coolant', 'Engine coolant'],
        keywords: ['antifreeze', 'coolant', 'ethylene glycol'],
      ),

      // Bleach
      ToxicSubstanceModel(
        id: 'bleach',
        name: 'Bleach (Sodium Hypochlorite)',
        category: SubstanceCategory.chemicals,
        description: 'Corrosive cleaner causing burns to mouth, throat, and stomach.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Drooling',
          'Vomiting',
          'Mouth/throat burns',
          'Difficulty breathing',
          'Pawing at mouth'
        ],
        immediateActions: [
          'Do NOT induce vomiting',
          'Rinse mouth with water',
          'Call Pet Poison Control',
          'Take pet to vet',
          'Bring product label'
        ],
        whatNotToDo: [
          'Do NOT induce vomiting (causes more damage)',
          'Do not give anything by mouth'
        ],
        treatment: 'Rinsing, protective medications, pain management.',
        induceVomiting: false,
        timeToReact: 30,
        alternativeNames: ['Chlorine bleach', 'Clorox'],
        keywords: ['bleach', 'chlorine', 'cleaner'],
      ),

      // Rat Poison (Rodenticide)
      ToxicSubstanceModel(
        id: 'rat_poison',
        name: 'Rat Poison (Rodenticides)',
        category: SubstanceCategory.pesticides,
        description: 'Various types cause different effects - bleeding, kidney failure, or seizures.',
        toxicityLevel: ToxicityLevel.fatal,
        symptoms: [
          'Bleeding (gums, nose, stool)',
          'Difficulty breathing',
          'Weakness',
          'Seizures',
          'Tremors'
        ],
        immediateActions: [
          'EMERGENCY - Call vet immediately',
          'Bring product packaging',
          'Note time of ingestion',
          'Different types need different antidotes',
          'Treatment is time-sensitive'
        ],
        whatNotToDo: [
          'Do not wait for symptoms',
          'Do not assume small amount is safe'
        ],
        treatment: 'Specific antidotes depending on type, vitamin K, blood transfusions.',
        induceVomiting: true,
        timeToReact: 30,
        alternativeNames: ['D-Con', 'Mouse poison'],
        keywords: ['rat poison', 'rodenticide', 'mouse poison'],
      ),

      // Insecticides
      ToxicSubstanceModel(
        id: 'insecticides',
        name: 'Insecticides & Pesticides',
        category: SubstanceCategory.pesticides,
        description: 'Sprays, baits, and yard treatments can be toxic.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Drooling',
          'Tremors',
          'Seizures',
          'Difficulty breathing',
          'Vomiting'
        ],
        immediateActions: [
          'Remove pet from contaminated area',
          'Call Pet Poison Control',
          'Bathe if on skin',
          'Bring product label',
          'Seek veterinary care'
        ],
        whatNotToDo: [
          'Do not let pet groom contaminated fur'
        ],
        treatment: 'Bathing, activated charcoal, seizure control, supportive care.',
        induceVomiting: false,
        timeToReact: 30,
        keywords: ['insecticide', 'pesticide', 'spray', 'bug killer'],
      ),

      // ==================== MEDICATIONS ====================

      // Ibuprofen (NSAIDs)
      ToxicSubstanceModel(
        id: 'ibuprofen',
        name: 'Ibuprofen & NSAIDs',
        category: SubstanceCategory.medications,
        description: 'Human pain medications cause stomach ulcers and kidney failure in pets.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Vomiting',
          'Bloody stool',
          'Loss of appetite',
          'Lethargy',
          'Kidney failure'
        ],
        immediateActions: [
          'Call vet or Pet Poison Control',
          'Note amount consumed',
          'Do not give more medication',
          'Seek veterinary care'
        ],
        whatNotToDo: [
          'Never give human pain meds to pets',
          'Do not assume "one pill is okay"'
        ],
        treatment: 'Decontamination, stomach protectants, IV fluids.',
        induceVomiting: true,
        timeToReact: 30,
        alternativeNames: ['Advil', 'Motrin', 'Aleve', 'Naproxen'],
        keywords: ['ibuprofen', 'advil', 'naproxen', 'aleve', 'nsaid'],
      ),

      // Acetaminophen
      ToxicSubstanceModel(
        id: 'acetaminophen',
        name: 'Acetaminophen (Tylenol)',
        category: SubstanceCategory.medications,
        description: 'EXTREMELY toxic to cats. Causes liver damage and destroys red blood cells.',
        toxicityLevel: ToxicityLevel.fatal,
        symptoms: [
          'Brown gums',
          'Difficulty breathing',
          'Swelling of face/paws',
          'Liver failure',
          'Death'
        ],
        immediateActions: [
          'EMERGENCY - especially for cats',
          'Call vet immediately',
          'Take pet to emergency clinic',
          'Note amount consumed',
          'Cats can die from ONE pill'
        ],
        whatNotToDo: [
          'NEVER give Tylenol to cats',
          'Do not delay treatment'
        ],
        treatment: 'Antidote (N-acetylcysteine), supportive care, oxygen.',
        induceVomiting: true,
        timeToReact: 15,
        alternativeNames: ['Tylenol', 'Paracetamol'],
        keywords: ['acetaminophen', 'tylenol', 'paracetamol'],
      ),

      // Antidepressants
      ToxicSubstanceModel(
        id: 'antidepressants',
        name: 'Antidepressants (SSRIs)',
        category: SubstanceCategory.medications,
        description: 'Human antidepressants cause serious neurological symptoms in pets.',
        toxicityLevel: ToxicityLevel.severe,
        symptoms: [
          'Agitation',
          'Tremors',
          'Seizures',
          'Elevated heart rate',
          'Hyperthermia'
        ],
        immediateActions: [
          'Call Pet Poison Control',
          'Take pet to vet',
          'Bring medication bottle',
          'Note time and amount consumed'
        ],
        whatNotToDo: [
          'Do not wait for symptoms'
        ],
        treatment: 'Decontamination, seizure control, cooling if needed.',
        induceVomiting: false,
        timeToReact: 30,
        alternativeNames: ['Prozac', 'Zoloft', 'Lexapro'],
        keywords: ['antidepressant', 'prozac', 'zoloft', 'ssri'],
      ),
    ];
  }

  /// Search substances by keyword
  static List<ToxicSubstanceModel> searchSubstances(String query) {
    if (query.isEmpty) return getAllSubstances();

    final queryLower = query.toLowerCase();
    return getAllSubstances().where((substance) {
      return substance.name.toLowerCase().contains(queryLower) ||
          substance.keywords.any((keyword) => keyword.contains(queryLower)) ||
          substance.alternativeNames.any((name) => name.toLowerCase().contains(queryLower));
    }).toList();
  }

  /// Get substances by category
  static List<ToxicSubstanceModel> getSubstancesByCategory(String category) {
    return getAllSubstances()
        .where((substance) => substance.category == category)
        .toList();
  }

  /// Get all categories
  static List<String> getAllCategories() {
    return [
      SubstanceCategory.food,
      SubstanceCategory.plants,
      SubstanceCategory.chemicals,
      SubstanceCategory.medications,
      SubstanceCategory.pesticides,
      SubstanceCategory.automotive,
      SubstanceCategory.other,
    ];
  }

  /// Get fatal substances
  static List<ToxicSubstanceModel> getFatalSubstances() {
    return getAllSubstances()
        .where((substance) => substance.toxicityLevel == ToxicityLevel.fatal)
        .toList();
  }
}
