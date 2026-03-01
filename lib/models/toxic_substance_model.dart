/// Toxic Substance Model for Poisoning Detection
class ToxicSubstanceModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final ToxicityLevel toxicityLevel;
  final List<String> symptoms;
  final List<String> immediateActions;
  final List<String> whatNotToDo;
  final String treatment;
  final bool induceVomiting;
  final int timeToReact; // Minutes before critical
  final List<String> alternativeNames;
  final List<String> keywords; // For image recognition matching

  const ToxicSubstanceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.toxicityLevel,
    required this.symptoms,
    required this.immediateActions,
    required this.whatNotToDo,
    required this.treatment,
    required this.induceVomiting,
    required this.timeToReact,
    this.alternativeNames = const [],
    this.keywords = const [],
  });

  /// Get toxicity color
  String get toxicityColor {
    switch (toxicityLevel) {
      case ToxicityLevel.fatal:
        return '#D32F2F'; // Red
      case ToxicityLevel.severe:
        return '#F57C00'; // Deep Orange
      case ToxicityLevel.moderate:
        return '#FFA726'; // Orange
      case ToxicityLevel.mild:
        return '#66BB6A'; // Green
    }
  }

  /// Get urgency message
  String get urgencyMessage {
    switch (toxicityLevel) {
      case ToxicityLevel.fatal:
        return 'FATAL - Call emergency vet immediately!';
      case ToxicityLevel.severe:
        return 'SEVERE - Seek veterinary care within $timeToReact minutes';
      case ToxicityLevel.moderate:
        return 'MODERATE - Call your veterinarian for guidance';
      case ToxicityLevel.mild:
        return 'MILD - Monitor and call vet if symptoms worsen';
    }
  }
}

/// Toxicity Levels
enum ToxicityLevel {
  fatal,   // Can cause death
  severe,  // Life-threatening
  moderate, // Serious but not immediately life-threatening
  mild,    // May cause discomfort
}

/// Substance Categories
class SubstanceCategory {
  static const String food = 'Human Foods';
  static const String plants = 'Plants & Flowers';
  static const String chemicals = 'Household Chemicals';
  static const String medications = 'Medications';
  static const String pesticides = 'Pesticides & Rodenticides';
  static const String automotive = 'Automotive Products';
  static const String other = 'Other Substances';
}
