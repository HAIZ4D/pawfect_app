import 'package:cloud_firestore/cloud_firestore.dart';

/// Diagnosis Model for AI-Powered Illness Detection Results
/// Enhanced with ML image analysis, Gemini AI explanations, and comprehensive recommendations
class DiagnosisModel {
  // Core diagnosis information
  final String condition; // Primary detected condition
  final List<String> symptoms; // User-reported symptoms
  final String urgencyLevel; // EMERGENCY, HIGH, MODERATE, LOW
  final double confidence; // 0.0 to 1.0

  // AI-generated content
  final String explanation; // Human-friendly explanation from Gemini AI
  final List<String> recommendations; // Actionable recommendations
  final String firstAidInstructions; // Immediate care instructions
  final String vetReport; // Professional vet-ready report

  // Visual analysis results (from Gemini 2.5 Flash multimodal vision)
  final List<String> mlDetections; // Conditions detected from the photo
  final String? mlAnalysis; // Vision analysis summary

  // Risk assessment
  final List<String> riskFactors; // Identified risk factors

  // Metadata
  final DateTime timestamp; // When diagnosis was performed
  final String? petId; // Associated pet ID
  final String? petName; // Pet name for display
  final String? id; // Firestore document ID (when saved)
  final String? imageUrl; // Firebase Storage URL if image was uploaded
  final String? imageBase64; // Base64 encoded image stored in Firestore

  const DiagnosisModel({
    required this.condition,
    required this.symptoms,
    required this.urgencyLevel,
    required this.confidence,
    required this.explanation,
    required this.recommendations,
    required this.firstAidInstructions,
    required this.vetReport,
    this.mlDetections = const [],
    this.mlAnalysis,
    this.riskFactors = const [],
    required this.timestamp,
    this.petId,
    this.petName,
    this.id,
    this.imageUrl,
    this.imageBase64,
  });

  /// Legacy compatibility - map old field names
  String get illnessName => condition;
  String get description => explanation;
  double get confidenceScore => confidence;
  String get severity => urgencyLevel;
  List<String> get matchedSymptoms => symptoms;
  List<String> get possibleCauses => riskFactors;
  List<String> get treatments => recommendations;
  bool get requiresVet => urgencyLevel == 'HIGH' || urgencyLevel == 'EMERGENCY';
  bool get isEmergency => urgencyLevel == 'EMERGENCY';

  /// Get confidence percentage
  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  /// Get urgency color
  String get urgencyColor {
    switch (urgencyLevel) {
      case 'EMERGENCY':
        return '#D32F2F'; // Red
      case 'HIGH':
        return '#F57C00'; // Deep Orange
      case 'MODERATE':
        return '#FFA726'; // Orange
      case 'LOW':
        return '#66BB6A'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get urgency emoji
  String get urgencyEmoji {
    switch (urgencyLevel) {
      case 'EMERGENCY':
        return '🚨';
      case 'HIGH':
        return '⚠️';
      case 'MODERATE':
        return '⚡';
      case 'LOW':
        return '✅';
      default:
        return 'ℹ️';
    }
  }

  /// Get urgency label
  String get urgencyLabel {
    switch (urgencyLevel) {
      case 'EMERGENCY':
        return 'EMERGENCY - Immediate Care Required';
      case 'HIGH':
        return 'High Priority - Vet Visit Needed Soon';
      case 'MODERATE':
        return 'Moderate - Schedule Vet Appointment';
      case 'LOW':
        return 'Low Risk - Monitor Symptoms';
      default:
        return 'Assessment Complete';
    }
  }

  /// Check if ML analysis was performed
  bool get hasMLAnalysis => mlDetections.isNotEmpty;

  /// Check if image was provided
  bool get hasImage => imageUrl != null || imageBase64 != null;

  /// Copy with method
  DiagnosisModel copyWith({
    String? condition,
    List<String>? symptoms,
    String? urgencyLevel,
    double? confidence,
    String? explanation,
    List<String>? recommendations,
    String? firstAidInstructions,
    String? vetReport,
    List<String>? mlDetections,
    String? mlAnalysis,
    List<String>? riskFactors,
    DateTime? timestamp,
    String? petId,
    String? petName,
    String? id,
    String? imageUrl,
    String? imageBase64,
  }) {
    return DiagnosisModel(
      condition: condition ?? this.condition,
      symptoms: symptoms ?? this.symptoms,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      confidence: confidence ?? this.confidence,
      explanation: explanation ?? this.explanation,
      recommendations: recommendations ?? this.recommendations,
      firstAidInstructions: firstAidInstructions ?? this.firstAidInstructions,
      vetReport: vetReport ?? this.vetReport,
      mlDetections: mlDetections ?? this.mlDetections,
      mlAnalysis: mlAnalysis ?? this.mlAnalysis,
      riskFactors: riskFactors ?? this.riskFactors,
      timestamp: timestamp ?? this.timestamp,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'condition': condition,
      'symptoms': symptoms,
      'urgencyLevel': urgencyLevel,
      'confidence': confidence,
      'explanation': explanation,
      'recommendations': recommendations,
      'firstAidInstructions': firstAidInstructions,
      'vetReport': vetReport,
      'mlDetections': mlDetections,
      'mlAnalysis': mlAnalysis,
      'riskFactors': riskFactors,
      'timestamp': Timestamp.fromDate(timestamp),
      'petId': petId,
      'petName': petName,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
    };
  }

  /// Create from Firestore document
  factory DiagnosisModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return DiagnosisModel(
      id: docId,
      condition: data['condition'] ?? 'Unknown',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      urgencyLevel: data['urgencyLevel'] ?? 'MODERATE',
      confidence: (data['confidence'] ?? 0.5).toDouble(),
      explanation: data['explanation'] ?? '',
      recommendations: List<String>.from(data['recommendations'] ?? []),
      firstAidInstructions: data['firstAidInstructions'] ?? '',
      vetReport: data['vetReport'] ?? '',
      mlDetections: List<String>.from(data['mlDetections'] ?? []),
      mlAnalysis: data['mlAnalysis'],
      riskFactors: List<String>.from(data['riskFactors'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      petId: data['petId'],
      petName: data['petName'],
      imageUrl: data['imageUrl'],
      imageBase64: data['imageBase64'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condition': condition,
      'symptoms': symptoms,
      'urgencyLevel': urgencyLevel,
      'confidence': confidence,
      'explanation': explanation,
      'recommendations': recommendations,
      'firstAidInstructions': firstAidInstructions,
      'vetReport': vetReport,
      'mlDetections': mlDetections,
      'mlAnalysis': mlAnalysis,
      'riskFactors': riskFactors,
      'timestamp': timestamp.toIso8601String(),
      'petId': petId,
      'petName': petName,
      'imageUrl': imageUrl,
    };
  }

  /// Create from JSON
  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'],
      condition: json['condition'] ?? 'Unknown',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      urgencyLevel: json['urgencyLevel'] ?? 'MODERATE',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      explanation: json['explanation'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      firstAidInstructions: json['firstAidInstructions'] ?? '',
      vetReport: json['vetReport'] ?? '',
      mlDetections: List<String>.from(json['mlDetections'] ?? []),
      mlAnalysis: json['mlAnalysis'],
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      timestamp: DateTime.parse(json['timestamp']),
      petId: json['petId'],
      petName: json['petName'],
      imageUrl: json['imageUrl'],
    );
  }
}
