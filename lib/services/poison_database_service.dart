import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poison_substance_model.dart';

class PoisonDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _poisonsCollection =
      FirebaseFirestore.instance.collection('poisons');

  /// Search poisons by name or alternative names
  Future<List<PoisonSubstanceModel>> searchPoisons(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();

    try {
      final snapshot = await _poisonsCollection.get();

      final poisons = snapshot.docs
          .map((doc) => PoisonSubstanceModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((poison) {
        return poison.name.toLowerCase().contains(queryLower) ||
            poison.alternativeNames
                .any((name) => name.toLowerCase().contains(queryLower));
      }).toList();

      return poisons;
    } catch (e) {
      print('Error searching poisons: $e');
      return [];
    }
  }

  /// Get poisons by category
  Future<List<PoisonSubstanceModel>> getPoisonsByCategory(
      PoisonCategory category) async {
    try {
      final snapshot = await _poisonsCollection
          .where('category', isEqualTo: category.name)
          .get();

      return snapshot.docs
          .map((doc) => PoisonSubstanceModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting poisons by category: $e');
      return [];
    }
  }

  /// Get poison by ID
  Future<PoisonSubstanceModel?> getPoisonById(String id) async {
    try {
      final doc = await _poisonsCollection.doc(id).get();

      if (!doc.exists) return null;

      return PoisonSubstanceModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error getting poison by ID: $e');
      return null;
    }
  }

  /// Get all emergency-level poisons
  Future<List<PoisonSubstanceModel>> getEmergencyPoisons() async {
    try {
      final snapshot = await _poisonsCollection
          .where('defaultRiskLevel', isEqualTo: RiskLevel.emergency.name)
          .get();

      return snapshot.docs
          .map((doc) => PoisonSubstanceModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting emergency poisons: $e');
      return [];
    }
  }

  /// Initialize database with default poisons (call this once to seed data)
  Future<void> seedPoisonDatabase() async {
    final defaultPoisons = _getDefaultPoisons();

    for (final poison in defaultPoisons) {
      await _poisonsCollection.add(poison.toFirestore());
    }
  }

  List<PoisonSubstanceModel> _getDefaultPoisons() {
    return [
      // Toxic Foods
      PoisonSubstanceModel(
        name: 'Chocolate',
        category: PoisonCategory.toxicFoods,
        alternativeNames: ['Cocoa', 'Cacao'],
        commonSymptoms: ['Vomiting', 'Diarrhea', 'Rapid heartbeat', 'Seizures', 'Hyperactivity'],
        defaultRiskLevel: RiskLevel.high,
        description: 'Contains theobromine which is toxic to pets. Dark chocolate is more dangerous than milk chocolate.',
        firstAidSteps: [
          'Remove any remaining chocolate immediately',
          'DO NOT induce vomiting unless instructed by vet',
          'Note the type and amount consumed',
          'Contact vet immediately',
        ],
        emergencyActions: ['Call emergency vet', 'Bring chocolate wrapper to vet'],
        requiresImmediateVetVisit: true,
        toxicityInfo: {'toxic_dose': '20mg/kg for mild symptoms, 100mg/kg for severe'},
      ),
      PoisonSubstanceModel(
        name: 'Grapes',
        category: PoisonCategory.toxicFoods,
        alternativeNames: ['Raisins', 'Currants'],
        commonSymptoms: ['Vomiting', 'Diarrhea', 'Lethargy', 'Loss of appetite', 'Kidney failure'],
        defaultRiskLevel: RiskLevel.emergency,
        description: 'Can cause acute kidney failure in dogs and cats. Even small amounts can be toxic.',
        firstAidSteps: [
          'Contact vet immediately - even if pet seems fine',
          'Note quantity consumed and time',
          'Monitor for vomiting or unusual behavior',
          'DO NOT wait for symptoms to appear',
        ],
        emergencyActions: ['Immediate vet visit required', 'May need IV fluids and hospitalization'],
        requiresImmediateVetVisit: true,
      ),
      PoisonSubstanceModel(
        name: 'Onions',
        category: PoisonCategory.toxicFoods,
        alternativeNames: ['Garlic', 'Leeks', 'Chives', 'Shallots'],
        commonSymptoms: ['Weakness', 'Pale gums', 'Vomiting', 'Diarrhea', 'Breathing difficulty'],
        defaultRiskLevel: RiskLevel.high,
        description: 'Contains compounds that damage red blood cells, causing anemia.',
        firstAidSteps: [
          'Stop feeding any products containing onions/garlic',
          'Monitor for weakness or pale gums',
          'Contact vet for guidance',
          'Symptoms may appear days after ingestion',
        ],
        requiresImmediateVetVisit: true,
      ),
      PoisonSubstanceModel(
        name: 'Xylitol',
        category: PoisonCategory.toxicFoods,
        alternativeNames: ['Sugar-free sweetener', 'Birch sugar'],
        commonSymptoms: ['Weakness', 'Seizures', 'Collapse', 'Tremors', 'Liver failure'],
        defaultRiskLevel: RiskLevel.emergency,
        description: 'Found in sugar-free gum, candy, and baked goods. Extremely toxic, causes rapid insulin release.',
        firstAidSteps: [
          'EMERGENCY - Contact vet immediately',
          'Note product name and amount consumed',
          'Check blood sugar if possible',
          'Do not delay treatment',
        ],
        emergencyActions: ['Immediate emergency vet visit', 'May need IV glucose'],
        requiresImmediateVetVisit: true,
      ),

      // Plants
      PoisonSubstanceModel(
        name: 'Lilies',
        category: PoisonCategory.plants,
        alternativeNames: ['Easter Lily', 'Tiger Lily', 'Asiatic Lily'],
        commonSymptoms: ['Vomiting', 'Lethargy', 'Loss of appetite', 'Kidney failure'],
        defaultRiskLevel: RiskLevel.emergency,
        description: 'Extremely toxic to cats. All parts of the plant are poisonous, even small amounts can be fatal.',
        firstAidSteps: [
          'EMERGENCY for cats - immediate vet visit',
          'Bring plant sample if possible',
          'Note time of exposure',
          'Do not wait for symptoms',
        ],
        emergencyActions: ['Immediate hospitalization may be needed', 'Activated charcoal treatment'],
        requiresImmediateVetVisit: true,
      ),
      PoisonSubstanceModel(
        name: 'Sago Palm',
        category: PoisonCategory.plants,
        alternativeNames: ['Cycad', 'Coontie Palm'],
        commonSymptoms: ['Vomiting', 'Diarrhea', 'Seizures', 'Liver failure', 'Death'],
        defaultRiskLevel: RiskLevel.emergency,
        description: 'All parts are toxic, especially seeds. Can be fatal even with aggressive treatment.',
        firstAidSteps: [
          'EMERGENCY - Call vet immediately',
          'Bring plant sample',
          'Note which parts were ingested',
          'Time is critical',
        ],
        emergencyActions: ['Immediate vet treatment required', 'May need hospitalization'],
        requiresImmediateVetVisit: true,
      ),

      // Medicines
      PoisonSubstanceModel(
        name: 'Ibuprofen',
        category: PoisonCategory.medicines,
        alternativeNames: ['Advil', 'Motrin', 'Nurofen'],
        commonSymptoms: ['Vomiting', 'Diarrhea', 'Stomach ulcers', 'Kidney damage', 'Seizures'],
        defaultRiskLevel: RiskLevel.high,
        description: 'Human pain medication that is highly toxic to pets. Never give to pets.',
        firstAidSteps: [
          'Contact vet immediately',
          'Note number of pills consumed',
          'Do not induce vomiting without vet approval',
          'Bring medication bottle to vet',
        ],
        requiresImmediateVetVisit: true,
      ),
      PoisonSubstanceModel(
        name: 'Paracetamol',
        category: PoisonCategory.medicines,
        alternativeNames: ['Acetaminophen', 'Tylenol', 'Panadol'],
        commonSymptoms: ['Difficulty breathing', 'Brown gums', 'Swelling', 'Liver damage'],
        defaultRiskLevel: RiskLevel.emergency,
        description: 'Extremely toxic, especially to cats. Can cause liver damage and death.',
        firstAidSteps: [
          'EMERGENCY - Contact vet immediately',
          'Note dosage and time of ingestion',
          'Bring medication packaging',
          'Treatment must start quickly',
        ],
        antidote: 'N-acetylcysteine (NAC) if given early',
        requiresImmediateVetVisit: true,
      ),

      // Chemicals
      PoisonSubstanceModel(
        name: 'Antifreeze',
        category: PoisonCategory.chemicals,
        alternativeNames: ['Ethylene glycol', 'Coolant'],
        commonSymptoms: ['Drunken behavior', 'Vomiting', 'Seizures', 'Kidney failure', 'Death'],
        defaultRiskLevel: RiskLevel.emergency,
        description: 'Sweet taste attracts pets. Extremely toxic, small amounts can be fatal. Time-sensitive emergency.',
        firstAidSteps: [
          'EMERGENCY - Immediate vet visit required',
          'Note time of exposure',
          'Every minute counts',
          'May need antidote within hours',
        ],
        antidote: 'Fomepizole or ethanol (must be given early)',
        emergencyActions: ['Rush to emergency vet', 'Call ahead so they can prepare'],
        requiresImmediateVetVisit: true,
      ),
      PoisonSubstanceModel(
        name: 'Bleach',
        category: PoisonCategory.chemicals,
        alternativeNames: ['Sodium hypochlorite', 'Chlorine bleach'],
        commonSymptoms: ['Drooling', 'Vomiting', 'Mouth burns', 'Difficulty breathing'],
        defaultRiskLevel: RiskLevel.high,
        description: 'Corrosive chemical that can burn mouth, throat, and stomach.',
        firstAidSteps: [
          'DO NOT induce vomiting',
          'Rinse mouth with water if possible',
          'Contact vet immediately',
          'Do not give milk or food',
        ],
        requiresImmediateVetVisit: true,
      ),

      // Household Items
      PoisonSubstanceModel(
        name: 'Batteries',
        category: PoisonCategory.householdItems,
        alternativeNames: ['Button batteries', 'Lithium batteries'],
        commonSymptoms: ['Drooling', 'Mouth burns', 'Vomiting', 'Abdominal pain'],
        defaultRiskLevel: RiskLevel.emergency,
        description: 'Can cause burns and blockages. Button batteries are especially dangerous.',
        firstAidSteps: [
          'EMERGENCY - Immediate vet visit',
          'X-ray needed to locate battery',
          'Do not induce vomiting',
          'Time is critical',
        ],
        emergencyActions: ['May need surgery to remove', 'Risk of perforation'],
        requiresImmediateVetVisit: true,
      ),
    ];
  }
}
