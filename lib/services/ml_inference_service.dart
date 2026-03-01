import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';  // Temporarily disabled

/// Service for TensorFlow Lite model inference
/// Handles on-device image analysis for visual abnormality detection
/// NOTE: TFLite is currently disabled due to package compatibility issues
/// The app will work using Gemini AI only for analysis
class MLInferenceService {
  dynamic _interpreter;  // Changed from Interpreter? to dynamic
  bool _initialized = false;

  // Model configuration
  static const String modelPath = 'assets/ml_models/pet_illness_detector.tflite';
  static const int inputSize = 224; // Standard MobileNet input size
  static const int numClasses = 4; // Skin infections, wounds, parasites, eye abnormalities
  static const double confidenceThreshold = 0.6;

  // Class labels matching model output
  static const List<String> classLabels = [
    'Skin Infection',
    'Wound/Injury',
    'Parasites (Fleas/Ticks)',
    'Eye Abnormality',
  ];

  /// Initialize TensorFlow Lite interpreter
  Future<void> initialize() async {
    try {
      print('⚠️ TensorFlow Lite is temporarily disabled due to package compatibility');
      print('✅ App will use Gemini AI only for image analysis');

      // TFLite temporarily disabled - app works with Gemini AI only
      // Uncomment when tflite_flutter package is fixed:
      // _interpreter = await Interpreter.fromAsset(modelPath);

      _initialized = false;  // Mark as not initialized (will use placeholder results)
    } catch (e) {
      print('❌ Error: $e');
      _initialized = false;
    }
  }

  /// Check if ML model is loaded
  bool get isInitialized => _initialized;

  /// Run inference on image
  ///
  /// Returns map with detected conditions and confidence scores
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    if (!_initialized) {
      print('⚠️ ML model not initialized, returning placeholder results');
      return _getPlaceholderResults();
    }

    try {
      print('🔄 Preprocessing image...');

      // Load and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Convert to normalized float array
      final input = _imageToByteListFloat(resizedImage);

      // Prepare output buffer
      final output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

      print('🔄 Running inference...');

      // Run inference
      _interpreter!.run(input, output);

      // Process results
      final results = _processOutput(output);

      print('✅ Inference complete');
      return results;
    } catch (e) {
      print('❌ Error during inference: $e');
      return _getPlaceholderResults();
    }
  }

  /// Convert image to normalized float array for model input
  Float32List _imageToByteListFloat(img.Image image) {
    final convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    final buffer = Float32List.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);

        // Extract RGB values and normalize to [0, 1]
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return convertedBytes;
  }

  /// Process model output into structured results
  Map<String, dynamic> _processOutput(List<dynamic> output) {
    final scores = output[0] as List<dynamic>;
    final List<Map<String, dynamic>> detections = [];
    final List<String> detectedConditions = [];
    final Map<String, double> confidenceScores = {};

    // Process each class
    for (int i = 0; i < numClasses && i < scores.length; i++) {
      final confidence = scores[i] as double;
      final label = classLabels[i];

      confidenceScores[label] = confidence;

      if (confidence >= confidenceThreshold) {
        detections.add({
          'condition': label,
          'confidence': confidence,
          'severity': _getSeverity(confidence),
        });
        detectedConditions.add(label);
      }
    }

    // Sort by confidence
    detections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

    return {
      'hasDetections': detections.isNotEmpty,
      'detectedConditions': detectedConditions,
      'detections': detections,
      'confidenceScores': confidenceScores,
      'topCondition': detections.isNotEmpty ? detections[0]['condition'] : null,
      'topConfidence': detections.isNotEmpty ? detections[0]['confidence'] : 0.0,
      'analysis': _generateAnalysis(detections),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Determine severity based on confidence score
  String _getSeverity(double confidence) {
    if (confidence >= 0.9) return 'HIGH';
    if (confidence >= 0.75) return 'MODERATE';
    return 'LOW';
  }

  /// Generate human-readable analysis
  String _generateAnalysis(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) {
      return 'No significant visual abnormalities detected. If symptoms persist, consult a veterinarian.';
    }

    final topDetection = detections[0];
    final condition = topDetection['condition'];
    final confidence = ((topDetection['confidence'] as double) * 100).toStringAsFixed(1);

    if (detections.length == 1) {
      return 'Visual analysis detected possible $condition with $confidence% confidence.';
    } else {
      final otherConditions = detections.sublist(1).map((d) => d['condition']).join(', ');
      return 'Visual analysis detected possible $condition ($confidence% confidence). Also observed: $otherConditions.';
    }
  }

  /// Get placeholder results when model is not available
  Map<String, dynamic> _getPlaceholderResults() {
    return {
      'hasDetections': false,
      'detectedConditions': [],
      'detections': [],
      'confidenceScores': {},
      'topCondition': null,
      'topConfidence': 0.0,
      'analysis': 'Image analysis not available. Diagnosis based on symptoms only.',
      'timestamp': DateTime.now().toIso8601String(),
      'note': 'ML model not loaded. Please ensure pet_illness_detector.tflite is in assets/ml_models/',
    };
  }

  /// Batch analyze multiple images (for comparison)
  Future<List<Map<String, dynamic>>> analyzeMultipleImages(List<File> imageFiles) async {
    final results = <Map<String, dynamic>>[];

    for (final imageFile in imageFiles) {
      final result = await analyzeImage(imageFile);
      results.add(result);
    }

    return results;
  }

  /// Get detailed information about a detected condition
  Map<String, dynamic> getConditionInfo(String condition) {
    final conditionDetails = {
      'Skin Infection': {
        'description': 'Bacterial or fungal infection affecting the skin',
        'commonCauses': ['Allergies', 'Parasites', 'Moisture', 'Wounds'],
        'symptoms': ['Redness', 'Swelling', 'Discharge', 'Odor', 'Hair loss'],
        'urgency': 'MODERATE',
      },
      'Wound/Injury': {
        'description': 'Physical trauma or injury to skin or tissue',
        'commonCauses': ['Accidents', 'Fights', 'Sharp objects', 'Burns'],
        'symptoms': ['Bleeding', 'Open skin', 'Pain', 'Swelling', 'Limping'],
        'urgency': 'HIGH',
      },
      'Parasites (Fleas/Ticks)': {
        'description': 'External parasites affecting skin and overall health',
        'commonCauses': ['Environmental exposure', 'Contact with infected animals'],
        'symptoms': ['Scratching', 'Visible insects', 'Hair loss', 'Skin irritation'],
        'urgency': 'MODERATE',
      },
      'Eye Abnormality': {
        'description': 'Infection, injury, or disease affecting the eye',
        'commonCauses': ['Infection', 'Trauma', 'Foreign objects', 'Disease'],
        'symptoms': ['Redness', 'Discharge', 'Swelling', 'Cloudiness', 'Squinting'],
        'urgency': 'HIGH',
      },
    };

    return conditionDetails[condition] ?? {
      'description': 'Unknown condition',
      'commonCauses': [],
      'symptoms': [],
      'urgency': 'MODERATE',
    };
  }

  /// Clean up resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
    print('🧹 ML Inference Service disposed');
  }
}

/// Extension for reshaping lists (helper for TensorFlow output)
extension ListReshape<T> on List<T> {
  List<List<T>> reshape(List<int> shape) {
    if (shape.length != 2) {
      throw ArgumentError('Only 2D reshape supported');
    }

    final result = <List<T>>[];
    for (int i = 0; i < shape[0]; i++) {
      final row = <T>[];
      for (int j = 0; j < shape[1]; j++) {
        row.add(this[i * shape[1] + j]);
      }
      result.add(row);
    }
    return result;
  }
}
