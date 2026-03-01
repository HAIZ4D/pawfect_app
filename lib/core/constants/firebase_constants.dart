/// Firebase Collection and Field Names
class FirebaseConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String petsCollection = 'pets';
  static const String medicalRecordsCollection = 'medical_records';
  static const String illnessDetectionsCollection = 'illness_detections';
  static const String poisonIncidentsCollection = 'poison_incidents';
  static const String poisonDatabaseCollection = 'poison_database';
  static const String veterinaryClinicsCollection = 'veterinary_clinics';

  // User Fields
  static const String userEmail = 'email';
  static const String userDisplayName = 'displayName';
  static const String userPhoneNumber = 'phoneNumber';
  static const String userProfileImageUrl = 'profileImageUrl';
  static const String userCreatedAt = 'createdAt';
  static const String userLastLoginAt = 'lastLoginAt';

  // Pet Fields
  static const String petOwnerId = 'ownerId';
  static const String petName = 'name';
  static const String petSpecies = 'species';
  static const String petBreed = 'breed';
  static const String petBirthDate = 'birthDate';
  static const String petGender = 'gender';
  static const String petWeight = 'weight';
  static const String petMicrochipId = 'microchipId';
  static const String petProfileImageUrl = 'profileImageUrl';
  static const String petAllergies = 'allergies';
  static const String petCreatedAt = 'createdAt';
  static const String petUpdatedAt = 'updatedAt';

  // Medical Record Fields
  static const String recordPetId = 'petId';
  static const String recordOwnerId = 'ownerId';
  static const String recordType = 'recordType';
  static const String recordTitle = 'title';
  static const String recordDescription = 'description';
  static const String recordDate = 'recordDate';
  static const String recordClinicName = 'clinicName';
  static const String recordVeterinarianName = 'veterinarianName';
  static const String recordAttachmentUrls = 'attachmentUrls';
  static const String recordMetadata = 'metadata';
  static const String recordCreatedAt = 'createdAt';
  static const String recordUpdatedAt = 'updatedAt';

  // Illness Detection Fields
  static const String detectionImageUrl = 'imageUrl';
  static const String detectionResults = 'detections';
  static const String detectionSymptoms = 'symptoms';
  static const String detectionUrgencyLevel = 'urgencyLevel';
  static const String detectionAiExplanation = 'aiExplanation';
  static const String detectionRecommendedAction = 'recommendedAction';
  static const String detectionFirstAidSteps = 'firstAidSteps';
  static const String detectionVetVisitRequired = 'vetVisitRequired';
  static const String detectionDetectedAt = 'detectedAt';

  // Poison Incident Fields
  static const String incidentToxinName = 'toxinName';
  static const String incidentToxinCategory = 'toxinCategory';
  static const String incidentSymptoms = 'symptoms';
  static const String incidentRiskLevel = 'riskLevel';
  static const String incidentFirstAidSteps = 'firstAidSteps';
  static const String incidentAiGuidance = 'aiGuidance';
  static const String incidentTime = 'incidentTime';
  static const String incidentNearestVetId = 'nearestVetId';
  static const String incidentVetReportUrl = 'vetReportUrl';
  static const String incidentResolved = 'resolved';

  // Toxin Fields
  static const String toxinCategory = 'category';
  static const String toxinToxicityLevel = 'toxicityLevel';
  static const String toxinCommonSymptoms = 'commonSymptoms';
  static const String toxinFirstAidSteps = 'firstAidSteps';
  static const String toxinTimeToSymptoms = 'timeToSymptoms';
  static const String toxinSpeciesSpecific = 'speciesSpecific';

  // Vet Clinic Fields
  static const String clinicName = 'name';
  static const String clinicAddress = 'address';
  static const String clinicLocation = 'location';
  static const String clinicPhoneNumber = 'phoneNumber';
  static const String clinicEmergencyNumber = 'emergencyNumber';
  static const String clinicOperatingHours = 'operatingHours';
  static const String clinicServices = 'services';
  static const String clinicIsEmergency = 'isEmergency';
  static const String clinicRating = 'rating';

  // Firebase Storage Paths
  static String getUserStoragePath(String userId) => 'users/$userId';
  static String getPetProfilePath(String userId, String petId) =>
      'users/$userId/pets/$petId/profile';
  static String getMedicalRecordPath(String userId, String petId, String recordId) =>
      'users/$userId/pets/$petId/medical_records/$recordId';
  static String getIllnessDetectionPath(String userId, String petId, String detectionId) =>
      'users/$userId/pets/$petId/illness_detections/$detectionId';
  static String getPoisonIncidentPath(String userId, String petId, String incidentId) =>
      'users/$userId/pets/$petId/poison_incidents/$incidentId';
}
