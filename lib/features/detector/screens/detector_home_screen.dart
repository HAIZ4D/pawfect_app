import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/pet_model.dart';
import '../../pawbook/providers/pet_provider.dart';
import 'illness_detector_camera_screen.dart';
import 'poisoning_detection_screen.dart';

/// Detector — editorial spread with atmospheric warmth.
///
/// Layered visual stack (back to front):
///   • Cream page + paw watermarks (LiquidBackground)
///   • Soft peach radial halo at the top of the body — feels like a
///     warm light source, not just a flat surface
///   • Editorial header (rule + display + italic accent)
///   • Two numbered cards with cream-tinted surfaces, ghost numerals,
///     accent stripes, text-link CTAs
///   • An "About these tools" editorial sidebar (italic, hairline-framed)
///   • Footer signature ornament + whisper disclaimer
///
/// Strict palette: cream / white / orange / ink. Red is reserved for
/// the emergency tile.
class DetectorHomeScreen extends StatelessWidget {
  const DetectorHomeScreen({super.key});

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _emergency = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Detector',
        subtitle: 'AI-powered health analysis',
        icon: Icons.healing_rounded,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.7),
          // Atmospheric warm halo — soft peach radial centred near the
          // header so the eye drifts to the display headline.
          Positioned(
            top: topInset + 60,
            left: -120,
            right: -120,
            height: 360,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.7,
                    colors: [
                      const Color(0xFFFFD9A8).withOpacity(0.55),
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
              padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditorialHeader(),
                  const SizedBox(height: 28),
                  const _Ornament(),
                  const SizedBox(height: 26),
                  _NumberedCard(
                    number: '01',
                    label: 'AI VISION',
                    title: 'Visual diagnosis',
                    description:
                        'Photo or symptoms. Skin, eyes, wounds, behaviour patterns.',
                    cta: 'Begin',
                    accentColor: PawfectColors.pawfectOrange,
                    isDark: false,
                    detail: 'Best for visible concerns.',
                    onTap: () => _startIllness(context),
                  ),
                  const SizedBox(height: 14),
                  _NumberedCard(
                    number: '02',
                    label: 'EMERGENCY',
                    title: 'Toxin triage',
                    description:
                        'Toxic exposure. First aid steps. Nearest open vet.',
                    cta: 'Open',
                    accentColor: _emergency,
                    isDark: true,
                    detail: 'Use when minutes matter.',
                    onTap: () => _startPoisoning(context),
                  ),
                  const SizedBox(height: 32),
                  const _Ornament(),
                  const SizedBox(height: 26),
                  _buildAboutPanel(),
                  const SizedBox(height: 36),
                  _buildSignatureFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Editorial header ──────────────────────
  Widget _buildEditorialHeader() {
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
              'DETECTION',
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
              'TWO TOOLS',
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
          'Look closer.',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "See what they can't say.",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: PawfectColors.pawfectOrange,
            letterSpacing: -0.4,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        // Subtle contextual lead — italic line, ink-soft, sits like a
        // magazine kicker beneath the headline.
        Text(
          'Two ways to read the early signs your pet keeps to themselves.',
          style: TextStyle(
            fontSize: 13.5,
            color: _inkSoft.withOpacity(0.92),
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── About sidebar ────────────────────────
  Widget _buildAboutPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF6E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ABOUT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 22, height: 1, color: _hairline),
              const SizedBox(width: 12),
              const Text(
                'THE TOOLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _aboutLine(
            label: 'Visual diagnosis',
            body:
                'Reads a single photo for skin, wound, eye and posture cues, then asks symptoms to narrow it down.',
          ),
          const SizedBox(height: 14),
          _aboutLine(
            label: 'Toxin triage',
            body:
                'Maps your description to known hazards. Returns urgency, first aid, and the nearest open clinic.',
          ),
        ],
      ),
    );
  }

  Widget _aboutLine({required String label, required String body}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13.5,
          color: _ink,
          height: 1.55,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: '$label.  ',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.1,
            ),
          ),
          TextSpan(
            text: body,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: _inkSoft.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Signature footer ─────────────────────
  /// Magazine colophon: hairline rule + open ring + Pawfect logo +
  /// italic medical disclaimer (the screen's required vet-care
  /// reminder doubles as the tagline beneath the mark).
  Widget _buildSignatureFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 1,
              color: PawfectColors.pawfectOrange.withOpacity(0.35),
            ),
            const SizedBox(width: 12),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PawfectColors.pawfectOrange,
                  width: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 1,
              color: PawfectColors.pawfectOrange.withOpacity(0.35),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Image.asset(
          'assets/images/pawfect-logo.png',
          width: 200,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          'Care, not diagnosis. Speak with a licensed vet for treatment.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: _inkSoft.withOpacity(0.7),
            height: 1.5,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Navigation ───────────────────────────
  void _startIllness(BuildContext context) {
    HapticFeedback.lightImpact();
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    if (!petProvider.hasPets) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IllnessDetectorCameraScreen(),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PetSelectorSheet(pets: petProvider.pets),
    );
  }

  void _startPoisoning(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PoisoningDetectionScreen(),
      ),
    );
  }
}

