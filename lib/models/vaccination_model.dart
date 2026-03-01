import 'package:cloud_firestore/cloud_firestore.dart';

/// Vaccination Record Model
class VaccinationModel {
  final String? id;
  final String petId;
  final String vaccineName;
  final DateTime dateGiven;
  final DateTime? nextDueDate;
  final String? veterinarianName;
  final String? clinic;
  final String? batchNumber;
  final String? notes;
  final DateTime? createdAt;

  const VaccinationModel({
    this.id,
    required this.petId,
    required this.vaccineName,
    required this.dateGiven,
    this.nextDueDate,
    this.veterinarianName,
    this.clinic,
    this.batchNumber,
    this.notes,
    this.createdAt,
  });

  /// Check if vaccination is overdue
  bool get isOverdue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  /// Check if vaccination is due soon (within 30 days)
  bool get isDueSoon {
    if (nextDueDate == null) return false;
    final daysUntilDue = nextDueDate!.difference(DateTime.now()).inDays;
    return daysUntilDue > 0 && daysUntilDue <= 30;
  }

  /// Get days until next due date
  int? get daysUntilDue {
    if (nextDueDate == null) return null;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'vaccineName': vaccineName,
      'dateGiven': Timestamp.fromDate(dateGiven),
      'nextDueDate': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'veterinarianName': veterinarianName,
      'clinic': clinic,
      'batchNumber': batchNumber,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory VaccinationModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return VaccinationModel(
      id: documentId,
      petId: data['petId'] ?? '',
      vaccineName: data['vaccineName'] ?? '',
      dateGiven: (data['dateGiven'] as Timestamp).toDate(),
      nextDueDate: data['nextDueDate'] != null
          ? (data['nextDueDate'] as Timestamp).toDate()
          : null,
      veterinarianName: data['veterinarianName'],
      clinic: data['clinic'],
      batchNumber: data['batchNumber'],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Copy with method
  VaccinationModel copyWith({
    String? id,
    String? petId,
    String? vaccineName,
    DateTime? dateGiven,
    DateTime? nextDueDate,
    String? veterinarianName,
    String? clinic,
    String? batchNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return VaccinationModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      vaccineName: vaccineName ?? this.vaccineName,
      dateGiven: dateGiven ?? this.dateGiven,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      veterinarianName: veterinarianName ?? this.veterinarianName,
      clinic: clinic ?? this.clinic,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Common vaccination types
class VaccinationType {
  static const String rabies = 'Rabies';
  static const String dhpp = 'DHPP (Distemper, Hepatitis, Parvovirus, Parainfluenza)';
  static const String bordetella = 'Bordetella (Kennel Cough)';
  static const String lyme = 'Lyme Disease';
  static const String canineInfluenza = 'Canine Influenza';
  static const String fvrcp = 'FVRCP (Feline Distemper)';
  static const String felv = 'FeLV (Feline Leukemia)';
  static const String fiv = 'FIV (Feline Immunodeficiency Virus)';

  static List<String> getAllTypes() {
    return [
      rabies,
      dhpp,
      bordetella,
      lyme,
      canineInfluenza,
      fvrcp,
      felv,
      fiv,
    ];
  }

  static List<String> getDogVaccinations() {
    return [rabies, dhpp, bordetella, lyme, canineInfluenza];
  }

  static List<String> getCatVaccinations() {
    return [rabies, fvrcp, felv, fiv];
  }
}
