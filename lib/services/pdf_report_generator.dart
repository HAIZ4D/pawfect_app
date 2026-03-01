import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/poisoning_incident_model.dart';
import '../models/poison_substance_model.dart';
import '../models/pet_model.dart';

class PdfReportGenerator {
  /// Generate a PDF report for a poisoning incident
  /// Returns base64 encoded PDF string for storage in Firestore
  Future<String> generatePoisoningReport({
    required PoisoningIncidentModel incident,
    required PoisonSubstanceModel poison,
    required PetModel pet,
    required String riskDescription,
    required List<String> immediateActions,
    required String severityExplanation,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with Emergency Alert
            _buildHeader(incident.assessedRiskLevel),
            pw.SizedBox(height: 20),

            // Incident Overview
            _buildSection(
              title: '🚨 POISONING INCIDENT REPORT',
              content: [
                pw.Text(
                  'Report Generated: ${DateTime.now().toString().substring(0, 19)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Incident Time: ${incident.incidentTime.toString().substring(0, 19)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Pet Information
            _buildSection(
              title: '🐾 PET INFORMATION',
              content: [
                _buildInfoRow('Name:', pet.name),
                _buildInfoRow('Species:', pet.species),
                _buildInfoRow('Breed:', pet.breed ?? 'Not specified'),
                _buildInfoRow(
                    'Weight:', pet.weight != null ? '${pet.weight} kg' : 'Not specified'),
                _buildInfoRow('Gender:', pet.gender),
                _buildInfoRow(
                    'Age:',
                    pet.birthdate != null
                        ? '${DateTime.now().difference(pet.birthdate!).inDays ~/ 365} years'
                        : 'Not specified'),
              ],
            ),
            pw.SizedBox(height: 20),

            // Poison Substance Details
            _buildSection(
              title: '☠️ SUBSTANCE INGESTED',
              content: [
                _buildInfoRow('Substance:', poison.name),
                _buildInfoRow('Category:', poison.categoryName),
                _buildInfoRow('Amount Ingested:', incident.amountIngested),
                _buildInfoRow('Risk Level:', _getRiskLevelText(incident.assessedRiskLevel)),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Description:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
                pw.Text(poison.description, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Symptoms Observed
            if (incident.symptoms.isNotEmpty)
              _buildSection(
                title: '🩺 OBSERVED SYMPTOMS',
                content: [
                  ...incident.symptoms.map((symptom) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, bottom: 5),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
                            pw.Expanded(
                              child: pw.Text(symptom, style: const pw.TextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            pw.SizedBox(height: 20),

            // Risk Assessment
            _buildSection(
              title: '⚠️ RISK ASSESSMENT',
              content: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _getRiskColor(incident.assessedRiskLevel),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    riskDescription,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  severityExplanation,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Immediate Actions Required
            _buildSection(
              title: '🚑 IMMEDIATE ACTIONS REQUIRED',
              content: [
                ...immediateActions.map((action) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, bottom: 8),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('► ', style: const pw.TextStyle(fontSize: 10)),
                          pw.Expanded(
                            child: pw.Text(
                              action,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
            pw.SizedBox(height: 20),

            // First Aid Steps
            if (poison.firstAidSteps.isNotEmpty)
              _buildSection(
                title: '🏥 FIRST AID STEPS',
                content: [
                  ...poison.firstAidSteps.asMap().entries.map((entry) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 20,
                              child: pw.Text(
                                '${entry.key + 1}.',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                entry.value,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            pw.SizedBox(height: 20),

            // Antidote Information
            if (poison.antidote != null)
              _buildSection(
                title: '💊 ANTIDOTE AVAILABLE',
                content: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColors.green700, width: 2),
                    ),
                    child: pw.Text(
                      poison.antidote!,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '⚠️ Must be administered by a licensed veterinarian',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            pw.SizedBox(height: 20),

            // First Aid Given (if any)
            if (incident.firstAidGiven.isNotEmpty)
              _buildSection(
                title: '✅ FIRST AID ALREADY ADMINISTERED',
                content: [
                  pw.Text(incident.firstAidGiven, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            pw.SizedBox(height: 20),

            // Vet Contact Status
            _buildSection(
              title: '📞 VETERINARY CONTACT STATUS',
              content: [
                _buildInfoRow(
                  'Veterinarian Contacted:',
                  incident.vetContacted ? 'YES' : 'NO',
                ),
                if (incident.vetNotes != null && incident.vetNotes!.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Vet Notes:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text(incident.vetNotes!, style: const pw.TextStyle(fontSize: 10)),
                ],
              ],
            ),
            pw.SizedBox(height: 20),

            // Emergency Contacts
            _buildSection(
              title: '🆘 EMERGENCY CONTACTS',
              content: [
                _buildInfoRow('Pet Poison Helpline:', '(855) 764-7661'),
                _buildInfoRow('ASPCA Poison Control:', '(888) 426-4435'),
                pw.SizedBox(height: 5),
                pw.Text(
                  '⚠️ These hotlines operate 24/7 and may charge a consultation fee',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'This report is for informational purposes only and does not replace professional veterinary advice.',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Always consult with a licensed veterinarian for proper diagnosis and treatment.',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];
        },
      ),
    );

    // Convert PDF to bytes
    final bytes = await pdf.save();

    // Encode as base64 string
    final base64String = base64Encode(bytes);

    return base64String;
  }

  pw.Widget _buildHeader(RiskLevel riskLevel) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: _getRiskColor(riskLevel),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'PAWFECT APP',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Emergency Poisoning Report',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Text(
              _getRiskLevelText(riskLevel),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _getRiskColor(riskLevel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSection({
    required String title,
    required List<pw.Widget> content,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: content,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
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

  PdfColor _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return PdfColors.green700;
      case RiskLevel.moderate:
        return PdfColors.orange700;
      case RiskLevel.high:
        return PdfColors.deepOrange700;
      case RiskLevel.emergency:
        return PdfColors.red700;
    }
  }
}
