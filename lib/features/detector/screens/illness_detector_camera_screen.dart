import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../models/pet_model.dart';
import '../../../models/symptom_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/ai_loading_animation.dart';
import '../widgets/symptom_questionnaire_widget.dart';
import 'illness_result_screen.dart';
import '../../../services/gemini_service.dart';
import '../../../services/ml_inference_service.dart';
import '../../../services/ai_agent_service.dart';

/// Main camera/upload interface for AI Illness Detection
/// Follows architecture: Camera → ML Model → Symptom Input → AI Agent → Results
class IllnessDetectorCameraScreen extends StatefulWidget {
  final PetModel? selectedPet;

  const IllnessDetectorCameraScreen({
    super.key,
    this.selectedPet,
  });

  @override
  State<IllnessDetectorCameraScreen> createState() =>
      _IllnessDetectorCameraScreenState();
}

class _IllnessDetectorCameraScreenState
    extends State<IllnessDetectorCameraScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  List<SymptomModel> _selectedSymptoms = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Illness Detector'),
        backgroundColor: PawfectColors.pawfectOrange,
      ),
      body: _isAnalyzing
          ? _buildAnalyzingView()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPetInfoCard(),
                    const SizedBox(height: 20),
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _buildSymptomSection(),
                    const SizedBox(height: 30),
                    _buildAnalyzeButton(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Pet information card
  Widget _buildPetInfoCard() {
    if (widget.selectedPet == null) {
      return Card(
        color: Colors.orange.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: PawfectColors.pawfectOrange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No pet selected. Results will be general.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pet = widget.selectedPet!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: PawfectColors.pawfectOrange,
              child: Text(
                pet.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${pet.species} • ${pet.breed}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Image selection section
  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.camera_alt, color: PawfectColors.pawfectOrange),
                SizedBox(width: 8),
                Text(
                  'Step 1: Capture or Upload Image (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Take a photo of visible symptoms like skin issues, wounds, or eye problems.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PawfectColors.pawfectOrange,
                      side: const BorderSide(color: PawfectColors.pawfectOrange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PawfectColors.pawfectOrange,
                      side: const BorderSide(color: PawfectColors.pawfectOrange),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Symptom selection section
  Widget _buildSymptomSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services, color: PawfectColors.pawfectOrange),
                SizedBox(width: 8),
                Text(
                  'Step 2: Select Symptoms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select all symptoms your pet is experiencing.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SymptomQuestionnaireWidget(
              onSymptomsChanged: (symptoms) {
                setState(() {
                  _selectedSymptoms = symptoms;
                });
              },
            ),
            if (_selectedSymptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${_selectedSymptoms.length} symptom(s) selected',
                  style: const TextStyle(
                    color: PawfectColors.pawfectOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Analyze button
  Widget _buildAnalyzeButton() {
    final canAnalyze = _selectedImage != null || _selectedSymptoms.isNotEmpty;

    return ElevatedButton(
      onPressed: canAnalyze ? _analyzeWithAI : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: PawfectColors.pawfectOrange,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Analyze with AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Analyzing view with progress
  Widget _buildAnalyzingView() {
    return AILoadingAnimation(
      title: 'AI Analysis in Progress',
      subtitle: 'Our AI agent is carefully analyzing your pet\'s condition',
      steps: const [
        LoadingStep(emoji: '', text: 'Processing image with ML model'),
        LoadingStep(emoji: '', text: 'Analyzing symptoms and patterns'),
        LoadingStep(emoji: '', text: 'Consulting Gemini AI'),
        LoadingStep(emoji: '', text: 'Generating diagnosis report'),
        LoadingStep(emoji: '', text: 'Preparing recommendations'),
      ],
    );
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  /// Analyze with AI Agent
  Future<void> _analyzeWithAI() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Initialize services
      final geminiService = GeminiService();
      final mlService = MLInferenceService();

      // Initialize Gemini with API key from environment
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not configured. Please add GEMINI_API_KEY to .env file');
      }
      await geminiService.initialize(apiKey);

      // Initialize ML model
      await mlService.initialize();

      // Create AI Agent
      final aiAgent = AIAgentService(
        geminiService: geminiService,
        mlService: mlService,
      );

      // Perform diagnosis
      final diagnosis = await aiAgent.diagnose(
        symptoms: _selectedSymptoms,
        image: _selectedImage,
        pet: widget.selectedPet,
      );

      // Navigate to results
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IllnessResultScreen(
              diagnosis: diagnosis,
              capturedImage: _selectedImage,
              pet: widget.selectedPet,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Analysis failed: $e');
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  /// Show error dialog
  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
