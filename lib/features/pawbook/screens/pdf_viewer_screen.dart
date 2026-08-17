import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';

/// PDF Report Ready — editorial confirmation screen.
///
/// Renders after the poisoning incident PDF is written to local
/// storage. Shows a magazine-style hero with the report subject, a
/// quiet path detail card, primary Share / Done actions, and a soft
/// PawBook footer reminding the owner where the incident is archived.
class PdfViewerScreen extends StatefulWidget {
  final String pdfBase64;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfBase64,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // ─── State preserved verbatim ────────────────────────────────────
  File? _pdfFile;
  bool _isLoading = true;
  String? _error;

  // ─── Palette ─────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _emergency = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfFile?.delete().catchError((_) => File(''));
    super.dispose();
  }

  // ─────────────────────────── Logic ────────────────────────────────
  Future<void> _loadPdf() async {
    try {
      final bytes = base64Decode(widget.pdfBase64);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() {
        _pdfFile = file;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfFile == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      HapticFeedback.lightImpact();
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        subject: widget.title,
        text: 'Poisoning Incident Report',
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        _brandSnack('Couldn\'t open the share sheet.', isError: true),
      );
    }
  }

  // ─────────────────────────── Helpers ──────────────────────────────
  SnackBar _brandSnack(String message, {bool isError = false}) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? _emergency : _ink,
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

  String _shortenPath(String path) {
    if (path.length <= 56) return path;
    final segments = path.split(RegExp(r'[/\\]'));
    if (segments.length < 3) return path;
    return '…/${segments[segments.length - 2]}/${segments.last}';
  }

  // ─────────────────────────── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Report Ready',
        subtitle: 'PDF saved to PawBook',
        icon: Icons.picture_as_pdf_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.45),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else
            _buildSuccessState(),
        ],
      ),
    );
  }

  // ─────────────────────────── Loading ──────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(
                PawfectColors.pawfectOrange,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Preparing your report',
            style: TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _inkSoft.withOpacity(0.92),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Error ────────────────────────────────
  Widget _buildErrorState() {
    final topInset = MediaQuery.of(context).padding.top;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    'COULDN\'T OPEN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Report failed to load.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.6,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The file may have been moved or your storage is full. Try generating it again.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft.withOpacity(0.95),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Success ──────────────────────────────
  Widget _buildSuccessState() {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        // Warm radial halo behind the hero
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
            padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHero(),
                const SizedBox(height: 22),
                _buildPathCard(),
                const SizedBox(height: 22),
                const _Ornament(),
                const SizedBox(height: 22),
                _buildActions(),
                const SizedBox(height: 28),
                _buildPawBookCard(),
                const SizedBox(height: 28),
                _buildSignatureFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Hero ─────────────────────────────────
  Widget _buildReportHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: _cardDecoration(radius: 26),
      child: Stack(
        children: [
          // Ghost glyph — paper sheet
          Positioned(
            top: -22,
            right: -16,
            child: Text(
              'PDF',
              style: TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w900,
                color: PawfectColors.pawfectOrange.withOpacity(0.06),
                height: 1.0,
                letterSpacing: -4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Column(
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
                    'REPORT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 22, height: 1, color: _hairline),
                  const SizedBox(width: 12),
                  const Text(
                    'READY',
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: PawfectColors.pawfectOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PawfectColors.pawfectOrange.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: PawfectColors.pawfectOrange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report ready.',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vet-ready, shareable, archived.',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                            color:
                                PawfectColors.pawfectOrange.withOpacity(0.92),
                            letterSpacing: -0.2,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.title.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: _hairline),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'SUBJECT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: _inkSoft,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 18, height: 1, color: _hairline),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Path card ────────────────────────────
  Widget _buildPathCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PawfectColors.pawfectOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PawfectColors.pawfectOrange.withOpacity(0.32),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.folder_outlined,
              size: 18,
              color: PawfectColors.pawfectOrange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAVED LOCALLY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: _inkSoft,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _pdfFile != null
                      ? _shortenPath(_pdfFile!.path)
                      : 'Generating',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Actions ──────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            label: 'DONE',
            icon: Icons.check_rounded,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _ActionTile(
            onTap: _sharePdf,
            label: 'SHARE PDF',
            icon: Icons.ios_share_rounded,
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── PawBook card ─────────────────────────
  Widget _buildPawBookCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAEE), Color(0xFFFFF1D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.88),
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
              const SizedBox(width: 10),
              const Text(
                'PAWBOOK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 18, height: 1, color: _hairline),
              const SizedBox(width: 12),
              const Text(
                'ARCHIVED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This incident is logged in your pet\'s medical history. Open PawBook to review it any time.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _ink.withOpacity(0.92),
              height: 1.55,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Signature footer ─────────────────────
  Widget _buildSignatureFooter() {
    return Center(
      child: Column(
        children: [
          Container(width: 36, height: 1, color: _hairline),
          const SizedBox(height: 12),
          Text(
            'Care, not diagnosis. Share with a licensed vet for treatment.',
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

  BoxDecoration _cardDecoration({double radius = 22}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFFFF6E2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.88),
        width: 1.2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
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

// ─────────────────────────── Action tile ───────────────────────────
class _ActionTile extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool isPrimary;

  const _ActionTile({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.isPrimary,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  static const Color _ink = Color(0xFF2D3142);

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [
                      PawfectColors.pawfectOrange,
                      Color(0xFFFFB347),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF6E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: isPrimary
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.88),
                    width: 1.2,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: PawfectColors.pawfectOrange.withOpacity(0.36),
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
