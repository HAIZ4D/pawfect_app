import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/toxic_substance_model.dart';
import '../../../models/pet_model.dart';
import '../../../models/poisoning_incident_model.dart';
import '../../../models/poison_substance_model.dart';
import '../../../repositories/poisoning_incident_repository.dart';
import '../../../services/pdf_report_generator.dart';
import '../../pawbook/providers/pet_provider.dart';
import '../../pawbook/screens/pdf_viewer_screen.dart';
import '../../poisoning_detection/screens/vet_finder_screen.dart';
import 'ai_poisoning_assessment_screen.dart';

/// Report Poisoning Incident — editorial spread.
///
/// Owner has tapped a substance in the Poison Alert directory. We capture
/// the four facts the AI needs to triage (which pet, how much, when,
/// which symptoms) plus optional first aid notes, then hand off to
/// [AIPoisoningAssessmentScreen].
///
/// Visual language: cream page, white editorial cards, eyebrow rules,
/// numbered sections, ornament dividers. Red is reserved for the
/// substance hero and toxicity stripe so the rest of the screen stays
/// calm for an anxious owner.
class ReportPoisoningIncidentScreen extends StatefulWidget {
  final ToxicSubstanceModel substance;

  const ReportPoisoningIncidentScreen({
    Key? key,
    required this.substance,
  }) : super(key: key);

  @override
  State<ReportPoisoningIncidentScreen> createState() =>
      _ReportPoisoningIncidentScreenState();
}

