import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poisoning_incident_model.dart';
import '../models/poison_substance_model.dart';

class PoisoningIncidentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _incidentsCollection =
      FirebaseFirestore.instance.collection('poisoning_incidents');

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Save a new poisoning incident
  Future<String?> saveIncident(PoisoningIncidentModel incident) async {
    try {
      final docRef = await _incidentsCollection.add(incident.toFirestore());
      await docRef.update({'id': docRef.id});
      print('✅ Poisoning incident saved: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error saving incident: $e');
      return null;
    }
  }

  /// Update an existing incident (e.g., after vet visit)
  Future<bool> updateIncident(PoisoningIncidentModel incident) async {
    if (incident.id == null) return false;

    try {
      await _incidentsCollection.doc(incident.id).update(incident.toFirestore());
      print('✅ Incident updated: ${incident.id}');
      return true;
    } catch (e) {
      print('❌ Error updating incident: $e');
      return false;
    }
  }

  /// Get all incidents for a specific pet
  Future<List<PoisoningIncidentModel>> getPetIncidents(String petId) async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _incidentsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('petId', isEqualTo: petId)
          .get();

      final incidents = snapshot.docs
          .map((doc) => PoisoningIncidentModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      // Sort by incident time (most recent first)
      incidents.sort((a, b) => b.incidentTime.compareTo(a.incidentTime));

      return incidents;
    } catch (e) {
      print('❌ Error getting pet incidents: $e');
      return [];
    }
  }

  /// Get all incidents for current user
  Future<List<PoisoningIncidentModel>> getAllUserIncidents() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _incidentsCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final incidents = snapshot.docs
          .map((doc) => PoisoningIncidentModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      incidents.sort((a, b) => b.incidentTime.compareTo(a.incidentTime));

      return incidents;
    } catch (e) {
      print('❌ Error getting user incidents: $e');
      return [];
    }
  }

  /// Get incident by ID
  Future<PoisoningIncidentModel?> getIncidentById(String id) async {
    try {
      final doc = await _incidentsCollection.doc(id).get();

      if (!doc.exists) return null;

      return PoisoningIncidentModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('❌ Error getting incident: $e');
      return null;
    }
  }

  /// Delete an incident
  Future<bool> deleteIncident(String id) async {
    try {
      await _incidentsCollection.doc(id).delete();
      print('✅ Incident deleted: $id');
      return true;
    } catch (e) {
      print('❌ Error deleting incident: $e');
      return false;
    }
  }

  /// Get emergency incidents (high risk or emergency level)
  Future<List<PoisoningIncidentModel>> getEmergencyIncidents() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _incidentsCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final incidents = snapshot.docs
          .map((doc) => PoisoningIncidentModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((incident) =>
              incident.assessedRiskLevel == RiskLevel.emergency ||
              incident.assessedRiskLevel == RiskLevel.high)
          .toList();

      incidents.sort((a, b) => b.incidentTime.compareTo(a.incidentTime));

      return incidents;
    } catch (e) {
      print('❌ Error getting emergency incidents: $e');
      return [];
    }
  }
}
