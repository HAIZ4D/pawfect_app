import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/pet_model.dart';
import '../../../core/utils/image_processor.dart';

/// Repository for managing pet data in Firestore
/// Handles CRUD operations and image storage using Base64 encoding
class PetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// UID of the currently signed-in user. Throws if nobody is signed in
  /// — the AuthGate prevents home-screen flows from being reached
  /// without auth, so a null here is a programmer error worth surfacing.
  String get _currentUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'PetRepository accessed without a signed-in user. '
        'Ensure AuthGate has authenticated the user before calling.',
      );
    }
    return uid;
  }

  /// Reference to the pets collection
  CollectionReference get _petsCollection => _firestore.collection('pets');

  /// Add a new pet to Firestore
  ///
  /// Takes a [PetModel] and optional [imageFile]
  /// Returns the pet ID if successful, null otherwise
  Future<String?> addPet(PetModel pet, {File? imageFile}) async {
    try {
      // Process image if provided
      String? base64Image;
      if (imageFile != null) {
        base64Image = await ImageProcessor.compressAndConvertToBase64(imageFile);
      }

      // Create pet with image
      final petData = pet.copyWith(
        userId: _currentUserId,
        imageBase64: base64Image,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to Firestore
      final docRef = await _petsCollection.add(petData.toFirestore());

      // Update with document ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error adding pet: $e');
      return null;
    }
  }

  /// Update an existing pet
  ///
  /// Takes a [PetModel] and optional [imageFile]
  /// Returns true if successful, false otherwise
  Future<bool> updatePet(PetModel pet, {File? imageFile}) async {
    try {
      if (pet.id == null) {
        throw Exception('Pet ID is null');
      }

      // Process new image if provided
      String? base64Image = pet.imageBase64;
      if (imageFile != null) {
        base64Image = await ImageProcessor.compressAndConvertToBase64(imageFile);
      }

      // Create updated pet data
      final petData = pet.copyWith(
        imageBase64: base64Image,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _petsCollection.doc(pet.id).update(petData.toFirestore());

      return true;
    } catch (e) {
      print('Error updating pet: $e');
      return false;
    }
  }

  /// Delete a pet from Firestore
  ///
  /// Takes a [petId]
  /// Returns true if successful, false otherwise
  Future<bool> deletePet(String petId) async {
    try {
      await _petsCollection.doc(petId).delete();
      return true;
    } catch (e) {
      print('Error deleting pet: $e');
      return false;
    }
  }

  /// Get a single pet by ID
  ///
  /// Returns [PetModel] if found, null otherwise
  Future<PetModel?> getPet(String petId) async {
    try {
      final doc = await _petsCollection.doc(petId).get();

      if (!doc.exists) return null;

      return PetModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error getting pet: $e');
      return null;
    }
  }

  /// Get all pets for the current user
  ///
  /// Returns a list of [PetModel]
  Future<List<PetModel>> getUserPets() async {
    try {
      print('🔵 Fetching pets for user: $_currentUserId');

      // Temporarily remove orderBy to avoid index issues
      final querySnapshot = await _petsCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      print('🔵 Query returned ${querySnapshot.docs.length} documents');

      final pets = querySnapshot.docs
          .map((doc) {
            print('🔵 Processing pet document: ${doc.id}');
            return PetModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          })
          .toList();

      print('🟢 Successfully loaded ${pets.length} pets');
      return pets;
    } catch (e) {
      print('🔴 Error getting user pets: $e');
      print('🔴 Error type: ${e.runtimeType}');
      rethrow; // Rethrow to see error in provider
    }
  }

  /// Stream of all pets for the current user (real-time updates)
  ///
  /// Returns a [Stream] of [List<PetModel>]
  Stream<List<PetModel>> getUserPetsStream() {
    return _petsCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Search pets by name
  ///
  /// Takes a [query] string
  /// Returns a list of [PetModel] matching the query
  Future<List<PetModel>> searchPets(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final querySnapshot = await _petsCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      // Filter by name (Firestore doesn't support case-insensitive search)
      return querySnapshot.docs
          .map((doc) => PetModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((pet) => pet.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching pets: $e');
      return [];
    }
  }

  /// Filter pets by species
  ///
  /// Takes a [species] string (e.g., 'Dog', 'Cat')
  /// Returns a list of [PetModel] of that species
  Future<List<PetModel>> filterPetsBySpecies(String species) async {
    try {
      if (species.isEmpty) {
        return [];
      }

      final querySnapshot = await _petsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('species', isEqualTo: species)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error filtering pets by species: $e');
      return [];
    }
  }
}
