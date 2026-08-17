import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/agent_progress_view.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/chat_session_model.dart';
import '../../../models/toxic_substance_model.dart';
import '../../../models/pet_model.dart';
import '../../../models/poisoning_incident_model.dart';
import '../../../models/poison_substance_model.dart';
import '../../../repositories/chat_repository.dart';
import '../../../repositories/poisoning_incident_repository.dart';
import '../../../services/pdf_report_generator.dart';
import '../../../services/ai_poisoning_assessment_service.dart';
import '../../../services/orchestration/agent_stage.dart';
import '../../../services/orchestration/poisoning_orchestrator.dart';
import '../../chat/screens/vet_chat_screen.dart';
import '../../pawbook/screens/pdf_viewer_screen.dart';
import '../../poisoning_detection/screens/vet_finder_screen.dart';

/// AI Poisoning Risk Assessment — editorial reveal.
///
/// After capturing facts on [ReportPoisoningIncidentScreen], Gemini
/// returns a [PoisoningAssessmentResult] plus first-aid steps. This
/// screen presents the verdict as a magazine spread: a risk hero,
/// numbered analysis sections (AI reading, time window, what to do,
/// first aid, watch list, outcome, owner message), and two CTAs.
///
/// All state, service calls, and navigation targets are preserved
/// from the previous implementation.
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
  // ─── State preserved verbatim ────────────────────────────────────
  final _aiService = AIPoisoningAssessmentService();
  PoisoningAssessmentResult? _assessment;
  List<String>? _firstAidInstructions;
  bool _isAssessing = true;
  String? _error;
  bool _isSavingReport = false;

  // Live progress for the 5-stage poisoning orchestrator pipeline.
  // The orchestrator updates this; AgentProgressView listens and
  // re-renders each stage as it transitions.
  late final ValueNotifier<OrchestrationProgress> _progress =
      ValueNotifier(const OrchestrationProgress(
    stages: PoisoningOrchestrator.defaultStages,
    activeIndex: -1,
  ));

  // ─── Palette ─────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _emergency = Color(0xFFD32F2F);
  static const Color _high = Color(0xFFE65100);
  static const Color _moderate = Color(0xFFF57C00);
  static const Color _low = Color(0xFF2E8A68);

  @override
  void initState() {
    super.initState();
    _performAIAssessment();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  // ─────────────────────────── Logic ────────────────────────────────
  Future<void> _performAIAssessment() async {
    setState(() {
      _isAssessing = true;
      _error = null;
    });

    try {
      final timeSince = DateTime.now().difference(widget.incidentTime);

      final assessment = await _aiService.assessPoisoningRisk(
        substanceName: widget.substance.name,
        substanceDescription: widget.substance.description,
        pet: widget.pet,
        symptoms: widget.symptoms,
        amountIngested: widget.amountIngested,
        timeSinceIngestion: timeSince,
        progress: _progress,
      );

      final firstAid = await _aiService.getFirstAidInstructions(
        substanceName: widget.substance.name,
        pet: widget.pet,
        riskLevel: assessment.riskLevel,
      );

      if (!mounted) return;
      setState(() {
        _assessment = assessment;
        _firstAidInstructions = firstAid;
        _isAssessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isAssessing = false;
      });
    }
  }

  Future<void> _saveReportAndGeneratePDF() async {
    if (_assessment == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isSavingReport = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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

      final repository = PoisoningIncidentRepository();
      final incidentId = await repository.saveIncident(incident);

      if (incidentId != null) {
        await _generatePdfWithAI(incident, incidentId);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        _brandSnack('Couldn\'t save the report. Try again.', isError: true),
      );
      if (mounted) setState(() => _isSavingReport = false);
    }
  }

  Future<void> _generatePdfWithAI(
    PoisoningIncidentModel incident,
    String incidentId,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

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

      final repository = PoisoningIncidentRepository();
      final updatedIncident = incident.copyWith(
        id: incidentId,
        pdfReportBase64: pdfBase64,
      );
      await repository.updateIncident(updatedIncident);

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfBase64: pdfBase64,
            title: '${widget.pet.name} · ${widget.substance.name}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isSavingReport = false);
      scaffoldMessenger.showSnackBar(
        _brandSnack('Couldn\'t generate the PDF.', isError: true),
      );
    }
  }

  // ─────────────────────────── Helpers ──────────────────────────────
  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return _low;
      case RiskLevel.moderate:
        return _moderate;
      case RiskLevel.high:
        return _high;
      case RiskLevel.emergency:
        return _emergency;
    }
  }

  String _getRiskText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.moderate:
        return 'MODERATE';
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.emergency:
        return 'EMERGENCY';
    }
  }

  String _getRiskDisplay(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'Low risk.';
      case RiskLevel.moderate:
        return 'Moderate.';
      case RiskLevel.high:
        return 'High risk.';
      case RiskLevel.emergency:
        return 'Emergency.';
    }
  }

  SnackBar _brandSnack(String message, {bool isError = false}) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? _emergency : _ink,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.1,
        ),
      ),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  // ─────────────────────────── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: LiquidAppBar(
        title: 'Risk Assessment',
        subtitle: _assessment != null
            ? _getRiskText(_assessment!.riskLevel)
            : 'Analysing',
        icon: Icons.shield_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.45),
          if (_isAssessing)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else
            _buildAssessmentResults(),
          if (_isSavingReport) _buildSavingOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────── Loading ──────────────────────────────
  Widget _buildLoadingState() {
    return AgentProgressView(
      progress: _progress,
      title: 'Risk Assessment',
      subtitle:
          'Five specialised agents reviewing toxicology, symptoms, timeline, and consistency.',
      italicAccent: 'Reasoning, not guessing.',
    );
  }

  // ─────────────────────────── Error ────────────────────────────────
  Widget _buildErrorState() {
    final topInset = MediaQuery.of(context).padding.top;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF6E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.88),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _emergency,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'COULDN\'T READ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Assessor unreachable.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.6,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t reach the AI assessor. Check your connection and try again.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft.withOpacity(0.95),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _performAIAssessment,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        PawfectColors.pawfectOrange,
                        Color(0xFFFFB347),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            PawfectColors.pawfectOrange.withOpacity(0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'TRY AGAIN',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.8,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.refresh_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Results ──────────────────────────────
  Widget _buildAssessmentResults() {
    if (_assessment == null) return const SizedBox();
    final topInset = MediaQuery.of(context).padding.top;
    final riskColor = _getRiskColor(_assessment!.riskLevel);

    return Stack(
      children: [
        // Risk-colored halo behind the hero
        Positioned(
          top: topInset + 60,
          left: -120,
          right: -120,
          height: 360,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.7,
                  colors: [
                    riskColor.withOpacity(0.2),
                    riskColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 120),
            children: [
              _buildRiskHero(riskColor),
              const SizedBox(height: 14),
              _buildConfidenceBadge(),
              const SizedBox(height: 28),
              const _Ornament(),
              const SizedBox(height: 28),
              _buildSection(
                number: '01',
                label: 'AI READING',
                title: 'What we think happened.',
                child: _buildExplanationCard(),
              ),
              const SizedBox(height: 28),
              _buildSection(
                number: '02',
                label: 'TIME WINDOW',
                title: 'How long you have.',
                child: _buildTimeWindowCard(riskColor),
              ),
              const SizedBox(height: 28),
              _buildSection(
                number: '03',
                label: 'DO NOW',
                title: 'Take these steps.',
                child: _buildNumberedList(
                  _assessment!.immediateActions,
                  accent: riskColor,
                ),
              ),
              if (_firstAidInstructions != null &&
                  _firstAidInstructions!.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildSection(
                  number: '04',
                  label: 'FIRST AID',
                  title: 'Hands-on care.',
                  child: _buildNumberedList(
                    _firstAidInstructions!,
                    accent: PawfectColors.pawfectOrange,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _buildSection(
                number: _firstAidInstructions != null &&
                        _firstAidInstructions!.isNotEmpty
                    ? '05'
                    : '04',
                label: 'WATCH FOR',
                title: 'Signs to monitor.',
                child: _buildSymptomChips(_assessment!.symptomsToMonitor),
              ),
              const SizedBox(height: 28),
              _buildSection(
                number: _firstAidInstructions != null &&
                        _firstAidInstructions!.isNotEmpty
                    ? '06'
                    : '05',
                label: 'OUTCOME',
                title: 'What likely follows.',
                child: _buildPrognosisPair(),
              ),
              const SizedBox(height: 28),
              _buildSection(
                number: _firstAidInstructions != null &&
                        _firstAidInstructions!.isNotEmpty
                    ? '07'
                    : '06',
                label: 'FOR YOU',
                title: 'A note from the assessor.',
                child: _buildOwnerGuidanceCard(),
              ),
              const SizedBox(height: 32),
              const _Ornament(),
              const SizedBox(height: 26),
              if (_assessment!.requiresEmergencyVet) ...[
                _buildEmergencyVetCta(),
                const SizedBox(height: 12),
              ],
              _buildSaveCta(),
              const SizedBox(height: 12),
              _buildAskVetAiCta(),
              const SizedBox(height: 24),
              _buildDisclaimer(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Risk hero ────────────────────────────
  Widget _buildRiskHero(Color riskColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_ink, _inkDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Ghost glyph — the risk text initial
            Positioned(
              top: -28,
              right: -14,
              child: Text(
                _assessment!.requiresEmergencyVet ? '!' : '~',
                style: TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.06),
                  height: 1.0,
                  letterSpacing: -8,
                ),
              ),
            ),
            // Decorative shield watermark
            Positioned(
              bottom: -20,
              right: 14,
              child: Transform.rotate(
                angle: -0.32,
                child: Icon(
                  _assessment!.requiresEmergencyVet
                      ? Icons.emergency_rounded
                      : Icons.shield_rounded,
                  size: 96,
                  color: riskColor.withOpacity(0.10),
                ),
              ),
            ),
            // Left risk stripe
            Positioned(
              left: 0,
              top: 26,
              bottom: 26,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: riskColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VERDICT',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.78),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 22,
                        height: 1,
                        color: Colors.white.withOpacity(0.32),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _getRiskText(_assessment!.riskLevel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: riskColor,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _getRiskDisplay(_assessment!.riskLevel),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _assessment!.urgencyMessage,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.92),
                      letterSpacing: -0.2,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pets_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${widget.pet.name.toUpperCase()} · ${widget.substance.name.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
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

  // ─────────────────────────── Confidence badge ─────────────────────
  Widget _buildConfidenceBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: PawfectColors.pawfectOrange,
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              'AI CONFIDENCE · ${_assessment!.confidenceScore}%',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Section wrapper ──────────────────────
  Widget _buildSection({
    required String number,
    required String label,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: PawfectColors.pawfectOrange,
                letterSpacing: 0.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 18, height: 1, color: _hairline),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  // ─────────────────────────── Cards ────────────────────────────────
  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: _cardDecoration(),
      child: Text(
        _assessment!.detailedExplanation,
        style: TextStyle(
          fontSize: 14,
          color: _ink.withOpacity(0.92),
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildTimeWindowCard(Color riskColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: riskColor.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: riskColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WINDOW',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: riskColor,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _assessment!.timeWindow,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedList(List<String> items, {required Color accent}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: _cardDecoration(),
      child: Column(
        children: List.generate(items.length, (index) {
          final isLast = index == items.length - 1;
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: isLast ? 12 : 12,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: _ink.withOpacity(0.92),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: _hairline),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSymptomChips(List<String> symptoms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map((symptom) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PawfectColors.pawfectOrange.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                symptom,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrognosisPair() {
    return Column(
      children: [
        _buildPrognosisCard(
          label: 'WITH TREATMENT',
          body: _assessment!.prognosisIfTreated,
          accent: _low,
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: 10),
        _buildPrognosisCard(
          label: 'WITHOUT TREATMENT',
          body: _assessment!.prognosisIfUntreated,
          accent: _emergency,
          icon: Icons.trending_down_rounded,
        ),
      ],
    );
  }

  Widget _buildPrognosisCard({
    required String label,
    required String body,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF6E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withOpacity(0.32),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: _ink.withOpacity(0.92),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerGuidanceCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAEE), Color(0xFFFFF1D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 1,
                color: PawfectColors.pawfectOrange.withOpacity(0.35),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PawfectColors.pawfectOrange,
                    width: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 1,
                color: PawfectColors.pawfectOrange.withOpacity(0.35),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _assessment!.petOwnerGuidance,
            style: TextStyle(
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _ink.withOpacity(0.92),
              height: 1.6,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── CTAs ─────────────────────────────────
  Widget _buildEmergencyVetCta() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VetFinderScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_emergency, Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _emergency.withOpacity(0.38),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find emergency vet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Minutes matter. Open the nearest clinic.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveCta() {
    return GestureDetector(
      onTap: _isSavingReport
          ? null
          : () {
              HapticFeedback.lightImpact();
              _saveReportAndGeneratePDF();
            },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [PawfectColors.pawfectOrange, Color(0xFFFFB347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: PawfectColors.pawfectOrange.withOpacity(0.38),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save report & generate PDF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Logs to medical history and prepares the printable report.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Ask Vet AI CTA ───────────────────────
  Widget _buildAskVetAiCta() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _launchVetChat,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_ink, _inkDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.32),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: PawfectColors.pawfectOrange.withOpacity(0.45),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: PawfectColors.pawfectOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask the Vet AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Follow-up questions about this case.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchVetChat() async {
    HapticFeedback.lightImpact();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      scaffoldMessenger.showSnackBar(_brandSnack(
        'Please sign in to chat with the vet AI.',
      ));
      return;
    }
    if (_assessment == null) return;

    final summary = [
      'Substance: ${widget.substance.name} (${widget.substance.category}).',
      'Reported amount: ${widget.amountIngested}.',
      if (widget.symptoms.isNotEmpty)
        'Owner sees: ${widget.symptoms.take(6).join(", ")}.',
      'AI risk: ${_getRiskText(_assessment!.riskLevel)}. '
          'Window: ${_assessment!.timeWindow}.',
    ].join(' ');

    final session = ChatSessionModel(
      userId: uid,
      petId: widget.pet.id,
      petName: widget.pet.name,
      petSpecies: widget.pet.species,
      contextType: ChatContextType.poisoning,
      subject: widget.substance.name,
      riskLabel: _getRiskText(_assessment!.riskLevel),
      summary: summary,
      title: 'About ${widget.substance.name}',
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    try {
      final created = await ChatRepository().createSession(session);
      await navigator.push(
        MaterialPageRoute(builder: (_) => VetChatScreen(session: created)),
      );
    } catch (_) {
      scaffoldMessenger.showSnackBar(_brandSnack(
        'Couldn\'t open the chat. Try again.',
        isError: true,
      ));
    }
  }

  Widget _buildDisclaimer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(width: 36, height: 1, color: _hairline),
            const SizedBox(height: 12),
            Text(
              'Triage only. For any real concern, contact a licensed vet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _inkSoft.withOpacity(0.85),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: _ink.withOpacity(0.42),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF6E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.88),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.32),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  PawfectColors.pawfectOrange,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saving report',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Logging incident and generating PDF.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: _inkSoft.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFFFF6E2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.88),
        width: 1.2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}

// ─────────────────────────── Ornament rule ─────────────────────────
class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 1,
            color: PawfectColors.pawfectOrange.withOpacity(0.35),
          ),
          const SizedBox(width: 14),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PawfectColors.pawfectOrange,
                width: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 56,
            height: 1,
            color: PawfectColors.pawfectOrange.withOpacity(0.35),
          ),
        ],
      ),
    );
  }
}
