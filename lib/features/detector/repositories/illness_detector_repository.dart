import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/diagnosis_model.dart';
import 'dart:convert';

/// Repository for managing illness detection data in Firebase
/// Handles saving diagnoses (images stored as base64 in Firestore)
class IllnessDetectorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// UID of the currently signed-in user. Throws if nobody is signed in
  /// — flows that reach diagnosis save are auth-gated upstream.
  String get _currentUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'IllnessDetectorRepository accessed without a signed-in user.',
      );
    }
    return uid;
  }

  /// Reference to the diagnoses collection
  CollectionReference get _diagnosesCollection =>
      _firestore.collection('diagnoses');

  /// Save diagnosis to Firestore
  ///
  /// Returns the document ID if successful, null otherwise
  Future<String?> saveDiagnosis(DiagnosisModel diagnosis) async {
    try {
      print('💾 Saving diagnosis to Firestore...');

      final docRef = await _diagnosesCollection.add({
        ...diagnosis.toFirestore(),
        'userId': _currentUserId,
      });

      // Update with document ID
      await docRef.update({'id': docRef.id});

      print('✅ Diagnosis saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error saving diagnosis: $e');
      return null;
    }
  }

  /// Save diagnosis with image (stored as base64)
  ///
  /// Converts image to base64 and stores in Firestore
  Future<String?> saveDiagnosisWithImage(
    DiagnosisModel diagnosis,
    File imageFile,
  ) async {
    try {
      print('💾 Saving diagnosis with image to Firestore...');

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Add to Firestore with base64 image
      final docRef = await _diagnosesCollection.add({
        ...diagnosis.toFirestore(),
        'userId': _currentUserId,
        'imageBase64': base64Image,
      });

      // Update with document ID
      await docRef.update({'id': docRef.id});

      print('✅ Diagnosis with image saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error saving diagnosis with image: $e');
      return null;
    }
  }

  /// Get all diagnoses for current user
  Future<List<DiagnosisModel>> getUserDiagnoses() async {
    try {
      print('🔍 Fetching user diagnoses...');

      final querySnapshot = await _diagnosesCollection
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      final diagnoses = querySnapshot.docs
          .map((doc) => DiagnosisModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      print('✅ Loaded ${diagnoses.length} diagnoses');
      return diagnoses;
    } catch (e) {
      print('❌ Error getting user diagnoses: $e');
      return [];
    }
  }

  /// Get diagnoses for a specific pet
  Future<List<DiagnosisModel>> getPetDiagnoses(String petId) async {
    try {
      print('🔍 Fetching diagnoses for pet: $petId');

      // Simplified query without composite index requirement
      // Filter by userId and petId only, sort in memory
      final querySnapshot = await _diagnosesCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('petId', isEqualTo: petId)
          .get();

      final diagnoses = querySnapshot.docs
          .map((doc) => DiagnosisModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Sort by timestamp in memory
      diagnoses.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('✅ Loaded ${diagnoses.length} diagnoses for pet');
      return diagnoses;
    } catch (e) {
      print('❌ Error getting pet diagnoses: $e');
      return [];
    }
  }

  /// Get a single diagnosis by ID
  Future<DiagnosisModel?> getDiagnosis(String diagnosisId) async {
    try {
      final doc = await _diagnosesCollection.doc(diagnosisId).get();

      if (!doc.exists) return null;

      return DiagnosisModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('❌ Error getting diagnosis: $e');
      return null;
    }
  }

  /// Delete a diagnosis
  Future<bool> deleteDiagnosis(String diagnosisId) async {
    try {
      // Delete diagnosis document (image is stored as base64, so it's deleted too)
      await _diagnosesCollection.doc(diagnosisId).delete();

      print('✅ Diagnosis deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting diagnosis: $e');
      return false;
    }
  }

  /// Stream of user diagnoses (real-time updates)
  Stream<List<DiagnosisModel>> getUserDiagnosesStream() {
    return _diagnosesCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiagnosisModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream of pet diagnoses (real-time updates)
  Stream<List<DiagnosisModel>> getPetDiagnosesStream(String petId) {
    return _diagnosesCollection
        .where('userId', isEqualTo: _currentUserId)
        .where('petId', isEqualTo: petId)
        .snapshots()
        .map((snapshot) {
      final diagnoses = snapshot.docs
          .map((doc) => DiagnosisModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Sort by timestamp in memory
      diagnoses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return diagnoses;
    });
  }

  /// Get diagnosis statistics
  Future<Map<String, dynamic>> getDiagnosisStats() async {
    try {
      final diagnoses = await getUserDiagnoses();

      final stats = {
        'total': diagnoses.length,
        'emergency': diagnoses.where((d) => d.urgencyLevel == 'EMERGENCY').length,
        'high': diagnoses.where((d) => d.urgencyLevel == 'HIGH').length,
        'moderate': diagnoses.where((d) => d.urgencyLevel == 'MODERATE').length,
        'low': diagnoses.where((d) => d.urgencyLevel == 'LOW').length,
        'withImages': diagnoses.where((d) => d.hasImage).length,
        'withMLAnalysis': diagnoses.where((d) => d.hasMLAnalysis).length,
      };

      return stats;
    } catch (e) {
      print('❌ Error getting diagnosis stats: $e');
      return {};
    }
  }
}
