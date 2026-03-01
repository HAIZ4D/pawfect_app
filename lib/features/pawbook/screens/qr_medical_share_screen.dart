import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/shareable_medical_profile.dart';
import '../../../models/pet_model.dart';
import '../../../models/diagnosis_model.dart';
import '../../../core/constants/colors.dart';
import 'dart:ui' as ui;

class QrMedicalShareScreen extends StatefulWidget {
  final PetModel pet;
  final List<DiagnosisModel> diagnoses;
  final String ownerName;

  const QrMedicalShareScreen({
    super.key,
    required this.pet,
    required this.diagnoses,
    required this.ownerName,
  });

  @override
  State<QrMedicalShareScreen> createState() => _QrMedicalShareScreenState();
}

class _QrMedicalShareScreenState extends State<QrMedicalShareScreen> {
  late ShareableMedicalProfile _profile;
  String? _qrData;
  int _includedDiagnosesCount = 0;

  @override
  void initState() {
    super.initState();
    _generateQrData();
  }

  void _generateQrData() {
    _profile = ShareableMedicalProfile(
      pet: widget.pet,
      diagnoses: widget.diagnoses,
      sharedAt: DateTime.now(),
      ownerId: widget.pet.userId ?? '',
      ownerName: widget.ownerName,
    );

    // Create minimal profile data for QR code
    // QR codes can only handle ~2953 bytes maximum
    final minimalProfile = ShareableMedicalProfile(
      pet: PetModel(
        id: _profile.pet.id,
        userId: _profile.pet.userId,
        name: _profile.pet.name,
        species: _profile.pet.species,
        breed: _profile.pet.breed,
        gender: _profile.pet.gender,
        birthdate: _profile.pet.birthdate,
        color: null, // Remove optional fields
        weight: null,
        microchipId: null,
        notes: null,
        imageBase64: null,
      ),
      diagnoses: _profile.diagnoses
          .take(1) // Only 1 most recent diagnosis
          .map((d) => DiagnosisModel(
                id: d.id,
                condition: d.condition,
                symptoms: d.symptoms.take(2).toList(), // Max 2 symptoms
                urgencyLevel: d.urgencyLevel,
                confidence: d.confidence,
                explanation: d.explanation.length > 50
                    ? '${d.explanation.substring(0, 50)}...'
                    : d.explanation,
                recommendations: d.recommendations.take(1).map((r) => r.length > 30 ? '${r.substring(0, 30)}...' : r).toList(),
                firstAidInstructions: d.firstAidInstructions.length > 50
                    ? '${d.firstAidInstructions.substring(0, 50)}...'
                    : d.firstAidInstructions,
                vetReport: '', // Remove
                mlDetections: [], // Remove
                mlAnalysis: null, // Remove
                riskFactors: [], // Remove
                timestamp: d.timestamp,
                petId: d.petId,
                petName: d.petName,
                imageUrl: null, // Remove
                imageBase64: null, // Remove
              ))
          .toList(),
      sharedAt: _profile.sharedAt,
      ownerId: _profile.ownerId,
      ownerName: _profile.ownerName,
    );

    final jsonString = minimalProfile.toJsonString();

    print('QR Data length: ${jsonString.length} bytes');

    _qrData = jsonString;
    _includedDiagnosesCount = minimalProfile.diagnoses.length;
  }

  Future<void> _shareQrCode() async {
    try {
      // Create QR code image
      final qrValidationResult = QrValidator.validate(
        data: _qrData!,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );

        final picData = await painter.toImageData(
          500,
          format: ui.ImageByteFormat.png,
        );

        if (picData != null) {
          final buffer = picData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final file = await File('${tempDir.path}/pet_medical_qr.png').create();
          await file.writeAsBytes(buffer);

          await Share.shareXFiles(
            [XFile(file.path)],
            text: '${widget.pet.name}\'s Medical Profile QR Code',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Share Medical Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: PawfectColors.pawfectOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQrCode,
            tooltip: 'Share QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildQrCodeCard(),
            const SizedBox(height: 20),
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: PawfectColors.pawfectOrange.withOpacity(0.1),
              child: widget.pet.imageBase64 != null
                  ? ClipOval(child: widget.pet.getDecodedImage())
                  : const Icon(Icons.pets, size: 30, color: PawfectColors.pawfectOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pet.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.pet.breed} • ${widget.pet.getAge()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PawfectColors.pawfectOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _includedDiagnosesCount > 0
                          ? '$_includedDiagnosesCount of ${widget.diagnoses.length} Record (Summary)'
                          : '${widget.diagnoses.length} Medical Records',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PawfectColors.pawfectOrange,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildQrCodeCard() {
    if (_qrData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check QR data size
    final dataSize = _qrData!.length;
    final isLargeData = dataSize > 2000;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isLargeData)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Large QR code - may be harder to scan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: _qrData!.length > 2953
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[700]),
                        const SizedBox(height: 16),
                        Text(
                          'Data too large for QR code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Size: ${_qrData!.length} bytes (max: 2953)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    )
                  : QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 280,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.L,
                      errorStateBuilder: (context, error) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.red[700]),
                            const SizedBox(height: 16),
                            Text(
                              'Error generating QR code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to View Medical Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data size: ${(dataSize / 1024).toStringAsFixed(2)} KB',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: PawfectColors.pawfectOrange),
                const SizedBox(width: 8),
                const Text(
                  'How to Share',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              '1',
              'Show this QR code to your vet',
            ),
            _buildInstructionItem(
              '2',
              'Vet scans the code using the Pawfect app',
            ),
            _buildInstructionItem(
              '3',
              'Medical history is displayed instantly',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data is automatically optimized for QR code size',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_includedDiagnosesCount < widget.diagnoses.length) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing summary of most recent diagnosis only due to QR size limits',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: PawfectColors.pawfectOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
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
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