// ─────────────────────────── Ornament rule ─────────────────────────
/// A small horizontal ornament: hairline + open orange ring + hairline.
/// Used as the section divider throughout the screen — premium,
/// restrained, anchors the brand without shouting.
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

// ─────────────────────────── Numbered card ────────────────────────
class _NumberedCard extends StatefulWidget {
  final String number;
  final String label;
  final String title;
  final String description;
  final String detail;
  final String cta;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NumberedCard({
    required this.number,
    required this.label,
    required this.title,
    required this.description,
    required this.detail,
    required this.cta,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NumberedCard> createState() => _NumberedCardState();
}

class _NumberedCardState extends State<_NumberedCard> {
  bool _pressed = false;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final foreground = isDark ? Colors.white : _ink;
    final muted = isDark ? Colors.white.withOpacity(0.65) : _inkSoft;
    final detailColor =
        isDark ? Colors.white.withOpacity(0.55) : _inkSoft.withOpacity(0.75);
    final ghostText = isDark
        ? Colors.white.withOpacity(0.07)
        : _ink.withOpacity(0.05);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [_ink, _inkDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF6E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: isDark
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.88),
                    width: 1.2,
                  ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? _ink.withOpacity(0.32)
                    : const Color(0x18000000),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Ghost numeral — huge, off-edge, the editorial signature
                Positioned(
                  top: -22,
                  right: -10,
                  child: Text(
                    widget.number,
                    style: TextStyle(
                      fontSize: 184,
                      fontWeight: FontWeight.w900,
                      color: ghostText,
                      height: 1.0,
                      letterSpacing: -7,
                    ),
                  ),
                ),
                // Decorative paw watermark — soft, atmospheric (only on
                // the white card so the dark card stays austere)
                if (!isDark)
                  Positioned(
                    bottom: -16,
                    right: 12,
                    child: Transform.rotate(
                      angle: -0.32,
                      child: Icon(
                        Icons.pets_rounded,
                        size: 78,
                        color: PawfectColors.pawfectOrange.withOpacity(0.08),
                      ),
                    ),
                  ),
                // Left accent stripe — short, restrained
                Positioned(
                  left: 0,
                  top: 28,
                  bottom: 28,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top: label row + italic detail
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: widget.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: widget.accentColor,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.detail,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: detailColor,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      // Bottom: title + description + CTA rule
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: foreground,
                              letterSpacing: -0.6,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: muted,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          // CTA — caps + rule + arrow
                          Row(
                            children: [
                              Text(
                                widget.cta.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: widget.accentColor,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 22,
                                height: 1,
                                color: widget.accentColor,
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: widget.accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Pet selector sheet ─────────────────────
class _PetSelectorSheet extends StatelessWidget {
  final List<PetModel> pets;
  const _PetSelectorSheet({required this.pets});

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PawfectColors.pawfectCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 12,
                    decoration: BoxDecoration(
                      color: PawfectColors.pawfectOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CHOOSE A PET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Who are we checking?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.6,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: pets
                        .map((pet) => _buildPetTile(context, pet))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IllnessDetectorCameraScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SCAN WITHOUT A PET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _inkSoft,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 18, height: 1, color: _inkSoft),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetTile(BuildContext context, PetModel pet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IllnessDetectorCameraScreen(selectedPet: pet),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF6E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.88),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFEAD5),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: pet.imageBase64 != null
                        ? pet.getDecodedImage()
                        : const Icon(
                            Icons.pets_rounded,
                            color: PawfectColors.pawfectOrange,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pet.breed} · ${pet.getAge()}',
                        style: const TextStyle(
                          fontSize: 12,
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
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: PawfectColors.pawfectOrange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
