import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/pet_model.dart';
import '../../../models/diagnosis_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../detector/repositories/illness_detector_repository.dart';
import '../../detector/screens/diagnosis_detail_screen.dart';
import 'qr_medical_share_screen.dart';
import 'qr_scanner_screen.dart';

/// Pet medical history — premium liquid-glass timeline of saved AI
/// diagnoses for a single pet.
class PetMedicalHistoryScreen extends StatefulWidget {
  final PetModel pet;

  const PetMedicalHistoryScreen({super.key, required this.pet});

  @override
  State<PetMedicalHistoryScreen> createState() =>
      _PetMedicalHistoryScreenState();
}

class _PetMedicalHistoryScreenState extends State<PetMedicalHistoryScreen> {
  final IllnessDetectorRepository _repository = IllnessDetectorRepository();
  List<DiagnosisModel> _diagnoses = [];
  bool _isLoading = true;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _peach = Color(0xFFFFEAD5);

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
        const SnackBar(
          content: Text('Please log in to share medical profile'),
        ),
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

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: LiquidAppBar(
        title: '${widget.pet.name}\'s PawBook',
        subtitle: 'Medical timeline',
        icon: Icons.medical_services_rounded,
        showBackButton: true,
        actions: [
          GestureDetector(
            onTap: _scanQrCode,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 18,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: PawfectColors.pawfectOrange,
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _loadDiagnoses,
              color: PawfectColors.pawfectOrange,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, topInset + 132, 20, 36),
                children: [
                  _buildSummaryHeader(),
                  const SizedBox(height: 18),
                  if (_diagnoses.isNotEmpty) ...[
                    _buildShareCta(),
                    const SizedBox(height: 22),
                    _buildSectionEyebrow(
                      'TIMELINE',
                      '${_diagnoses.length} entries',
                    ),
                    const SizedBox(height: 12),
                    ..._diagnoses.map(_buildDiagnosisCard),
                  ] else
                    _buildEmptyState(),
                  const SizedBox(height: 24),
                  _buildDisclaimer(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── Summary header ───────────────────────────
  Widget _buildSummaryHeader() {
    final emergencyCount = _diagnoses
        .where((d) => d.urgencyLevel == 'EMERGENCY')
        .length;
    final highCount =
        _diagnoses.where((d) => d.urgencyLevel == 'HIGH').length;

    return GlassCard(
      radius: 26,
      blur: 20,
      tintOpacity: 0.55,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      PawfectColors.pawfectOrange,
                      Color(0xFFFFB347),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PawfectColors.pawfectOrange.withOpacity(0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pet.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.pet.breed} • ${widget.pet.species}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Total',
                  value: '${_diagnoses.length}',
                  accent: const Color(0xFF3E6BC6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  label: 'High',
                  value: '$highCount',
                  accent: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  label: 'Emergency',
                  value: '$emergencyCount',
                  accent: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.65),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: _inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Share CTA ───────────────────────────
  Widget _buildShareCta() {
    return GlassCard(
      radius: 22,
      blur: 16,
      tintOpacity: 0.5,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      onTap: _shareQrCode,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _peach.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Color(0xFFE07B2A),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with your vet',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Generate a QR code with the full timeline',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Section eyebrow ───────────────────────────
  Widget _buildSectionEyebrow(String label, String trailing) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: PawfectColors.pawfectOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _ink,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 11,
            color: _inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Diagnosis card ───────────────────────────
  Widget _buildDiagnosisCard(DiagnosisModel diagnosis) {
    final urgencyColor = _getUrgencyColor(diagnosis.urgencyLevel);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 22,
        blur: 16,
        tintOpacity: 0.52,
        padding: const EdgeInsets.all(16),
        onTap: () => _viewDiagnosisDetail(diagnosis),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: urgencyColor.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _urgencyIcon(diagnosis.urgencyLevel),
                          size: 12,
                          color: urgencyColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            diagnosis.urgencyLabel,
                            style: TextStyle(
                              color: urgencyColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(diagnosis.timestamp),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _inkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              diagnosis.condition,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _cleanText(diagnosis.explanation),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: _inkSoft,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (diagnosis.symptoms.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...diagnosis.symptoms.take(3).map(
                        (symptom) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCE9FF).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            _cleanText(symptom),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF3E6BC6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  if (diagnosis.symptoms.length > 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                      child: Text(
                        '+${diagnosis.symptoms.length - 3} more',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 13,
                  color: _inkSoft.withOpacity(0.8),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '${diagnosis.confidencePercentage} confidence',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'View details',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: PawfectColors.pawfectOrange,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: PawfectColors.pawfectOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Empty state ───────────────────────────
  Widget _buildEmptyState() {
    return GlassCard(
      radius: 26,
      blur: 18,
      tintOpacity: 0.5,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _peach.withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              size: 34,
              color: Color(0xFFE07B2A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No records yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Diagnoses from the AI Illness Detector will\nappear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: _inkSoft,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Disclaimer ───────────────────────────
  Widget _buildDisclaimer() {
    return GlassCard(
      radius: 18,
      blur: 12,
      tintOpacity: 0.45,
      elevated: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: _inkSoft.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI-assisted records — always confirm with a licensed veterinarian for medical decisions.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: _inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Helpers ───────────────────────────
  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'EMERGENCY':
        return const Color(0xFFD32F2F);
      case 'HIGH':
        return const Color(0xFFE65100);
      case 'MODERATE':
        return const Color(0xFFF57C00);
      case 'LOW':
        return const Color(0xFF2E8A68);
      default:
        return _inkSoft;
    }
  }

  IconData _urgencyIcon(String urgency) {
    switch (urgency) {
      case 'EMERGENCY':
        return Icons.warning_rounded;
      case 'HIGH':
        return Icons.error_rounded;
      case 'MODERATE':
        return Icons.shield_rounded;
      case 'LOW':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
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
}
