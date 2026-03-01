import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Pet Model with Base64 image storage for Firestore
class PetModel {
  final String? id;
  final String userId;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final DateTime birthdate;
  final String? color;
  final double? weight;
  final String? microchipId;
  final String? notes;
  final String? imageBase64; // Store image as Base64 string in Firestore
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PetModel({
    this.id,
    required this.userId,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.birthdate,
    this.color,
    this.weight,
    this.microchipId,
    this.notes,
    this.imageBase64,
    this.createdAt,
    this.updatedAt,
  });

  /// Calculate pet's age as a readable string
  String getAge() {
    final now = DateTime.now();
    final age = now.difference(birthdate);

    if (age.inDays < 30) {
      return '${age.inDays} days old';
    } else if (age.inDays < 365) {
      final months = (age.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} old';
    } else {
      final years = (age.inDays / 365).floor();
      final months = ((age.inDays % 365) / 30).floor();
      if (months > 0) {
        return '$years ${years == 1 ? 'year' : 'years'}, $months ${months == 1 ? 'month' : 'months'} old';
      }
      return '$years ${years == 1 ? 'year' : 'years'} old';
    }
  }

  /// Get age in years (for calculations)
  int getAgeInYears() {
    return DateTime.now().difference(birthdate).inDays ~/ 365;
  }

  /// Decode Base64 image to display
  Widget getDecodedImage() {
    if (imageBase64 == null || imageBase64!.isEmpty) {
      return const Icon(Icons.pets, size: 50);
    }

    try {
      final Uint8List bytes = base64Decode(imageBase64!);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.pets, size: 50);
        },
      );
    } catch (e) {
      return const Icon(Icons.pets, size: 50);
    }
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'birthdate': Timestamp.fromDate(birthdate),
      'color': color,
      'weight': weight,
      'microchipId': microchipId,
      'notes': notes,
      'imageBase64': imageBase64,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory PetModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return PetModel(
      id: documentId,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      species: data['species'] ?? '',
      breed: data['breed'] ?? '',
      gender: data['gender'] ?? '',
      birthdate: data['birthdate'] is Timestamp
          ? (data['birthdate'] as Timestamp).toDate()
          : DateTime.now(),
      color: data['color'],
      weight: data['weight']?.toDouble(),
      microchipId: data['microchipId'],
      notes: data['notes'],
      imageBase64: data['imageBase64'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Copy with method for updating fields
  PetModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? breed,
    String? gender,
    DateTime? birthdate,
    String? color,
    double? weight,
    String? microchipId,
    String? notes,
    String? imageBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      microchipId: microchipId ?? this.microchipId,
      notes: notes ?? this.notes,
      imageBase64: imageBase64 ?? this.imageBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
