import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';

/// Vet Finder — editorial directory of nearby emergency clinics.
///
/// Currently shows a curated sample list plus a deep link into Google
/// Maps for live results. The screen is styled to match the rest of
/// the poison-alert flow: cream page, hairline-framed list, red
/// reserved exclusively for the emergency CTA and 24/7 chip.
class VetFinderScreen extends StatefulWidget {
  const VetFinderScreen({Key? key}) : super(key: key);

  @override
  State<VetFinderScreen> createState() => _VetFinderScreenState();
}

class _VetFinderScreenState extends State<VetFinderScreen> {
  // ─── State preserved verbatim ────────────────────────────────────
  final List<VetClinic> _vetClinics = [
    VetClinic(
      name: 'Emergency Veterinary Hospital',
      address: '123 Main Street',
      phone: '(555) 123-4567',
      isOpen24Hours: true,
      distance: 1.2,
    ),
    VetClinic(
      name: 'City Animal Clinic',
      address: '456 Oak Avenue',
      phone: '(555) 234-5678',
      isOpen24Hours: false,
      distance: 2.5,
    ),
    VetClinic(
      name: '24/7 Pet Emergency Center',
      address: '789 Elm Road',
      phone: '(555) 345-6789',
      isOpen24Hours: true,
      distance: 3.1,
    ),
  ];

  // ─── Palette ─────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _emergency = Color(0xFFD32F2F);
  static const Color _low = Color(0xFF2E8A68);

  // ─────────────────────────── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Vet Finder',
        subtitle: 'Nearest open clinics',
        icon: Icons.local_hospital_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.45),
          // Soft red halo at the top — emergency mood, restrained
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
                      _emergency.withOpacity(0.16),
                      _emergency.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
              children: [
                _buildEditorialHeader(),
                const SizedBox(height: 24),
                _buildLiveSearchCta(),
                if (kIsWeb) ...[
                  const SizedBox(height: 14),
                  _buildWebNotice(),
                ],
                const SizedBox(height: 26),
                const _Ornament(),
                const SizedBox(height: 22),
                _buildSampleEyebrow(),
                const SizedBox(height: 14),
                ..._vetClinics.map(_buildVetCard),
                const SizedBox(height: 24),
                _buildDisclaimer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Editorial header ─────────────────────
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
                color: _emergency,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'EMERGENCY',
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
              'NEAREST VETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _inkSoft,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Closest help.',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Minutes matter.',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: PawfectColors.pawfectOrange,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap "Search nearby" for live results in Maps, or call one of the curated samples below.',
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

  // ─────────────────────────── Live search CTA ──────────────────────
  Widget _buildLiveSearchCta() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _launchDirections();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_emergency, Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _emergency.withOpacity(0.38),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search nearby in Maps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Live clinics around you, open and rated.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_outward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Web notice ───────────────────────────
  Widget _buildWebNotice() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAEE), Color(0xFFFFF1D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: PawfectColors.pawfectOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Maps and live search work best in the mobile app.',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _ink.withOpacity(0.92),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Sample eyebrow ───────────────────────
  Widget _buildSampleEyebrow() {
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
        const Text(
          'SAMPLES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        Text(
          '${_vetClinics.length.toString().padLeft(2, "0")} CLINICS',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: _inkSoft,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Vet card ─────────────────────────────
  Widget _buildVetCard(VetClinic vet) {
    final accent = vet.isOpen24Hours ? _emergency : PawfectColors.pawfectOrange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVetDetails(vet),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF6E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: accent.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${vet.distance} km away',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: _inkSoft,
                              ),
                            ),
                          ),
                          if (vet.isOpen24Hours) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _low.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _low.withOpacity(0.32),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                '24/7',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: _low,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _launchPhone(vet.phone),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withOpacity(0.32),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.phone_rounded,
                        size: 16,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Disclaimer ──────────────────────────
  Widget _buildDisclaimer() {
    return Center(
      child: Column(
        children: [
          Container(width: 36, height: 1, color: _hairline),
          const SizedBox(height: 12),
          Text(
            'Sample list. Use Maps for live, verified clinics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _inkSoft.withOpacity(0.85),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Details sheet ────────────────────────
  void _showVetDetails(VetClinic vet) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _buildVetDetailsSheet(sheetContext, vet),
    );
  }

  Widget _buildVetDetailsSheet(BuildContext sheetContext, VetClinic vet) {
    final accent = vet.isOpen24Hours ? _emergency : PawfectColors.pawfectOrange;

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
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CLINIC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 18, height: 1, color: _hairline),
                  const SizedBox(width: 12),
                  if (vet.isOpen24Hours)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _low.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _low.withOpacity(0.32),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'OPEN 24/7',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: _low,
                          letterSpacing: 1.4,
                        ),
                      ),
                    )
                  else
                    Text(
                      'BUSINESS HOURS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: _inkSoft.withOpacity(0.8),
                        letterSpacing: 1.4,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                vet.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.7,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 18),
              _buildDetailRow(
                icon: Icons.location_on_outlined,
                label: 'ADDRESS',
                value: vet.address,
                accent: accent,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.phone_outlined,
                label: 'PHONE',
                value: vet.phone,
                accent: accent,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.directions_outlined,
                label: 'DISTANCE',
                value: '${vet.distance} km away',
                accent: accent,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _SheetActionTile(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _launchPhone(vet.phone);
                      },
                      label: 'CALL',
                      icon: Icons.phone_rounded,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _SheetActionTile(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _launchDirections();
                      },
                      label: 'DIRECTIONS',
                      icon: Icons.directions_rounded,
                      isPrimary: true,
                      primaryColor: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF6E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withOpacity(0.32),
                width: 1.2,
              ),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: _inkSoft,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Launchers ────────────────────────────
  Future<void> _launchPhone(String phone) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9]'), '')}');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          _brandSnack('Couldn\'t open the dialer.'),
        );
      }
    }
  }

  Future<void> _launchDirections() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // geo: URI opens the Maps app directly on Android; falls back to any
    // app that handles map intents (browser, Waze, etc.)
    final geoUri = Uri.parse('geo:0,0?q=emergency+vet+near+me');
    final webUri =
        Uri.parse('https://www.google.com/maps/search/emergency+vet+near+me');
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          _brandSnack('Couldn\'t open Maps.'),
        );
      }
    }
  }

  SnackBar _brandSnack(String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _ink,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.1,
        ),
      ),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
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
            color: PawfectColors.pawfectOrange.withValues(alpha: 0.35),
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
            color: PawfectColors.pawfectOrange.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Sheet action tile ─────────────────────
class _SheetActionTile extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool isPrimary;
  final Color? primaryColor;

  const _SheetActionTile({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.primaryColor,
  });

  @override
  State<_SheetActionTile> createState() => _SheetActionTileState();
}

class _SheetActionTileState extends State<_SheetActionTile> {
  bool _pressed = false;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _emergency = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    final primary = widget.primaryColor ?? _emergency;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF6E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.88),
                    width: 1.2,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isPrimary ? Colors.white : _ink,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: isPrimary ? Colors.white : _ink,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VetClinic {
  final String name;
  final String address;
  final String phone;
  final bool isOpen24Hours;
  final double distance;

  VetClinic({
    required this.name,
    required this.address,
    required this.phone,
    required this.isOpen24Hours,
    required this.distance,
  });
}
