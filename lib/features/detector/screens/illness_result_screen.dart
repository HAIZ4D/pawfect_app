import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/diagnosis_model.dart';
import '../../../models/pet_model.dart';
import '../../../core/constants/colors.dart';
import '../repositories/illness_detector_repository.dart';

/// Beautiful results screen with image header and card carousel
class IllnessResultScreen extends StatefulWidget {
  final DiagnosisModel diagnosis;
  final File? capturedImage;
  final PetModel? pet;

  const IllnessResultScreen({
    super.key,
    required this.diagnosis,
    this.capturedImage,
    this.pet,
  });

  @override
  State<IllnessResultScreen> createState() => _IllnessResultScreenState();
}

class _IllnessResultScreenState extends State<IllnessResultScreen> {
  final IllnessDetectorRepository _repository = IllnessDetectorRepository();
  late PageController _pageController;
  bool _isSaving = false;
  bool _isSaved = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.capturedImage != null) _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildConditionBadge(),
                    const SizedBox(height: 20),
                    _buildPageIndicator(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 420,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        children: [
                          _buildExplanationCard(),
                          _buildFirstAidCard(),
                          _buildRecommendationsCard(),
                          _buildTreatmentOptionsCard(),
                          _buildPreventionCard(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildBottomActions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with back button and share
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const Expanded(
            child: Text(
              'Diagnosis Results',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: _shareResults,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  /// Image section at top
  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              widget.capturedImage!,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Condition badge with urgency
  Widget _buildConditionBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getUrgencyColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.diagnosis.urgencyEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      widget.diagnosis.urgencyLabel,
                      style: TextStyle(
                        color: _getUrgencyColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${widget.diagnosis.confidencePercentage} Confidence',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _cleanText(widget.diagnosis.condition),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.diagnosis.symptoms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: widget.diagnosis.symptoms.take(5).map((symptom) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    _cleanText(symptom),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (widget.diagnosis.symptoms.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${widget.diagnosis.symptoms.length - 5} more symptoms',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Page indicator dots
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? PawfectColors.pawfectOrange : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  /// Card 1: Explanation
  Widget _buildExplanationCard() {
    return _buildInfoCard(
      icon: Icons.psychology_outlined,
      title: 'What This Means',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
      ),
      content: _cleanText(widget.diagnosis.explanation),
    );
  }

  /// Card 2: First Aid
  Widget _buildFirstAidCard() {
    final steps = _extractSteps(_cleanText(widget.diagnosis.firstAidInstructions));

    return _buildInfoCard(
      icon: Icons.medical_services_outlined,
      title: 'First Aid Steps',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Card 3: Recommendations
  Widget _buildRecommendationsCard() {
    return _buildInfoCard(
      icon: Icons.checklist_rounded,
      title: 'Action Plan',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.diagnosis.recommendations.map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _cleanText(rec),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Card 4: Treatment Options
  Widget _buildTreatmentOptionsCard() {
    final treatments = widget.diagnosis.treatments.isNotEmpty
        ? widget.diagnosis.treatments
        : [
            'Consult with a veterinarian for proper diagnosis',
            'Follow prescribed medication schedules',
            'Provide supportive care at home',
            'Monitor for improvement or worsening symptoms',
            'Follow up with vet as recommended',
          ];

    return _buildInfoCard(
      icon: Icons.medication_outlined,
      title: 'Treatment Options',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: treatments.map((treatment) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: PawfectColors.pawfectOrange.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _cleanText(treatment),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Card 5: Prevention Tips
  Widget _buildPreventionCard() {
    final preventionTips = [
      'Regular health check-ups with your veterinarian',
      'Maintain a balanced diet and proper nutrition',
      'Keep your pet\'s environment clean and safe',
      'Stay up to date with vaccinations',
      'Monitor your pet\'s behavior and appetite daily',
      'Provide regular exercise and mental stimulation',
    ];

    return _buildInfoCard(
      icon: Icons.health_and_safety_outlined,
      title: 'Prevention Tips',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: preventionTips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Generic info card builder
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Gradient gradient,
    String? content,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: content != null
                    ? Text(
                        content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      )
                    : child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom action buttons
  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _isSaved ? null : _saveToPawBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaved ? Colors.green : PawfectColors.pawfectOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: PawfectColors.pawfectOrange.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isSaved ? Icons.check_circle : Icons.bookmark_border),
                  const SizedBox(width: 8),
                  Text(
                    _isSaved ? 'Saved' : 'Save to PawBook',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _findNearbyVet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Icon(Icons.location_on),
          ),
        ],
      ),
    );
  }

  /// Clean text from markdown
  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('__', '')
        .replaceAll('_', '')
        .replaceAll('~~', '')
        .trim();
  }

  /// Extract steps from text
  List<String> _extractSteps(String text) {
    final lines = text.split('\n');
    final steps = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final cleaned = trimmed
          .replaceFirst(RegExp(r'^\d+\.\s*'), '')
          .replaceFirst(RegExp(r'^[-*•]\s*'), '');

      if (cleaned.isNotEmpty) {
        steps.add(cleaned);
      }
    }

    if (steps.isEmpty) {
      final sentences = text.split('. ');
      return sentences.where((s) => s.trim().isNotEmpty).take(6).toList();
    }

    return steps.take(6).toList();
  }

  /// Get urgency color
  Color _getUrgencyColor() {
    switch (widget.diagnosis.urgencyLevel) {
      case 'EMERGENCY':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade700;
      case 'MODERATE':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Save to PawBook
  Future<void> _saveToPawBook() async {
    setState(() => _isSaving = true);

    try {
      String? diagnosisId;

      if (widget.capturedImage != null) {
        diagnosisId = await _repository.saveDiagnosisWithImage(
          widget.diagnosis,
          widget.capturedImage!,
        );
      } else {
        diagnosisId = await _repository.saveDiagnosis(widget.diagnosis);
      }

      if (diagnosisId != null && mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to PawBook successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Share results
  void _shareResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Find nearby vet
  void _findNearbyVet() {
    Navigator.pushNamed(context, '/vet-finder');
  }
}
