import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  PetModel? _selectedPet;
  List<String> _selectedSymptoms = [];
  DateTime _incidentTime = DateTime.now();
  bool _isSaving = false;
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectIncidentTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
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

    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet')),
      );
      return;
    }

    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Convert ToxicityLevel to RiskLevel
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

      // Convert ToxicSubstanceModel category to PoisonCategory
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

      // Create incident
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

      // Save to Firestore
      final repository = PoisoningIncidentRepository();
      final incidentId = await repository.saveIncident(incident);

      if (incidentId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident saved to medical history'),
            backgroundColor: PawfectColors.success,
          ),
        );

        // Generate PDF
        await _generatePdf(incident, incidentId);
      }
    } catch (e) {
      print('Error saving incident: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving incident: $e'),
          backgroundColor: PawfectColors.error,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _generatePdf(PoisoningIncidentModel incident, String incidentId) async {
    setState(() => _isGeneratingPdf = true);

    try {
      // Create PoisonSubstanceModel from ToxicSubstanceModel
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
        requiresImmediateVetVisit: widget.substance.toxicityLevel == ToxicityLevel.fatal ||
            widget.substance.toxicityLevel == ToxicityLevel.severe,
      );

      final generator = PdfReportGenerator();
      final pdfBase64 = await generator.generatePoisoningReport(
        incident: incident,
        poison: poisonModel,
        pet: _selectedPet!,
        riskDescription: widget.substance.urgencyMessage,
        immediateActions: widget.substance.immediateActions,
        severityExplanation: 'Risk Level: ${widget.substance.toxicityLevel.name.toUpperCase()}',
      );

      // Save PDF to device
      final bytes = base64Decode(pdfBase64);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/poisoning_report_${_selectedPet!.name}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

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
            title: '${_selectedPet!.name} - ${widget.substance.name}',
          ),
        ),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: PawfectColors.error,
        ),
      );
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: PawfectColors.success),
            const SizedBox(width: 8),
            Text('Report Generated', style: PawfectTextStyles.h4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident report saved successfully!',
              style: PawfectTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '✓ Medical history updated',
              style: PawfectTextStyles.bodySmall,
            ),
            Text(
              '✓ PDF report generated',
              style: PawfectTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to substance detail
            },
            child: const Text('Done'),
          ),
          if (widget.substance.toxicityLevel == ToxicityLevel.fatal ||
              widget.substance.toxicityLevel == ToxicityLevel.severe)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VetFinderScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Find Vet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PawfectColors.error,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: AppBar(
        title: Text('Report Incident', style: PawfectTextStyles.h3),
        backgroundColor: PawfectColors.error,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Substance Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [PawfectColors.cardShadow],
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: PawfectColors.error, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.substance.name,
                          style: PawfectTextStyles.h4,
                        ),
                        Text(
                          widget.substance.category,
                          style: PawfectTextStyles.bodySmall.copyWith(
                            color: PawfectColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pet Selection
            Text('Select Affected Pet', style: PawfectTextStyles.h5),
            const SizedBox(height: 12),
            if (!petProvider.hasPets)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No pets found. Please add a pet first.',
                  style: PawfectTextStyles.bodyMedium,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: petProvider.pets.map((pet) {
                  final isSelected = _selectedPet?.id == pet.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPet = pet),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PawfectColors.error
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? PawfectColors.error
                              : PawfectColors.borderLight,
                          width: 2,
                        ),
                        boxShadow: isSelected ? [PawfectColors.cardShadow] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pets,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : PawfectColors.textBody,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pet.name,
                            style: PawfectTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : PawfectColors.textBody,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Amount Ingested
            Text('Amount Ingested', style: PawfectTextStyles.h5),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: 'e.g., Small piece, 2 tablets, Entire bar...',
                prefixIcon: const Icon(Icons.scale),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please specify the amount ingested';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Incident Time
            Text('When Did This Happen?', style: PawfectTextStyles.h5),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectIncidentTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PawfectColors.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: PawfectColors.textBody),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incident Time',
                            style: PawfectTextStyles.bodySmall.copyWith(
                              color: PawfectColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_incidentTime.toString().substring(0, 16)} (${_getTimeSinceIncident()})',
                            style: PawfectTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: PawfectColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Symptoms Selection
            Text('What Symptoms Are You Seeing?', style: PawfectTextStyles.h5),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.substance.symptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return GestureDetector(
                  onTap: () => _toggleSymptom(symptom),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PawfectColors.error
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? PawfectColors.error
                            : PawfectColors.borderLight,
                      ),
                    ),
                    child: Text(
                      symptom,
                      style: PawfectTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : PawfectColors.textBody,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (_selectedSymptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${_selectedSymptoms.length} symptom(s) selected',
                  style: PawfectTextStyles.bodySmall.copyWith(
                    color: PawfectColors.textHint,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // First Aid Notes
            Text('First Aid Given (Optional)', style: PawfectTextStyles.h5),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Note any first aid actions you\'ve taken...',
                prefixIcon: const Icon(Icons.edit_note),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // AI Assessment Button
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedPet == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a pet')),
                  );
                  return;
                }
                if (_selectedSymptoms.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one symptom')),
                  );
                  return;
                }
                if (!_formKey.currentState!.validate()) return;

                // Navigate to AI Assessment Screen
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
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                'Get AI Risk Assessment',
                style: PawfectTextStyles.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PawfectColors.pawfectOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTimeSinceIncident() {
    final duration = DateTime.now().difference(_incidentTime);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else {
      return '${duration.inDays} days ago';
    }
  }
}
