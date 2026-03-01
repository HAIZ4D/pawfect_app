import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/diagnosis_model.dart';
import '../data/illness_database.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final List<String> selectedSymptomIds;
  final String? petName;

  const DiagnosisResultScreen({
    super.key,
    required this.selectedSymptomIds,
    this.petName,
  });

  @override
  Widget build(BuildContext context) {
    final diagnoses = IllnessDatabase.analyzeSymptoms(selectedSymptomIds);

    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: AppBar(
        title: Text(
          'Diagnosis Results',
          style: PawfectTextStyles.h3,
        ),
        backgroundColor: PawfectColors.pawfectOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: diagnoses.isEmpty
          ? _buildNoResults()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: diagnoses.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(diagnoses);
                }
                return _buildDiagnosisCard(diagnoses[index - 1]);
              },
            ),
    );
  }

  Widget _buildHeader(List<DiagnosisModel> diagnoses) {
    final hasEmergency = diagnoses.any((d) => d.isEmergency);

    return Column(
      children: [
        if (hasEmergency)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: PawfectColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY - SEEK IMMEDIATE CARE',
                        style: PawfectTextStyles.h4.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Call your vet or emergency animal hospital now',
                        style: PawfectTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [PawfectColors.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                petName != null
                    ? 'Results for $petName'
                    : 'Analysis Results',
                style: PawfectTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'Based on ${selectedSymptomIds.length} selected symptoms, here are the most likely conditions:',
                style: PawfectTextStyles.bodyMedium.copyWith(
                  color: PawfectColors.textHint,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PawfectColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: PawfectColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is an AI-assisted analysis. Always consult a veterinarian for proper diagnosis and treatment.',
                        style: PawfectTextStyles.bodySmall.copyWith(
                          color: PawfectColors.info,
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
    );
  }

  Widget _buildDiagnosisCard(DiagnosisModel diagnosis) {
    Color severityColor;
    switch (diagnosis.severity.toLowerCase()) {
      case 'emergency':
        severityColor = PawfectColors.error;
        break;
      case 'severe':
        severityColor = const Color(0xFFF57C00);
        break;
      case 'moderate':
        severityColor = PawfectColors.warning;
        break;
      default:
        severityColor = PawfectColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PawfectColors.cardShadow],
        border: diagnosis.isEmergency
            ? Border.all(color: PawfectColors.error, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diagnosis.illnessName,
                        style: PawfectTextStyles.h4,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: severityColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              diagnosis.severity.toUpperCase(),
                              style: PawfectTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Match: ${diagnosis.confidencePercentage}',
                            style: PawfectTextStyles.bodyMedium.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (diagnosis.requiresVet)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: severityColor,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: PawfectTextStyles.h5,
                ),
                const SizedBox(height: 8),
                Text(
                  diagnosis.description,
                  style: PawfectTextStyles.bodyMedium,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Possible Causes
          _buildSection(
            icon: Icons.psychology,
            title: 'Possible Causes',
            items: diagnosis.possibleCauses,
          ),

          const Divider(height: 1),

          // Recommendations
          _buildSection(
            icon: Icons.recommend,
            title: 'Recommendations',
            items: diagnosis.recommendations,
            color: PawfectColors.pawfectOrange,
          ),

          const Divider(height: 1),

          // Treatments
          _buildSection(
            icon: Icons.medication,
            title: 'Typical Treatments',
            items: diagnosis.treatments,
            color: PawfectColors.success,
          ),

          // Vet Warning
          if (diagnosis.requiresVet)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: severityColor),
              ),
              child: Row(
                children: [
                  Icon(
                    diagnosis.isEmergency
                        ? Icons.emergency
                        : Icons.local_hospital,
                    color: severityColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      diagnosis.isEmergency
                          ? 'Seek emergency veterinary care immediately'
                          : 'Veterinary consultation recommended',
                      style: PawfectTextStyles.bodyMedium.copyWith(
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> items,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color ?? PawfectColors.textBody,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: PawfectTextStyles.h5,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color ?? PawfectColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: PawfectTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [PawfectColors.cardShadow],
              ),
              child: const Icon(
                Icons.search_off,
                size: 60,
                color: PawfectColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Matches Found',
              style: PawfectTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              'The selected symptoms don\'t match any known conditions in our database. Please consult a veterinarian.',
              style: PawfectTextStyles.bodyLarge.copyWith(
                color: PawfectColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
