import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/pet_model.dart';
import '../../../models/diagnosis_model.dart';
import '../../../core/constants/colors.dart';
import '../../detector/repositories/illness_detector_repository.dart';
import '../../detector/screens/diagnosis_detail_screen.dart';
import 'qr_medical_share_screen.dart';
import 'qr_scanner_screen.dart';

/// Screen to display pet's medical history (saved diagnoses)
class PetMedicalHistoryScreen extends StatefulWidget {
  final PetModel pet;

  const PetMedicalHistoryScreen({super.key, required this.pet});

  @override
  State<PetMedicalHistoryScreen> createState() => _PetMedicalHistoryScreenState();
}

class _PetMedicalHistoryScreenState extends State<PetMedicalHistoryScreen> {
  final IllnessDetectorRepository _repository = IllnessDetectorRepository();
  List<DiagnosisModel> _diagnoses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnoses();
  }

  Future<void> _loadDiagnoses() async {
    setState(() => _isLoading = true);

    final diagnoses = await _repository.getPetDiagnoses(widget.pet.id!);

    if (mounted) {
      setState(() {
        _diagnoses = diagnoses;
        _isLoading = false;
      });
    }
  }

  void _shareQrCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to share medical profile')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrMedicalShareScreen(
          pet: widget.pet,
          diagnoses: _diagnoses,
          ownerName: user.displayName ?? 'Pet Owner',
        ),
      ),
    );
  }

  void _scanQrCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.pet.name}\'s Medical History'),
        backgroundColor: PawfectColors.pawfectOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQrCode,
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_diagnoses.isNotEmpty) _buildShareButton(),
                Expanded(
                  child: _diagnoses.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadDiagnoses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _diagnoses.length,
                            itemBuilder: (context, index) {
                              return _buildDiagnosisCard(_diagnoses[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildShareButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ElevatedButton.icon(
        onPressed: _shareQrCode,
        icon: const Icon(Icons.qr_code, color: Colors.white),
        label: const Text(
          'Share Medical Profile via QR Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: PawfectColors.pawfectOrange,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Medical Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diagnoses saved from AI Illness Detector\nwill appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(DiagnosisModel diagnosis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewDiagnosisDetail(diagnosis),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(diagnosis.urgencyLevel).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            diagnosis.urgencyEmoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            diagnosis.urgencyLabel,
                            style: TextStyle(
                              color: _getUrgencyColor(diagnosis.urgencyLevel),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, yyyy').format(diagnosis.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  diagnosis.condition,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _cleanText(diagnosis.explanation),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                if (diagnosis.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: diagnosis.symptoms.take(3).map((symptom) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _cleanText(symptom),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (diagnosis.symptoms.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+${diagnosis.symptoms.length - 3} more',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${diagnosis.confidencePercentage} Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: PawfectColors.pawfectOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: PawfectColors.pawfectOrange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
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

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .trim();
  }

  void _viewDiagnosisDetail(DiagnosisModel diagnosis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiagnosisDetailScreen(
          diagnosis: diagnosis,
          pet: widget.pet,
        ),
      ),
    );
  }
}
