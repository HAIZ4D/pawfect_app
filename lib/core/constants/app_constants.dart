/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Pawfect';
  static const String appVersion = '1.0.0';

  // Urgency Levels
  static const String urgencyLow = 'low';
  static const String urgencyModerate = 'moderate';
  static const String urgencyHigh = 'high';
  static const String urgencyEmergency = 'emergency';

  // Pet Species
  static const List<String> petSpecies = [
    'dog',
    'cat',
    'rabbit',
    'bird',
    'hamster',
    'guinea_pig',
    'other',
  ];

  // Gender Options
  static const List<String> genderOptions = [
    'male',
    'female',
  ];

  // Medical Record Types
  static const String recordTypeVaccine = 'vaccine';
  static const String recordTypeTest = 'test';
  static const String recordTypeMedication = 'medication';
  static const String recordTypeVisit = 'visit';
  static const String recordTypeIllnessDetection = 'illness_detection';
  static const String recordTypePoisoning = 'poisoning';

  // Toxin Categories
  static const String toxinCategoryFood = 'food';
  static const String toxinCategoryPlant = 'plant';
  static const String toxinCategoryMedicine = 'medicine';
  static const String toxinCategoryChemical = 'chemical';
  static const String toxinCategoryHousehold = 'household';

  // Severity Levels
  static const String severityMild = 'mild';
  static const String severityModerate = 'moderate';
  static const String severitySevere = 'severe';

  // Duration Options
  static const String durationMinutes = 'minutes';
  static const String durationHours = 'hours';
  static const String durationDays = 'days';

  // Image Settings
  static const int maxImageSizeKB = 500;
  static const int imageQuality = 85;
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;

  // Pagination
  static const int defaultPageSize = 20;
  static const int medicalRecordsPageSize = 50;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);

  // Medical Disclaimer
  static const String medicalDisclaimer = '''
MEDICAL DISCLAIMER:

Pawfect is an informational tool designed to assist pet owners in monitoring their pets' health. This app does NOT replace professional veterinary care, diagnosis, or treatment. Always consult with a licensed veterinarian for medical advice, diagnosis, and treatment of your pet.

In case of emergency, contact your veterinarian or emergency animal hospital immediately.

The AI-powered illness detector uses Gemini 2.5 Flash to provide preliminary assessments based on image analysis and symptom patterns. These assessments are not definitive diagnoses and should be confirmed by a veterinary professional.

By using this app, you acknowledge that you understand its limitations and agree to seek appropriate veterinary care for your pet.
''';

  // Emergency Warning
  static const String emergencyWarning = '''
⚠️ EMERGENCY SITUATION

Seek immediate veterinary care. This is a potentially life-threatening situation that requires urgent professional attention.

Contact your veterinarian or emergency animal hospital NOW.
''';
}
