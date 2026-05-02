import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/widgets/ai_loading_animation.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/toxic_substance_model.dart';
import '../../../models/pet_model.dart';
import '../../../models/poisoning_incident_model.dart';
import '../../../models/poison_substance_model.dart';
import '../../../repositories/poisoning_incident_repository.dart';
import '../../../services/pdf_report_generator.dart';
import '../../../services/ai_poisoning_assessment_service.dart';
import '../../pawbook/screens/pdf_viewer_screen.dart';
import '../../poisoning_detection/screens/vet_finder_screen.dart';

class AIPoisoningAssessmentScreen extends StatefulWidget {
  final ToxicSubstanceModel substance;
  final PetModel pet;
  final List<String> symptoms;
  final String amountIngested;
  final DateTime incidentTime;

  const AIPoisoningAssessmentScreen({
    Key? key,
    required this.substance,
    required this.pet,
    required this.symptoms,
    required this.amountIngested,
    required this.incidentTime,
  }) : super(key: key);

  @override
  State<AIPoisoningAssessmentScreen> createState() =>
      _AIPoisoningAssessmentScreenState();
}

class _AIPoisoningAssessmentScreenState
    extends State<AIPoisoningAssessmentScreen> {
  final _aiService = AIPoisoningAssessmentService();
  PoisoningAssessmentResult? _assessment;
  List<String>? _firstAidInstructions;
  bool _isAssessing = true;
  String? _error;
  bool _isSavingReport = false;

  @override
  void initState() {
    super.initState();
    _performAIAssessment();
  }

  Future<void> _performAIAssessment() async {
    setState(() {
      _isAssessing = true;
      _error = null;
    });

    try {
      final timeSince = DateTime.now().difference(widget.incidentTime);

      // Get AI risk assessment
      final assessment = await _aiService.assessPoisoningRisk(
        substanceName: widget.substance.name,
        substanceDescription: widget.substance.description,
        pet: widget.pet,
        symptoms: widget.symptoms,
        amountIngested: widget.amountIngested,
        timeSinceIngestion: timeSince,
      );

      // Get AI first aid instructions
      final firstAid = await _aiService.getFirstAidInstructions(
        substanceName: widget.substance.name,
        pet: widget.pet,
        riskLevel: assessment.riskLevel,
      );

      setState(() {
        _assessment = assessment;
        _firstAidInstructions = firstAid;
        _isAssessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isAssessing = false;
      });
    }
  }

  Future<void> _saveReportAndGeneratePDF() async {
    if (_assessment == null) return;

    setState(() => _isSavingReport = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Convert category
      PoisonCategory category;
      switch (widget.substance.category.toLowerCase()) {
        case 'human foods':
          category = PoisonCategory.toxicFoods;
          break;
        case 'plants & flowers':
          category = PoisonCategory.plants;
          break;
        case 'medications':
          category = PoisonCategory.medicines;
          break;
        case 'household chemicals':
          category = PoisonCategory.chemicals;
          break;
        default:
          category = PoisonCategory.householdItems;
      }

      // Create incident with AI assessment
      final incident = PoisoningIncidentModel(
        userId: user.uid,
        petId: widget.pet.id!,
        petName: widget.pet.name,
        substanceName: widget.substance.name,
        category: category,
        assessedRiskLevel: _assessment!.riskLevel,
        symptoms: widget.symptoms,
        amountIngested: widget.amountIngested,
        incidentTime: widget.incidentTime,
        firstAidGiven: '',
        vetContacted: false,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final repository = PoisoningIncidentRepository();
      final incidentId = await repository.saveIncident(incident);

      if (incidentId != null) {
        // Generate PDF with AI assessment
        await _generatePdfWithAI(incident, incidentId);
      }
    } catch (e) {
      print('Error saving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving report: $e'),
          backgroundColor: PawfectColors.error,
        ),
      );
      setState(() => _isSavingReport = false);
    }
  }

  Future<void> _generatePdfWithAI(
      PoisoningIncidentModel incident, String incidentId) async {
    try {
      final poisonModel = PoisonSubstanceModel(
        name: widget.substance.name,
        category: incident.category,
        alternativeNames: widget.substance.alternativeNames,
        commonSymptoms: widget.symptoms,
        defaultRiskLevel: _assessment!.riskLevel,
        description: widget.substance.description,
        firstAidSteps: _firstAidInstructions ?? [],
        emergencyActions: _assessment!.immediateActions,
        requiresImmediateVetVisit: _assessment!.requiresEmergencyVet,
      );

      final generator = PdfReportGenerator();
      final pdfBase64 = await generator.generatePoisoningReport(
        incident: incident,
        poison: poisonModel,
        pet: widget.pet,
        riskDescription: _assessment!.urgencyMessage,
        immediateActions: _assessment!.immediateActions,
        severityExplanation: _assessment!.detailedExplanation,
      );

      // Update incident with PDF
      final repository = PoisoningIncidentRepository();
      final updatedIncident = incident.copyWith(
        id: incidentId,
        pdfReportBase64: pdfBase64,
      );
      await repository.updateIncident(updatedIncident);

      // Navigate to PDF viewer
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfBase64: pdfBase64,
            title: '${widget.pet.name} - ${widget.substance.name}',
          ),
        ),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      setState(() => _isSavingReport = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: PawfectColors.error,
        ),
      );
    }
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return PawfectColors.success;
      case RiskLevel.moderate:
        return PawfectColors.warning;
      case RiskLevel.high:
        return const Color(0xFFF57C00);
      case RiskLevel.emergency:
        return PawfectColors.error;
    }
  }

  String _getRiskText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.moderate:
        return 'MODERATE RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.emergency:
        return 'EMERGENCY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: LiquidAppBar(
        title: 'Risk Assessment',
        subtitle: _assessment != null
            ? _getRiskText(_assessment!.riskLevel)
            : 'Analyzing…',
        icon: Icons.shield_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          _isAssessing
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildAssessmentResults(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return AILoadingAnimation(
      title: 'Poisoning Risk Assessment',
      subtitle: 'AI is evaluating toxicity levels and calculating safety',
      steps: const [
        LoadingStep(emoji: '', text: 'Analyzing substance toxicity'),
        LoadingStep(emoji: '', text: 'Evaluating pet health factors'),
        LoadingStep(emoji: '', text: 'Calculating risk level'),
        LoadingStep(emoji: '', text: 'Generating first aid steps'),
        LoadingStep(emoji: '', text: 'Preparing safety recommendations'),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: PawfectColors.error),
            const SizedBox(height: 16),
            Text('Assessment Error', style: PawfectTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unable to complete AI assessment',
              style: PawfectTextStyles.bodyMedium.copyWith(
                color: PawfectColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _performAIAssessment,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PawfectColors.pawfectOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentResults() {
    if (_assessment == null) return const SizedBox();
    final topInset = MediaQuery.of(context).padding.top;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topInset + 132, 16, 32),
      children: [
        // Risk Level Banner
        _buildRiskBanner(),
        const SizedBox(height: 20),

        // AI Confidence Badge
        _buildConfidenceBadge(),
        const SizedBox(height: 20),

        // Detailed Explanation
        _buildSectionCard(
          title: '🤖 AI Analysis',
          children: [
            Text(
              _assessment!.detailedExplanation,
              style: PawfectTextStyles.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Time Window
        _buildSectionCard(
          title: '⏰ Time to Act',
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRiskColor(_assessment!.riskLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getRiskColor(_assessment!.riskLevel),
                  width: 2,
                ),
              ),
              child: Text(
                _assessment!.timeWindow,
                style: PawfectTextStyles.h5.copyWith(
                  color: _getRiskColor(_assessment!.riskLevel),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Immediate Actions
        _buildSectionCard(
          title: '🚨 Immediate Actions',
          children: [
            ..._assessment!.immediateActions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getRiskColor(_assessment!.riskLevel),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: PawfectTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),

        // First Aid Instructions
        if (_firstAidInstructions != null && _firstAidInstructions!.isNotEmpty)
          _buildSectionCard(
            title: '🏥 First Aid Steps',
            children: [
              ..._firstAidInstructions!.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: PawfectTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PawfectColors.pawfectOrange,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: PawfectTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        const SizedBox(height: 16),

        // Symptoms to Monitor
        _buildSectionCard(
          title: '👁️ Symptoms to Monitor',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _assessment!.symptomsToMonitor.map((symptom) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PawfectColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PawfectColors.warning),
                  ),
                  child: Text(
                    symptom,
                    style: PawfectTextStyles.bodySmall.copyWith(
                      color: PawfectColors.warning,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Prognosis
        _buildSectionCard(
          title: '📊 Expected Outcome',
          children: [
            _buildPrognosisRow(
              'With Treatment:',
              _assessment!.prognosisIfTreated,
              PawfectColors.success,
            ),
            const SizedBox(height: 12),
            _buildPrognosisRow(
              'Without Treatment:',
              _assessment!.prognosisIfUntreated,
              PawfectColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pet Owner Guidance
        _buildSectionCard(
          title: '💬 Message for You',
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                _assessment!.petOwnerGuidance,
                style: PawfectTextStyles.bodyMedium.copyWith(
                  color: Colors.blue[900],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Action Buttons
        if (_assessment!.requiresEmergencyVet)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VetFinderScreen(),
                ),
              );
            },
            icon: const Icon(Icons.location_on),
            label: const Text('Find Emergency Vet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PawfectColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (_assessment!.requiresEmergencyVet) const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _isSavingReport ? null : _saveReportAndGeneratePDF,
          icon: _isSavingReport
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isSavingReport ? 'Saving...' : 'Save Report & Generate PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PawfectColors.pawfectOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRiskBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRiskColor(_assessment!.riskLevel),
            _getRiskColor(_assessment!.riskLevel).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getRiskColor(_assessment!.riskLevel).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _assessment!.requiresEmergencyVet ? Icons.emergency : Icons.warning_amber,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _getRiskText(_assessment!.riskLevel),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _assessment!.urgencyMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    return Center(
      child: GlassPill(
        tintOpacity: 0.7,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: PawfectColors.pawfectOrange,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'AI Confidence: ${_assessment!.confidenceScore}%',
              style: PawfectTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return GlassCard(
      radius: 22,
      blur: 16,
      tintOpacity: 0.55,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PawfectTextStyles.h5.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPrognosisRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.fiber_manual_record, size: 12, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: PawfectTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: PawfectTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
