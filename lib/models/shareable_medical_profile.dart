import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'diagnosis_model.dart';
import 'pet_model.dart';

/// Model for shareable medical profile data that can be encoded in QR code
class ShareableMedicalProfile {
  final PetModel pet;
  final List<DiagnosisModel> diagnoses;
  final DateTime sharedAt;
  final String ownerId;
  final String ownerName;

  const ShareableMedicalProfile({
    required this.pet,
    required this.diagnoses,
    required this.sharedAt,
    required this.ownerId,
    required this.ownerName,
  });

  /// Convert to JSON for QR code encoding
  Map<String, dynamic> toJson() {
    return {
      'pet': {
        'id': pet.id,
        'userId': pet.userId,
        'name': pet.name,
        'species': pet.species,
        'breed': pet.breed,
        'gender': pet.gender,
        'birthdate': pet.birthdate.toIso8601String(),
        'color': pet.color,
        'weight': pet.weight,
        'microchipId': pet.microchipId,
        'notes': pet.notes,
        'imageBase64': pet.imageBase64,
      },
      'diagnoses': diagnoses.map((d) => d.toJson()).toList(),
      'sharedAt': sharedAt.toIso8601String(),
      'ownerId': ownerId,
      'ownerName': ownerName,
    };
  }

  /// Convert to JSON string for QR code
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON (for scanning QR code)
  factory ShareableMedicalProfile.fromJson(Map<String, dynamic> json) {
    final petData = Map<String, dynamic>.from(json['pet']);

    // Convert birthdate string back to DateTime
    if (petData['birthdate'] is String) {
      petData['birthdate'] = DateTime.parse(petData['birthdate']);
    }

    return ShareableMedicalProfile(
      pet: PetModel(
        id: petData['id'],
        userId: petData['userId'] ?? '',
        name: petData['name'] ?? '',
        species: petData['species'] ?? '',
        breed: petData['breed'] ?? '',
        gender: petData['gender'] ?? '',
        birthdate: petData['birthdate'] ?? DateTime.now(),
        color: petData['color'],
        weight: petData['weight']?.toDouble(),
        microchipId: petData['microchipId'],
        notes: petData['notes'],
        imageBase64: petData['imageBase64'],
      ),
      diagnoses: (json['diagnoses'] as List)
          .map((d) => DiagnosisModel.fromJson(d))
          .toList(),
      sharedAt: DateTime.parse(json['sharedAt']),
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
    );
  }

  /// Create from JSON string (scanned from QR code)
  factory ShareableMedicalProfile.fromJsonString(String jsonString) {
    return ShareableMedicalProfile.fromJson(jsonDecode(jsonString));
  }

  /// Create a lightweight version without images for smaller QR codes
  ShareableMedicalProfile toLightweight() {
    return ShareableMedicalProfile(
      pet: pet.copyWith(imageBase64: null),
      diagnoses: diagnoses
          .map((d) => d.copyWith(
                imageUrl: null,
                imageBase64: null,
                // Keep only essential fields
                explanation: d.explanation.length > 200
                    ? '${d.explanation.substring(0, 200)}...'
                    : d.explanation,
                firstAidInstructions: d.firstAidInstructions.length > 200
                    ? '${d.firstAidInstructions.substring(0, 200)}...'
                    : d.firstAidInstructions,
              ))
          .take(5) // Limit to 5 most recent diagnoses
          .toList(),
      sharedAt: sharedAt,
      ownerId: ownerId,
      ownerName: ownerName,
    );
  }
}
