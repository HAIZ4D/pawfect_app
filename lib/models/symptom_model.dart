/// Symptom Model for Illness Detection
class SymptomModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String severity; // mild, moderate, severe, emergency

  const SymptomModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.severity,
  });
}

/// Symptom Categories
class SymptomCategory {
  static const String behavioral = 'Behavioral';
  static const String digestive = 'Digestive';
  static const String respiratory = 'Respiratory';
  static const String skin = 'Skin & Coat';
  static const String urinary = 'Urinary';
  static const String neurological = 'Neurological';
  static const String physical = 'Physical';
  static const String other = 'Other';
}

/// Severity Levels
class SeverityLevel {
  static const String mild = 'mild';
  static const String moderate = 'moderate';
  static const String severe = 'severe';
  static const String emergency = 'emergency';
}