class _ReportPoisoningIncidentScreenState
    extends State<ReportPoisoningIncidentScreen> {
  // ─── State preserved verbatim ────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  PetModel? _selectedPet;
  List<String> _selectedSymptoms = [];
  DateTime _incidentTime = DateTime.now();
  bool _isSaving = false;
  bool _isGeneratingPdf = false;

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
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─────────────────────────── Logic ────────────────────────────────
  Future<void> _selectIncidentTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_incidentTime),
      );

      if (time != null) {
        setState(() {
          _incidentTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> _saveAndGenerateReport() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_selectedPet == null) {
      scaffoldMessenger.showSnackBar(_brandSnack('Choose a pet first.'));
      return;
    }

    if (_selectedSymptoms.isEmpty) {
      scaffoldMessenger.showSnackBar(
        _brandSnack('Pick at least one symptom you can see.'),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      RiskLevel riskLevel;
      switch (widget.substance.toxicityLevel) {
        case ToxicityLevel.fatal:
          riskLevel = RiskLevel.emergency;
          break;
        case ToxicityLevel.severe:
          riskLevel = RiskLevel.high;
          break;
        case ToxicityLevel.moderate:
          riskLevel = RiskLevel.moderate;
          break;
        case ToxicityLevel.mild:
          riskLevel = RiskLevel.low;
          break;
      }

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
        petId: _selectedPet!.id!,
        petName: _selectedPet!.name,
        substanceName: widget.substance.name,
        category: category,
        assessedRiskLevel: riskLevel,
        symptoms: _selectedSymptoms,
        amountIngested: _amountController.text,
        incidentTime: _incidentTime,
        firstAidGiven: _notesController.text,
        vetContacted: false,
        createdAt: DateTime.now(),
      );

      final repository = PoisoningIncidentRepository();
      final incidentId = await repository.saveIncident(incident);

      if (incidentId != null) {
        scaffoldMessenger.showSnackBar(
          _brandSnack('Incident saved to medical history.'),
        );
        await _generatePdf(incident, incidentId);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        _brandSnack('Couldn\'t save the incident. Try again.', isError: true),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generatePdf(
    PoisoningIncidentModel incident,
    String incidentId,
  ) async {
    setState(() => _isGeneratingPdf = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      RiskLevel defaultRisk;
      switch (widget.substance.toxicityLevel) {
        case ToxicityLevel.fatal:
          defaultRisk = RiskLevel.emergency;
          break;
        case ToxicityLevel.severe:
          defaultRisk = RiskLevel.high;
          break;
        case ToxicityLevel.moderate:
          defaultRisk = RiskLevel.moderate;
          break;
        case ToxicityLevel.mild:
          defaultRisk = RiskLevel.low;
          break;
      }

      final poisonModel = PoisonSubstanceModel(
        name: widget.substance.name,
        category: incident.category,
        alternativeNames: widget.substance.alternativeNames,
        commonSymptoms: widget.substance.symptoms,
        defaultRiskLevel: defaultRisk,
        description: widget.substance.description,
        firstAidSteps: widget.substance.immediateActions,
        emergencyActions: widget.substance.immediateActions,
        requiresImmediateVetVisit:
            widget.substance.toxicityLevel == ToxicityLevel.fatal ||
                widget.substance.toxicityLevel == ToxicityLevel.severe,
      );

      final generator = PdfReportGenerator();
      final pdfBase64 = await generator.generatePoisoningReport(
        incident: incident,
        poison: poisonModel,
        pet: _selectedPet!,
        riskDescription: widget.substance.urgencyMessage,
        immediateActions: widget.substance.immediateActions,
        severityExplanation:
            'Risk Level: ${widget.substance.toxicityLevel.name.toUpperCase()}',
      );

      final bytes = base64Decode(pdfBase64);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/poisoning_report_${_selectedPet!.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes);

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
            title: '${_selectedPet!.name} · ${widget.substance.name}',
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        _brandSnack('Couldn\'t generate the report.', isError: true),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showSuccessDialog() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierColor: _ink.withOpacity(0.45),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF6E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.88),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.32),
                blurRadius: 32,
                offset: const Offset(0, 18),
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
                      color: PawfectColors.pawfectOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'REPORT READY',
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
                'Saved and generated.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.6,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Medical history updated. PDF report ready to share with your vet.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft.withOpacity(0.95),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        navigator.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _hairline, width: 1.2),
                        ),
                        child: const Center(
                          child: Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.substance.toxicityLevel == ToxicityLevel.fatal ||
                      widget.substance.toxicityLevel ==
                          ToxicityLevel.severe) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          navigator.push(
                            MaterialPageRoute(
                              builder: (_) => const VetFinderScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_emergency, Color(0xFFB71C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _emergency.withOpacity(0.32),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'FIND VET',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeSinceIncident() {
    final duration = DateTime.now().difference(_incidentTime);
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else {
      return '${duration.inDays} days ago';
    }
  }

  // ─────────────────────────── Helpers ──────────────────────────────
  Color _toxicityColor() {
    switch (widget.substance.toxicityLevel) {
      case ToxicityLevel.fatal:
        return _emergency;
      case ToxicityLevel.severe:
        return _high;
      case ToxicityLevel.moderate:
        return _moderate;
      case ToxicityLevel.mild:
        return _low;
    }
  }

  String _toxicityLabel() {
    switch (widget.substance.toxicityLevel) {
      case ToxicityLevel.fatal:
        return 'FATAL';
      case ToxicityLevel.severe:
        return 'SEVERE';
      case ToxicityLevel.moderate:
        return 'MODERATE';
      case ToxicityLevel.mild:
        return 'MILD';
    }
  }

  String _formatIncidentTime() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final d = _incidentTime;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')} · $hour12:$minute $period';
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

  void _onAssessmentTap() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_selectedPet == null) {
      HapticFeedback.lightImpact();
      scaffoldMessenger.showSnackBar(_brandSnack('Choose a pet first.'));
      return;
    }
    if (_selectedSymptoms.isEmpty) {
      HapticFeedback.lightImpact();
      scaffoldMessenger.showSnackBar(
        _brandSnack('Pick at least one symptom you can see.'),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIPoisoningAssessmentScreen(
          substance: widget.substance,
          pet: _selectedPet!,
          symptoms: _selectedSymptoms,
          amountIngested: _amountController.text,
          incidentTime: _incidentTime,
        ),
      ),
    );
  }

  // ─────────────────────────── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final petProvider = context.watch<PetProvider>();
    final toxColor = _toxicityColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Report Incident',
        subtitle: 'Five facts, then assessment',
        icon: Icons.shield_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.45),
          // Atmospheric tinted halo behind the substance hero. Mood
          // matches toxicity colour without flooding the whole page.
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
                      toxColor.withOpacity(0.18),
                      toxColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 120),
                children: [
                  _buildSubstanceHero(toxColor),
                  const SizedBox(height: 28),
                  _buildEditorialHeader(),
                  const SizedBox(height: 24),
                  const _Ornament(),
                  const SizedBox(height: 28),
                  _buildSection(
                    number: '01',
                    label: 'PATIENT',
                    title: 'Who was affected?',
                    child: _buildPetPicker(petProvider),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    number: '02',
                    label: 'EXPOSURE',
                    title: 'How much got in?',
                    subtitle:
                        'A rough estimate is fine. Think bites, tablets, sips.',
                    child: _buildAmountField(),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    number: '03',
                    label: 'TIMELINE',
                    title: 'When did it happen?',
                    child: _buildTimePicker(),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    number: '04',
                    label: 'SIGNS',
                    title: 'What are you seeing?',
                    subtitle: 'Tap every symptom that fits.',
                    child: _buildSymptomsPicker(),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    number: '05',
                    label: 'FIRST AID',
                    title: 'What have you tried?',
                    subtitle: 'Optional. Leave blank if nothing yet.',
                    child: _buildNotesField(),
                  ),
                  const SizedBox(height: 32),
                  const _Ornament(),
                  const SizedBox(height: 26),
                  _buildAssessmentCta(),
                  const SizedBox(height: 24),
                  _buildDisclaimer(),
                ],
              ),
            ),
          ),
          if (_isSaving || _isGeneratingPdf) _buildSavingOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────── Substance hero ───────────────────────
  Widget _buildSubstanceHero(Color toxColor) {
    final altNames = widget.substance.alternativeNames;
    final altLine = altNames.isEmpty ? null : altNames.take(3).join(', ');

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
            // Ghost warning glyph — editorial signature
            Positioned(
              top: -28,
              right: -14,
              child: Text(
                '!',
                style: TextStyle(
                  fontSize: 196,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.06),
                  height: 1.0,
                  letterSpacing: -8,
                ),
              ),
            ),
            // Decorative shield watermark
            Positioned(
              bottom: -18,
              right: 16,
              child: Transform.rotate(
                angle: -0.32,
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 88,
                  color: toxColor.withOpacity(0.08),
                ),
              ),
            ),
            // Left toxicity stripe — semantic, not decorative
            Positioned(
              left: 0,
              top: 26,
              bottom: 26,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: toxColor,
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
                          color: toxColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TOXIN',
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
                          _toxicityLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: toxColor,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.substance.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.substance.category,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: PawfectColors.pawfectOrange.withOpacity(0.92),
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                  if (altLine != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Also: $altLine',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.66),
                        letterSpacing: -0.1,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (widget.substance.timeToReact > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: toxColor.withOpacity(0.92),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'CRITICAL WINDOW · ${widget.substance.timeToReact} MIN',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: toxColor,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Editorial header ─────────────────────
  Widget _buildEditorialHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'INCIDENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 28, height: 1, color: _hairline),
            const SizedBox(width: 12),
            const Text(
              'TELL US',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _inkSoft,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'What happened?',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A few facts, then we triage.',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: PawfectColors.pawfectOrange,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The more accurate the inputs, the sharper the assessment your vet gets to read.',
          style: TextStyle(
            fontSize: 13.5,
            color: _inkSoft.withOpacity(0.92),
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Section wrapper ──────────────────────
  Widget _buildSection({
    required String number,
    required String label,
    required String title,
    String? subtitle,
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
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _inkSoft.withOpacity(0.9),
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  // ─────────────────────────── Pet picker ───────────────────────────
  Widget _buildPetPicker(PetProvider petProvider) {
    if (!petProvider.hasPets) {
      return _buildHintCard(
        icon: Icons.pets_rounded,
        title: 'No pets on record.',
        body: 'Add a pet first so this incident lands in their file.',
      );
    }
    return Column(
      children: petProvider.pets.map((pet) {
        final isSelected = _selectedPet?.id == pet.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPet = pet);
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [_ink, _inkDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Colors.white, Color(0xFFFFF6E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? _ink
                        : Colors.white.withOpacity(0.88),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? _ink.withOpacity(0.28)
                          : const Color(0x10000000),
                      blurRadius: isSelected ? 18 : 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFEAD5),
                        border: Border.all(
                          color: isSelected
                              ? PawfectColors.pawfectOrange
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: pet.imageBase64 != null
                            ? pet.getDecodedImage()
                            : const Icon(
                                Icons.pets_rounded,
                                color: PawfectColors.pawfectOrange,
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : _ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pet.breed} · ${pet.getAge()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.7)
                                  : _inkSoft,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: PawfectColors.pawfectOrange,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────── Amount field ─────────────────────────
  Widget _buildAmountField() {
    return _EditorialTextField(
      controller: _amountController,
      hint: 'Small piece. Two tablets. Entire bar.',
      icon: Icons.scale_rounded,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please describe the amount.';
        }
        return null;
      },
    );
  }

  // ─────────────────────────── Time picker ──────────────────────────
  Widget _buildTimePicker() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectIncidentTime,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: PawfectColors.pawfectOrange.withOpacity(0.32),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: PawfectColors.pawfectOrange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatIncidentTime(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTimeSinceIncident(),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: _inkSoft.withOpacity(0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: _inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Symptoms picker ──────────────────────
  Widget _buildSymptomsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.substance.symptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _toggleSymptom(symptom);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [_ink, _inkDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? _ink
                        : Colors.white.withOpacity(0.9),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _ink.withOpacity(0.24),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: PawfectColors.pawfectOrange,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      symptom,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedSymptoms.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
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
                '${_selectedSymptoms.length.toString().padLeft(2, "0")} ${_selectedSymptoms.length == 1 ? "SIGN" : "SIGNS"} SELECTED',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: _inkSoft,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─────────────────────────── Notes field ──────────────────────────
  Widget _buildNotesField() {
    return _EditorialTextField(
      controller: _notesController,
      hint: 'e.g., rinsed mouth, called vet, last meal at 7am.',
      icon: Icons.edit_note_rounded,
      maxLines: 3,
    );
  }

  // ─────────────────────────── Assessment CTA ───────────────────────
  Widget _buildAssessmentCta() {
    return _AssessmentCta(onTap: _onAssessmentTap);
  }

  // ─────────────────────────── Hint card ────────────────────────────
  Widget _buildHintCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PawfectColors.pawfectOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PawfectColors.pawfectOrange.withOpacity(0.32),
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: PawfectColors.pawfectOrange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: _inkSoft.withOpacity(0.95),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Disclaimer ───────────────────────────
  Widget _buildDisclaimer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(width: 36, height: 1, color: _hairline),
            const SizedBox(height: 12),
            Text(
              'In any emergency, call your vet immediately.\nThis tool is informational only.',
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

  // ─────────────────────────── Saving overlay ───────────────────────
  Widget _buildSavingOverlay() {
    return IgnorePointer(
      ignoring: false,
      child: Container(
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
                    _isGeneratingPdf
                        ? 'Generating PDF…'
                        : 'Recording in medical history…',
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
      ),
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

// ─────────────────────────── Editorial text field ──────────────────
class _EditorialTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  const _EditorialTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.maxLines = 1,
  });

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);

  @override
  Widget build(BuildContext context) {
    final isMulti = maxLines > 1;
    return Container(
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
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        textAlignVertical:
            isMulti ? TextAlignVertical.top : TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 14,
          color: _ink,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13.5,
            color: _inkSoft.withOpacity(0.85),
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.fromLTRB(16, isMulti ? 14 : 0, 12, 0),
            child: Icon(
              icon,
              color: _ink.withOpacity(0.7),
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          errorStyle: const TextStyle(
            fontSize: 11.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD32F2F),
            letterSpacing: -0.1,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(0, isMulti ? 14 : 16, 14, 14),
        ),
      ),
    );
  }
}

// ─────────────────────────── Assessment CTA ────────────────────────
class _AssessmentCta extends StatefulWidget {
  final VoidCallback onTap;
  const _AssessmentCta({required this.onTap});

  @override
  State<_AssessmentCta> createState() => _AssessmentCtaState();
}

class _AssessmentCtaState extends State<_AssessmentCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
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
                  Icons.auto_awesome_rounded,
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
                      'Get AI risk assessment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Personalised triage in seconds.',
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
      ),
    );
  }
}
