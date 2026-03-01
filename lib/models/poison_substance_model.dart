import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskLevel {
  low,
  moderate,
  high,
  emergency,
}

enum PoisonCategory {
  toxicFoods,
  plants,
  medicines,
  chemicals,
  householdItems,
}

class PoisonSubstanceModel {
  final String? id;
  final String name;
  final PoisonCategory category;
  final List<String> alternativeNames;
  final List<String> commonSymptoms;
  final RiskLevel defaultRiskLevel;
  final String description;
  final List<String> firstAidSteps;
  final List<String> emergencyActions;
  final String? antidote;
  final bool requiresImmediateVetVisit;
  final Map<String, dynamic>? toxicityInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PoisonSubstanceModel({
    this.id,
    required this.name,
    required this.category,
    this.alternativeNames = const [],
    required this.commonSymptoms,
    required this.defaultRiskLevel,
    required this.description,
    required this.firstAidSteps,
    this.emergencyActions = const [],
    this.antidote,
    this.requiresImmediateVetVisit = false,
    this.toxicityInfo,
    this.createdAt,
    this.updatedAt,
  });

  String get categoryName {
    switch (category) {
      case PoisonCategory.toxicFoods:
        return 'Toxic Foods';
      case PoisonCategory.plants:
        return 'Plants';
      case PoisonCategory.medicines:
        return 'Medicines';
      case PoisonCategory.chemicals:
        return 'Chemicals';
      case PoisonCategory.householdItems:
        return 'Household Items';
    }
  }

  String get riskLevelName {
    switch (defaultRiskLevel) {
      case RiskLevel.low:
        return 'Low Risk - Monitor at home';
      case RiskLevel.moderate:
        return 'Moderate Risk - Close monitoring, prepare for vet visit';
      case RiskLevel.high:
        return 'High Risk - Immediate vet visit required';
      case RiskLevel.emergency:
        return 'Emergency - Urgent veterinary care needed NOW';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category.name,
      'alternativeNames': alternativeNames,
      'commonSymptoms': commonSymptoms,
      'defaultRiskLevel': defaultRiskLevel.name,
      'description': description,
      'firstAidSteps': firstAidSteps,
      'emergencyActions': emergencyActions,
      'antidote': antidote,
      'requiresImmediateVetVisit': requiresImmediateVetVisit,
      'toxicityInfo': toxicityInfo,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory PoisonSubstanceModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return PoisonSubstanceModel(
      id: docId,
      name: data['name'] ?? '',
      category: PoisonCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => PoisonCategory.householdItems,
      ),
      alternativeNames: List<String>.from(data['alternativeNames'] ?? []),
      commonSymptoms: List<String>.from(data['commonSymptoms'] ?? []),
      defaultRiskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == data['defaultRiskLevel'],
        orElse: () => RiskLevel.moderate,
      ),
      description: data['description'] ?? '',
      firstAidSteps: List<String>.from(data['firstAidSteps'] ?? []),
      emergencyActions: List<String>.from(data['emergencyActions'] ?? []),
      antidote: data['antidote'],
      requiresImmediateVetVisit: data['requiresImmediateVetVisit'] ?? false,
      toxicityInfo: data['toxicityInfo'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
