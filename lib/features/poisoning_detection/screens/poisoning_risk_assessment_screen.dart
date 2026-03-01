import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/pet_model.dart';
import '../../../models/poison_substance_model.dart';
import '../../../models/poisoning_incident_model.dart';
import '../../../services/risk_assessment_engine.dart';
import '../../../services/pdf_report_generator.dart';
import '../../../repositories/poisoning_incident_repository.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'vet_finder_screen.dart';

class PoisoningRiskAssessmentScreen extends StatefulWidget {
  final PetModel pet;
  final PoisonSubstanceModel poison;
  final List<String> symptoms;
  final String amountIngested;
  final DateTime incidentTime;

  const PoisoningRiskAssessmentScreen({
    Key? key,
    required this.pet,
    required this.poison,
    required this.symptoms,
    required this.amountIngested,
    required this.incidentTime,
  }) : super(key: key);

  @override
  State<PoisoningRiskAssessmentScreen> createState() =>
      _PoisoningRiskAssessmentScreenState();
}

class _PoisoningRiskAssessmentScreenState
    extends State<PoisoningRiskAssessmentScreen> {
  late RiskAssessmentResult _assessment;
  bool _isGeneratingPdf = false;
  bool _isSavingIncident = false;
  String? _incidentId;
  String? _pdfBase64;

  final _firstAidController = TextEditingController();
  final _vetNotesController = TextEditingController();
  bool _vetContacted = false;

  @override
  void initState() {
    super.initState();
    _performRiskAssessment();
  }

  @override
  void dispose() {
    _firstAidController.dispose();
    _vetNotesController.dispose();
    super.dispose();
  }

  void _performRiskAssessment() {
    final engine = RiskAssessmentEngine();
    final timeSince = DateTime.now().difference(widget.incidentTime);

    _assessment = engine.assessRisk(
      poison: widget.poison,
      pet: widget.pet,
      observedSymptoms: widget.symptoms,
      amountIngested: widget.amountIngested,
      timeSinceIngestion: timeSince,
    );

    // Auto-save incident
    _saveIncident();
  }

  Future<void> _saveIncident() async {
    setState(() => _isSavingIncident = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final incident = PoisoningIncidentModel(
      userId: user.uid,
      petId: widget.pet.id!,
      petName: widget.pet.name,
      substanceName: widget.poison.name,
      category: widget.poison.category,
      assessedRiskLevel: _assessment.assessedRiskLevel,
      symptoms: widget.symptoms,
      amountIngested: widget.amountIngested,
      incidentTime: widget.incidentTime,
      firstAidGiven: _firstAidController.text,
      vetContacted: _vetContacted,
      vetNotes: _vetNotesController.text.isNotEmpty ? _vetNotesController.text : null,
      pdfReportBase64: _pdfBase64,
      createdAt: DateTime.now(),
    );

    final repository = PoisoningIncidentRepository();
    final id = await repository.saveIncident(incident);

    setState(() {
      _incidentId = id;
      _isSavingIncident = false;
    });

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident saved to medical history'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _generateAndSavePdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final generator = PdfReportGenerator();
      final pdfBase64 = await generator.generatePoisoningReport(
        incident: PoisoningIncidentModel(
          userId: FirebaseAuth.instance.currentUser!.uid,
          petId: widget.pet.id!,
          petName: widget.pet.name,
          substanceName: widget.poison.name,
          category: widget.poison.category,
          assessedRiskLevel: _assessment.assessedRiskLevel,
          symptoms: widget.symptoms,
          amountIngested: widget.amountIngested,
          incidentTime: widget.incidentTime,
          firstAidGiven: _firstAidController.text,
          vetContacted: _vetContacted,
          vetNotes: _vetNotesController.text.isNotEmpty ? _vetNotesController.text : null,
          createdAt: DateTime.now(),
        ),
        poison: widget.poison,
        pet: widget.pet,
        riskDescription: _assessment.riskDescription,
        immediateActions: _assessment.immediateActions,
        severityExplanation: _assessment.severityExplanation,
      );

      setState(() => _pdfBase64 = pdfBase64);

      // Update incident with PDF
      if (_incidentId != null) {
        final repository = PoisoningIncidentRepository();
        final incident = await repository.getIncidentById(_incidentId!);
        if (incident != null) {
          await repository.updateIncident(
            incident.copyWith(pdfReportBase64: pdfBase64),
          );
        }
      }

      // Save PDF to device
      final bytes = base64Decode(pdfBase64);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/poisoning_report_${widget.pet.name}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report saved to ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Risk Assessment'),
        backgroundColor: _getRiskColor(_assessment.assessedRiskLevel),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf ? null : _generateAndSavePdf,
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Risk Level Banner
          _buildRiskBanner(),
          const SizedBox(height: 20),

          // Pet & Poison Info
          _buildInfoCard(),
          const SizedBox(height: 20),

          // Risk Description
          _buildSectionCard(
            title: 'Risk Assessment',
            icon: Icons.assessment,
            iconColor: _getRiskColor(_assessment.assessedRiskLevel),
            children: [
              Text(
                _assessment.riskDescription,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _assessment.severityExplanation,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Immediate Actions
          _buildSectionCard(
            title: 'Immediate Actions Required',
            icon: Icons.emergency,
            iconColor: Colors.red[700]!,
            children: [
              ..._assessment.immediateActions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.red[700],
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // First Aid Steps from Database
          _buildSectionCard(
            title: 'First Aid Steps',
            icon: Icons.medical_services,
            iconColor: Colors.blue[700]!,
            children: [
              ...widget.poison.firstAidSteps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Antidote Information
          if (widget.poison.antidote != null)
            _buildSectionCard(
              title: 'Antidote Available',
              icon: Icons.medication,
              iconColor: Colors.green[700]!,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[700]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.poison.antidote!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '⚠️ Must be administered by a licensed veterinarian',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (widget.poison.antidote != null) const SizedBox(height: 20),

          // First Aid Given (Editable)
          _buildSectionCard(
            title: 'First Aid Given (Optional)',
            icon: Icons.edit_note,
            iconColor: Colors.purple[700]!,
            children: [
              TextField(
                controller: _firstAidController,
                decoration: InputDecoration(
                  hintText: 'Note any first aid actions you\'ve taken...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                onChanged: (value) => _saveIncident(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vet Contact Status
          _buildSectionCard(
            title: 'Veterinarian Contact',
            icon: Icons.local_hospital,
            iconColor: Colors.teal[700]!,
            children: [
              CheckboxListTile(
                title: const Text('I have contacted my veterinarian'),
                value: _vetContacted,
                onChanged: (value) {
                  setState(() => _vetContacted = value ?? false);
                  _saveIncident();
                },
                contentPadding: EdgeInsets.zero,
              ),
              TextField(
                controller: _vetNotesController,
                decoration: InputDecoration(
                  labelText: 'Vet Notes (Optional)',
                  hintText: 'Any instructions or notes from your vet...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                onChanged: (value) => _saveIncident(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Emergency Contacts
          _buildSectionCard(
            title: 'Emergency Contacts',
            icon: Icons.phone,
            iconColor: Colors.orange[700]!,
            children: [
              _buildContactButton(
                'Pet Poison Helpline',
                '(855) 764-7661',
                Icons.phone,
              ),
              const SizedBox(height: 8),
              _buildContactButton(
                'ASPCA Poison Control',
                '(888) 426-4435',
                Icons.phone,
              ),
              const SizedBox(height: 12),
              Text(
                '⚠️ These hotlines operate 24/7 and may charge a consultation fee',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          if (_assessment.requiresEmergencyVet)
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
              label: const Text('Find Nearest Emergency Vet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRiskBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRiskColor(_assessment.assessedRiskLevel),
            _getRiskColor(_assessment.assessedRiskLevel).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getRiskColor(_assessment.assessedRiskLevel).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _assessment.requiresEmergencyVet ? Icons.emergency : Icons.warning_amber,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _getRiskLevelText(_assessment.assessedRiskLevel),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                widget.pet.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildInfoRow('Substance:', widget.poison.name),
          _buildInfoRow('Category:', widget.poison.categoryName),
          _buildInfoRow('Amount:', widget.amountIngested),
          _buildInfoRow(
            'Time:',
            '${widget.incidentTime.toString().substring(0, 16)} (${_getTimeSince()})',
          ),
          if (widget.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Symptoms:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.symptoms
                  .map((symptom) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          symptom,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[900],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(String name, String number, IconData icon) {
    return InkWell(
      onTap: () {
        // TODO: Implement phone call
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call $number')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green[700]!;
      case RiskLevel.moderate:
        return Colors.orange[700]!;
      case RiskLevel.high:
        return Colors.deepOrange[700]!;
      case RiskLevel.emergency:
        return Colors.red[700]!;
    }
  }

  String _getRiskLevelText(RiskLevel level) {
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

  String _getTimeSince() {
    final duration = DateTime.now().difference(widget.incidentTime);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else {
      return '${duration.inDays} days ago';
    }
  }
}
