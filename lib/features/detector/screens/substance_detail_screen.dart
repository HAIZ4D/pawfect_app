import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/toxic_substance_model.dart';
import 'report_poisoning_incident_screen.dart';

class SubstanceDetailScreen extends StatelessWidget {
  final ToxicSubstanceModel substance;

  const SubstanceDetailScreen({super.key, required this.substance});

  @override
  Widget build(BuildContext context) {
    Color toxicityColor;
    switch (substance.toxicityLevel) {
      case ToxicityLevel.fatal:
        toxicityColor = const Color(0xFFD32F2F);
        break;
      case ToxicityLevel.severe:
        toxicityColor = const Color(0xFFF57C00);
        break;
      case ToxicityLevel.moderate:
        toxicityColor = PawfectColors.warning;
        break;
      case ToxicityLevel.mild:
        toxicityColor = PawfectColors.success;
    }

    final isEmergency = substance.toxicityLevel == ToxicityLevel.fatal ||
        substance.toxicityLevel == ToxicityLevel.severe;

    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      body: CustomScrollView(
        slivers: [
          // App Bar with substance name
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: toxicityColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                substance.name,
                style: PawfectTextStyles.h3.copyWith(color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      toxicityColor,
                      toxicityColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.warning,
                      size: 80,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // Emergency Alert
              if (isEmergency) _buildEmergencyAlert(toxicityColor),

              // Urgency & Time
              _buildUrgencyCard(toxicityColor),

              // Description
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'About This Substance',
                content: substance.description,
                color: PawfectColors.info,
              ),

              // Immediate Actions
              _buildActionCard(
                icon: Icons.emergency,
                title: 'IMMEDIATE ACTIONS',
                items: substance.immediateActions,
                color: PawfectColors.error,
              ),

              // What NOT to Do
              _buildActionCard(
                icon: Icons.block,
                title: 'What NOT to Do',
                items: substance.whatNotToDo,
                color: const Color(0xFFF57C00),
              ),

              // Symptoms
              _buildActionCard(
                icon: Icons.medical_services,
                title: 'Symptoms to Watch For',
                items: substance.symptoms,
                color: PawfectColors.warning,
              ),

              // Treatment
              _buildInfoCard(
                icon: Icons.local_hospital,
                title: 'Veterinary Treatment',
                content: substance.treatment,
                color: PawfectColors.success,
              ),

              // Additional Info
              if (substance.alternativeNames.isNotEmpty)
                _buildAlternativeNames(),

              // Bottom Spacing
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildEmergencyButtons(context),
    );
  }

  Widget _buildEmergencyAlert(Color color) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emergency,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMERGENCY',
                  style: PawfectTextStyles.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  substance.urgencyMessage,
                  style:
                      PawfectTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyCard(Color color) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [PawfectColors.cardShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  substance.toxicityLevel.name.toUpperCase(),
                  style: PawfectTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.timer, color: color),
              const SizedBox(width: 8),
              Text(
                '${substance.timeToReact} min',
                style: PawfectTextStyles.h4.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Time to seek veterinary care',
                    style: PawfectTextStyles.bodyMedium.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
          if (substance.induceVomiting)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PawfectColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PawfectColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: PawfectColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'May require induced vomiting (only under vet guidance)',
                        style: PawfectTextStyles.bodySmall
                            .copyWith(color: PawfectColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [PawfectColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: PawfectTextStyles.h5),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: PawfectTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [PawfectColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: PawfectTextStyles.h5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: PawfectTextStyles.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
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
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildAlternativeNames() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [PawfectColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label, color: PawfectColors.textHint, size: 24),
              const SizedBox(width: 8),
              Text('Also Known As', style: PawfectTextStyles.h5),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: substance.alternativeNames.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PawfectColors.borderLight),
                ),
                child: Text(
                  name,
                  style: PawfectTextStyles.bodySmall,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Report Incident Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReportPoisoningIncidentScreen(substance: substance),
                  ),
                );
              },
              icon: const Icon(Icons.report, size: 24),
              label: Text(
                'Report Incident & Generate PDF',
                style: PawfectTextStyles.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PawfectColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Add phone call functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Call your emergency veterinarian',
                            style: PawfectTextStyles.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: PawfectColors.error,
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 20),
                    label: Text(
                      'Call Vet',
                      style: PawfectTextStyles.bodyMedium
                          .copyWith(color: PawfectColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: PawfectColors.error, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Add phone call functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pet Poison Helpline: (855) 764-7661',
                            style: PawfectTextStyles.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: PawfectColors.info,
                        ),
                      );
                    },
                    icon: const Icon(Icons.contact_phone, size: 20),
                    label: Text(
                      'Helpline',
                      style: PawfectTextStyles.bodyMedium
                          .copyWith(color: PawfectColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: PawfectColors.error, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
}
