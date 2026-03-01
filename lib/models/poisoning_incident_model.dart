import 'package:cloud_firestore/cloud_firestore.dart';
import 'poison_substance_model.dart';

class PoisoningIncidentModel {
  final String? id;
  final String userId;
  final String petId;
  final String petName;
  final String substanceName;
  final PoisonCategory category;
  final RiskLevel assessedRiskLevel;
  final List<String> symptoms;
  final String amountIngested;
  final DateTime incidentTime;
  final String firstAidGiven;
  final bool vetContacted;
  final String? vetNotes;
  final String? pdfReportBase64;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PoisoningIncidentModel({
    this.id,
    required this.userId,
    required this.petId,
    required this.petName,
    required this.substanceName,
    required this.category,
    required this.assessedRiskLevel,
    required this.symptoms,
    required this.amountIngested,
    required this.incidentTime,
    this.firstAidGiven = '',
    this.vetContacted = false,
    this.vetNotes,
    this.pdfReportBase64,
    required this.createdAt,
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

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'petId': petId,
      'petName': petName,
      'substanceName': substanceName,
      'category': category.name,
      'assessedRiskLevel': assessedRiskLevel.name,
      'symptoms': symptoms,
      'amountIngested': amountIngested,
      'incidentTime': Timestamp.fromDate(incidentTime),
      'firstAidGiven': firstAidGiven,
      'vetContacted': vetContacted,
      'vetNotes': vetNotes,
      'pdfReportBase64': pdfReportBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory PoisoningIncidentModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return PoisoningIncidentModel(
      id: docId,
      userId: data['userId'] ?? '',
      petId: data['petId'] ?? '',
      petName: data['petName'] ?? '',
      substanceName: data['substanceName'] ?? '',
      category: PoisonCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => PoisonCategory.householdItems,
      ),
      assessedRiskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == data['assessedRiskLevel'],
        orElse: () => RiskLevel.moderate,
      ),
      symptoms: List<String>.from(data['symptoms'] ?? []),
      amountIngested: data['amountIngested'] ?? '',
      incidentTime: (data['incidentTime'] as Timestamp).toDate(),
      firstAidGiven: data['firstAidGiven'] ?? '',
      vetContacted: data['vetContacted'] ?? false,
      vetNotes: data['vetNotes'],
      pdfReportBase64: data['pdfReportBase64'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  PoisoningIncidentModel copyWith({
    String? id,
    String? userId,
    String? petId,
    String? petName,
    String? substanceName,
    PoisonCategory? category,
    RiskLevel? assessedRiskLevel,
    List<String>? symptoms,
    String? amountIngested,
    DateTime? incidentTime,
    String? firstAidGiven,
    bool? vetContacted,
    String? vetNotes,
    String? pdfReportBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PoisoningIncidentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      substanceName: substanceName ?? this.substanceName,
      category: category ?? this.category,
      assessedRiskLevel: assessedRiskLevel ?? this.assessedRiskLevel,
      symptoms: symptoms ?? this.symptoms,
      amountIngested: amountIngested ?? this.amountIngested,
      incidentTime: incidentTime ?? this.incidentTime,
      firstAidGiven: firstAidGiven ?? this.firstAidGiven,
      vetContacted: vetContacted ?? this.vetContacted,
      vetNotes: vetNotes ?? this.vetNotes,
      pdfReportBase64: pdfReportBase64 ?? this.pdfReportBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
