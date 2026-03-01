import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../models/pet_model.dart';
import '../../../models/poisoning_incident_model.dart';
import '../../../models/poison_substance_model.dart';
import '../../../repositories/poisoning_incident_repository.dart';
import 'pdf_viewer_screen.dart';

class PoisoningIncidentsScreen extends StatefulWidget {
  final PetModel pet;

  const PoisoningIncidentsScreen({
    Key? key,
    required this.pet,
  }) : super(key: key);

  @override
  State<PoisoningIncidentsScreen> createState() => _PoisoningIncidentsScreenState();
}

class _PoisoningIncidentsScreenState extends State<PoisoningIncidentsScreen> {
  final _repository = PoisoningIncidentRepository();
  List<PoisoningIncidentModel> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);

    try {
      final incidents = await _repository.getPetIncidents(widget.pet.id!);
      incidents.sort((a, b) => b.incidentTime.compareTo(a.incidentTime));

      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading incidents: $e');
      setState(() => _isLoading = false);
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
        return 'LOW';
      case RiskLevel.moderate:
        return 'MODERATE';
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.emergency:
        return 'EMERGENCY';
    }
  }

  IconData _getCategoryIcon(PoisonCategory category) {
    switch (category) {
      case PoisonCategory.toxicFoods:
        return Icons.fastfood;
      case PoisonCategory.plants:
        return Icons.local_florist;
      case PoisonCategory.medicines:
        return Icons.medication;
      case PoisonCategory.chemicals:
        return Icons.science;
      case PoisonCategory.householdItems:
        return Icons.home;
    }
  }

  String _getTimeSince(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else if (duration.inDays < 30) {
      return '${duration.inDays} days ago';
    } else {
      return '${duration.inDays ~/ 30} months ago';
    }
  }

  void _viewIncidentDetails(PoisoningIncidentModel incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getRiskColor(incident.assessedRiskLevel).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning,
                              color: _getRiskColor(incident.assessedRiskLevel),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incident.substanceName,
                                  style: PawfectTextStyles.h4,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getRiskColor(incident.assessedRiskLevel),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getRiskText(incident.assessedRiskLevel),
                                    style: PawfectTextStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Incident Info
                      _buildInfoSection('Incident Details', [
                        _buildInfoRow('Pet:', incident.petName),
                        _buildInfoRow('Category:', incident.categoryName),
                        _buildInfoRow('Amount:', incident.amountIngested),
                        _buildInfoRow('Time:', '${incident.incidentTime.toString().substring(0, 16)} (${_getTimeSince(incident.incidentTime)})'),
                      ]),

                      const SizedBox(height: 16),

                      // Symptoms
                      if (incident.symptoms.isNotEmpty)
                        _buildInfoSection('Symptoms Observed', [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: incident.symptoms.map((symptom) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PawfectColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: PawfectColors.error.withOpacity(0.3)),
                                ),
                                child: Text(
                                  symptom,
                                  style: PawfectTextStyles.bodySmall.copyWith(
                                    color: PawfectColors.error,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ]),

                      const SizedBox(height: 16),

                      // First Aid
                      if (incident.firstAidGiven.isNotEmpty)
                        _buildInfoSection('First Aid Given', [
                          Text(
                            incident.firstAidGiven,
                            style: PawfectTextStyles.bodyMedium,
                          ),
                        ]),

                      const SizedBox(height: 16),

                      // Vet Contact
                      _buildInfoSection('Veterinary Care', [
                        _buildInfoRow('Vet Contacted:', incident.vetContacted ? 'Yes ✓' : 'No'),
                        if (incident.vetNotes != null && incident.vetNotes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vet Notes:',
                                  style: PawfectTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  incident.vetNotes!,
                                  style: PawfectTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                      ]),

                      const SizedBox(height: 24),

                      // View PDF Button
                      if (incident.pdfReportBase64 != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                  pdfBase64: incident.pdfReportBase64!,
                                  title: '${incident.substanceName} - ${incident.petName}',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('View PDF Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PawfectColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PawfectColors.pawfectCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PawfectTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
            width: 100,
            child: Text(
              label,
              style: PawfectTextStyles.bodyMedium.copyWith(
                color: PawfectColors.textHint,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: PawfectTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: AppBar(
        title: Text('Poisoning History', style: PawfectTextStyles.h3),
        backgroundColor: PawfectColors.error,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: PawfectColors.success,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Poisoning Incidents',
                          style: PawfectTextStyles.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Great news! ${widget.pet.name} has no recorded poisoning incidents.',
                          style: PawfectTextStyles.bodyMedium.copyWith(
                            color: PawfectColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadIncidents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _incidents.length,
                    itemBuilder: (context, index) {
                      final incident = _incidents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getRiskColor(incident.assessedRiskLevel).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _viewIncidentDetails(incident),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getRiskColor(incident.assessedRiskLevel).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(incident.category),
                                    color: _getRiskColor(incident.assessedRiskLevel),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        incident.substanceName,
                                        style: PawfectTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${incident.categoryName} • ${_getTimeSince(incident.incidentTime)}',
                                        style: PawfectTextStyles.bodySmall.copyWith(
                                          color: PawfectColors.textHint,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRiskColor(incident.assessedRiskLevel),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getRiskText(incident.assessedRiskLevel),
                                              style: PawfectTextStyles.bodySmall.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (incident.pdfReportBase64 != null) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.picture_as_pdf,
                                              size: 16,
                                              color: PawfectColors.textHint,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(Icons.chevron_right, color: PawfectColors.textHint),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
