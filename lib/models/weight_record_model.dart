import 'package:cloud_firestore/cloud_firestore.dart';

/// Weight Record Model for tracking pet weight over time
class WeightRecordModel {
  final String? id;
  final String petId;
  final double weight; // in kg
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;

  const WeightRecordModel({
    this.id,
    required this.petId,
    required this.weight,
    required this.date,
    this.notes,
    this.createdAt,
  });

  /// Convert weight to pounds
  double get weightInPounds => weight * 2.20462;

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'weight': weight,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory WeightRecordModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return WeightRecordModel(
      id: documentId,
      petId: data['petId'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Copy with method
  WeightRecordModel copyWith({
    String? id,
    String? petId,
    double? weight,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeightRecordModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Reminder Model for scheduling reminders
class ReminderModel {
  final String? id;
  final String petId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final ReminderType type;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const ReminderModel({
    this.id,
    required this.petId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.type,
    this.isCompleted = false,
    this.completedAt,
    this.createdAt,
  });

  /// Check if reminder is overdue
  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Check if reminder is due today
  bool get isDueToday {
    if (isCompleted) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  /// Check if reminder is due soon (within 3 days)
  bool get isDueSoon {
    if (isCompleted) return false;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue > 0 && daysUntilDue <= 3;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'type': type.name,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory ReminderModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return ReminderModel(
      id: documentId,
      petId: data['petId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      type: ReminderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReminderType.other,
      ),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Copy with method
  ReminderModel copyWith({
    String? id,
    String? petId,
    String? title,
    String? description,
    DateTime? dueDate,
    ReminderType? type,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Types of reminders
enum ReminderType {
  vaccination,
  medication,
  checkup,
  grooming,
  feeding,
  exercise,
  other,
}

/// Extension for ReminderType display
extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.vaccination:
        return 'Vaccination';
      case ReminderType.medication:
        return 'Medication';
      case ReminderType.checkup:
        return 'Check-up';
      case ReminderType.grooming:
        return 'Grooming';
      case ReminderType.feeding:
        return 'Feeding';
      case ReminderType.exercise:
        return 'Exercise';
      case ReminderType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.vaccination:
        return '💉';
      case ReminderType.medication:
        return '💊';
      case ReminderType.checkup:
        return '🏥';
      case ReminderType.grooming:
        return '✂️';
      case ReminderType.feeding:
        return '🍖';
      case ReminderType.exercise:
        return '🎾';
      case ReminderType.other:
        return '📌';
    }
  }
}
