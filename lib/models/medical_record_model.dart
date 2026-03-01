import 'package:cloud_firestore/cloud_firestore.dart';

/// Medical Record Model
class MedicalRecordModel {
  final String? id;
  final String petId;
  final DateTime date;
  final RecordType recordType;
  final String title;
  final String? description;
  final String? veterinarianName;
  final String? clinic;
  final String? diagnosis;
  final String? treatment;
  final String? medications;
  final double? cost;
  final List<String>? attachments; // Base64 encoded images or document references
  final DateTime? createdAt;

  const MedicalRecordModel({
    this.id,
    required this.petId,
    required this.date,
    required this.recordType,
    required this.title,
    this.description,
    this.veterinarianName,
    this.clinic,
    this.diagnosis,
    this.treatment,
    this.medications,
    this.cost,
    this.attachments,
    this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'date': Timestamp.fromDate(date),
      'recordType': recordType.name,
      'title': title,
      'description': description,
      'veterinarianName': veterinarianName,
      'clinic': clinic,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'medications': medications,
      'cost': cost,
      'attachments': attachments,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory MedicalRecordModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return MedicalRecordModel(
      id: documentId,
      petId: data['petId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      recordType: RecordType.values.firstWhere(
        (e) => e.name == data['recordType'],
        orElse: () => RecordType.general,
      ),
      title: data['title'] ?? '',
      description: data['description'],
      veterinarianName: data['veterinarianName'],
      clinic: data['clinic'],
      diagnosis: data['diagnosis'],
      treatment: data['treatment'],
      medications: data['medications'],
      cost: data['cost']?.toDouble(),
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Copy with method
  MedicalRecordModel copyWith({
    String? id,
    String? petId,
    DateTime? date,
    RecordType? recordType,
    String? title,
    String? description,
    String? veterinarianName,
    String? clinic,
    String? diagnosis,
    String? treatment,
    String? medications,
    double? cost,
    List<String>? attachments,
    DateTime? createdAt,
  }) {
    return MedicalRecordModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      recordType: recordType ?? this.recordType,
      title: title ?? this.title,
      description: description ?? this.description,
      veterinarianName: veterinarianName ?? this.veterinarianName,
      clinic: clinic ?? this.clinic,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      medications: medications ?? this.medications,
      cost: cost ?? this.cost,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Types of medical records
enum RecordType {
  general,
  checkup,
  emergency,
  surgery,
  dental,
  vaccination,
  labResults,
  prescription,
  other,
}

/// Extension for RecordType display
extension RecordTypeExtension on RecordType {
  String get displayName {
    switch (this) {
      case RecordType.general:
        return 'General Visit';
      case RecordType.checkup:
        return 'Check-up';
      case RecordType.emergency:
        return 'Emergency';
      case RecordType.surgery:
        return 'Surgery';
      case RecordType.dental:
        return 'Dental';
      case RecordType.vaccination:
        return 'Vaccination';
      case RecordType.labResults:
        return 'Lab Results';
      case RecordType.prescription:
        return 'Prescription';
      case RecordType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case RecordType.general:
        return '🏥';
      case RecordType.checkup:
        return '✅';
      case RecordType.emergency:
        return '🚨';
      case RecordType.surgery:
        return '🔪';
      case RecordType.dental:
        return '🦷';
      case RecordType.vaccination:
        return '💉';
      case RecordType.labResults:
        return '🔬';
      case RecordType.prescription:
        return '💊';
      case RecordType.other:
        return '📋';
    }
  }
}
