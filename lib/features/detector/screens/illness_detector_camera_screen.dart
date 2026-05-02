import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../models/pet_model.dart';
import '../../../models/symptom_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/ai_loading_animation.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../widgets/symptom_questionnaire_widget.dart';
import 'illness_result_screen.dart';
import '../../../services/gemini_service.dart';
import '../../../services/ai_agent_service.dart';

/// Illness detector consultation — editorial spread.
///
/// Two layers of input (a photo, then signs) collected through numbered
/// magazine sections. Strict palette: cream, white, orange, ink. Logic
/// (image picker, symptom widget callbacks, Gemini + AIAgent pipeline)
/// is preserved verbatim from the previous version.
class IllnessDetectorCameraScreen extends StatefulWidget {
  final PetModel? selectedPet;

  const IllnessDetectorCameraScreen({super.key, this.selectedPet});

  @override
  State<IllnessDetectorCameraScreen> createState() =>
      _IllnessDetectorCameraScreenState();
}

class _IllnessDetectorCameraScreenState
    extends State<IllnessDetectorCameraScreen> {
  // ─── State preserved verbatim ─────────────────────────────────────
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  List<SymptomModel> _selectedSymptoms = [];

  // ─── Palette ──────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Illness Detector',
        subtitle: 'Visual diagnosis',
        icon: Icons.health_and_safety_rounded,
        showBackButton: true,
      ),
      body: _isAnalyzing ? _buildAnalyzingView() : _buildContent(),
    );
  }

  // ─────────────────────────── Content ───────────────────────────
  Widget _buildContent() {
    final topInset = MediaQuery.of(context).padding.top;
    final canAnalyze =
        _selectedImage != null || _selectedSymptoms.isNotEmpty;
    return Stack(
      children: [
        const LiquidBackground(density: 0.55),
        // Atmospheric peach halo near the top — same warmth as the
        // detector home so the journey feels coherent.
        Positioned(
          top: topInset + 60,
          left: -120,
          right: -120,
          height: 320,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.7,
                  colors: [
                    const Color(0xFFFFD9A8).withOpacity(0.5),
                    const Color(0xFFFFD9A8).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditorialIntro(),
                const SizedBox(height: 24),
                const _Ornament(),
                const SizedBox(height: 22),
                _buildPetTag(),
                const SizedBox(height: 28),
                const _Ornament(),
                const SizedBox(height: 22),
                _buildPhotoSection(),
                const SizedBox(height: 28),
                const _Ornament(),
                const SizedBox(height: 22),
                _buildSymptomsSection(),
                const SizedBox(height: 28),
                _buildPrivacyNote(),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildStickyCTA(canAnalyze: canAnalyze),
        ),
      ],
    );
  }

  // ─────────────────────────── Editorial intro ──────────────────────
  Widget _buildEditorialIntro() {
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
              'AI VISION',
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
              'CONSULTATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _inkSoft,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Tell me\neverything.',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A photo, a few signs. We read between them.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: PawfectColors.pawfectOrange,
            letterSpacing: -0.2,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Pet tag ──────────────────────────────
  Widget _buildPetTag() {
    if (widget.selectedPet == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.85),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: _inkSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Scanning without a pet. Results will be generic.',
                style: TextStyle(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft.withOpacity(0.95),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final pet = widget.selectedPet!;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF6E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: PawfectColors.pawfectOrange.withOpacity(0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: pet.imageBase64 != null
                  ? pet.getDecodedImage()
                  : const Center(
                      child: Icon(
                        Icons.pets_rounded,
                        color: PawfectColors.pawfectOrange,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 10,
                      decoration: BoxDecoration(
                        color: PawfectColors.pawfectOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'SCANNING FOR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${pet.breed} · ${pet.species}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _inkSoft,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Photo section (01) ───────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionEyebrow(number: '01', label: 'PHOTO'),
        const SizedBox(height: 14),
        const Text(
          'Capture evidence.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Optional. Photos sharpen the diagnosis.',
          style: TextStyle(
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: _inkSoft.withOpacity(0.9),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        if (_selectedImage != null)
          _buildImagePreview()
        else
          _buildImagePlaceholder(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'TAKE PHOTO',
                icon: Icons.photo_camera_rounded,
                isPrimary: true,
                onTap: _takePhoto,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: 'GALLERY',
                icon: Icons.photo_library_rounded,
                isPrimary: false,
                onTap: _pickFromGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 178,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF6E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: PawfectColors.pawfectOrange.withOpacity(0.28),
          width: 1.4,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: PawfectColors.pawfectOrange.withOpacity(0.32),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.photo_camera_rounded,
              size: 26,
              color: PawfectColors.pawfectOrange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add a photo to anchor the read.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _ink.withOpacity(0.92),
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Skin, eyes, wounds, or general look.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: _inkSoft.withOpacity(0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        // Top dark gradient for badge legibility
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.32),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42],
                ),
              ),
            ),
          ),
        ),
        // Hairline white border for premium framing
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
        // Top-left ready badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const Text(
                  'PHOTO READY',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Top-right close
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedImage = null);
            },
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: _ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Symptoms section (02) ────────────────
  Widget _buildSymptomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionEyebrow(number: '02', label: 'SIGNS'),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Text(
                'Tell us the signs.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.8,
                  height: 1.05,
                ),
              ),
            ),
            if (_selectedSymptoms.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedSymptoms.length} SELECTED',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Tap everything you've noticed.",
          style: TextStyle(
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: _inkSoft.withOpacity(0.9),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        // The questionnaire widget owns its own visual styling. Wrapping
        // it in a soft white surface keeps it visually anchored to the
        // editorial language without overriding the widget itself.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.88),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SymptomQuestionnaireWidget(
            onSymptomsChanged: (symptoms) {
              setState(() => _selectedSymptoms = symptoms);
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Privacy note ─────────────────────────
  Widget _buildPrivacyNote() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          'Photos are read by Gemini and only saved if you keep this case in PawBook.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: _inkSoft.withOpacity(0.85),
            height: 1.55,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Section eyebrow ──────────────────────
  Widget _buildSectionEyebrow({
    required String number,
    required String label,
  }) {
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
        const SizedBox(width: 10),
        Text(
          number,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: PawfectColors.pawfectOrange,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 28, height: 1, color: _hairline),
        const SizedBox(width: 12),
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
    );
  }

  // ─────────────────────────── Action button ────────────────────────
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [_ink, _inkDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 1.2,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: _ink.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? Colors.white : _ink,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: isPrimary ? Colors.white : _ink,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Sticky CTA ───────────────────────────
  Widget _buildStickyCTA({required bool canAnalyze}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PawfectColors.pawfectCream.withOpacity(0),
            PawfectColors.pawfectCream,
            PawfectColors.pawfectCream,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: canAnalyze
            ? _buildPrimaryAnalyseButton(
                key: const ValueKey('analyse'),
              )
            : _buildHint(key: const ValueKey('hint')),
      ),
    );
  }

  Widget _buildPrimaryAnalyseButton({Key? key}) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: _analyzeWithAI,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                PawfectColors.pawfectOrange,
                Color(0xFFFFB347),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: PawfectColors.pawfectOrange.withOpacity(0.42),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ANALYSE WITH GEMINI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(width: 14),
              Container(width: 22, height: 1, color: Colors.white),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHint({Key? key}) {
    // Container width is forced to infinity so the card spans the
    // sticky bar, but height is left to wrap the text. A Row with
    // mainAxisAlignment.center is used instead of Center{} because
    // a bare Center inside an unsized Container would expand
    // vertically to fill the parent Align — which previously caused
    // the whole sticky bar to swell up and cover the screen.
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add a photo or pick a sign to begin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _inkSoft.withOpacity(0.95),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Analyzing view ───────────────────────
  Widget _buildAnalyzingView() {
    return AILoadingAnimation(
      title: 'AI Analysis in Progress',
      subtitle:
          "Our AI agent is carefully analyzing your pet's condition",
      steps: const [
        LoadingStep(emoji: '', text: 'Processing image with Gemini vision'),
        LoadingStep(emoji: '', text: 'Analyzing symptoms and patterns'),
        LoadingStep(emoji: '', text: 'Consulting Gemini AI'),
        LoadingStep(emoji: '', text: 'Generating diagnosis report'),
        LoadingStep(emoji: '', text: 'Preparing recommendations'),
      ],
    );
  }

  // ─────────────────────────── Actions (verbatim) ───────────────────
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() => _selectedImage = File(photo.path));
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeWithAI() async {
    HapticFeedback.lightImpact();
    setState(() => _isAnalyzing = true);

    try {
      final geminiService = GeminiService();
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception(
          'Gemini API key not configured. Please add GEMINI_API_KEY to .env file',
        );
      }
      await geminiService.initialize(apiKey);

      final aiAgent = AIAgentService(geminiService: geminiService);

      final diagnosis = await aiAgent.diagnose(
        symptoms: _selectedSymptoms,
        image: _selectedImage,
        pet: widget.selectedPet,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IllnessResultScreen(
              diagnosis: diagnosis,
              capturedImage: _selectedImage,
              pet: widget.selectedPet,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Analysis failed: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Something went wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: PawfectColors.pawfectOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
