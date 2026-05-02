import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/diagnosis_model.dart';
import '../../../models/pet_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_background.dart';

/// Screen to view saved diagnosis details from PawBook
class DiagnosisDetailScreen extends StatefulWidget {
  final DiagnosisModel diagnosis;
  final PetModel? pet;

  const DiagnosisDetailScreen({
    super.key,
    required this.diagnosis,
    this.pet,
  });

  @override
  State<DiagnosisDetailScreen> createState() => _DiagnosisDetailScreenState();
}

class _DiagnosisDetailScreenState extends State<DiagnosisDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _peach = Color(0xFFFFEAD5);

  static const List<_CareTab> _tabs = [
    _CareTab('Overview', Icons.psychology_rounded, Color(0xFFFFB74D)),
    _CareTab('First Aid', Icons.medical_services_rounded, Color(0xFFE5719A)),
    _CareTab('Actions', Icons.checklist_rounded, Color(0xFF6B9DFF)),
    _CareTab('Treatment', Icons.medication_rounded, Color(0xFFFDA002)),
    _CareTab('Prevention', Icons.shield_rounded, Color(0xFF5FB88A)),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (widget.diagnosis.imageBase64 != null) ...[
                          const SizedBox(height: 8),
                          _buildHeroImage(),
                        ],
                        const SizedBox(height: 16),
                        _buildConditionCard(),
                        const SizedBox(height: 22),
                        _buildTabSelector(),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 460,
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            children: [
                              _buildExplanationCard(),
                              _buildFirstAidCard(),
                              _buildRecommendationsCard(),
                              _buildTreatmentOptionsCard(),
                              _buildPreventionCard(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPageDots(),
                        const SizedBox(height: 20),
                        _buildDisclaimer(),
                        const SizedBox(height: 24),
                      ],
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

  // ─────────────────────────── Header ───────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Case File',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _inkSoft,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a')
                      .format(widget.diagnosis.timestamp),
                  style: const TextStyle(
                    fontSize: 13,
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          _iconButton(
            icon: Icons.ios_share_rounded,
            onTap: _shareResults,
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.7),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: _ink),
      ),
    );
  }

  // ─────────────────────────── Hero image ───────────────────────────
  Widget _buildHeroImage() {
    if (widget.diagnosis.imageBase64 == null) return const SizedBox.shrink();

    try {
      final imageBytes = base64Decode(widget.diagnosis.imageBase64!);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(imageBytes, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _ink.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 12,
                        color: _ink,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'CAPTURED EVIDENCE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.pet != null)
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 14,
                          color: PawfectColors.pawfectOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.pet!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  // ─────────────────────────── Condition card ───────────────────────────
  Widget _buildConditionCard() {
    final urgencyColor = _getUrgencyColor();
    final confidence = widget.diagnosis.confidence.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        radius: 26,
        blur: 20,
        tintOpacity: 0.55,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: urgencyColor.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.diagnosis.urgencyEmoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.diagnosis.urgencyLabel,
                          style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.diagnosis.confidencePercentage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _cleanText(widget.diagnosis.condition),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildConfidenceMeter(confidence, urgencyColor),
          if (widget.diagnosis.symptoms.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    color: PawfectColors.pawfectOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'REPORTED SYMPTOMS',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _inkSoft,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.diagnosis.symptoms.take(6).map((symptom) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _peach,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _cleanText(symptom),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8A4A14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (widget.diagnosis.symptoms.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${widget.diagnosis.symptoms.length - 6} additional signs',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _inkSoft,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildConfidenceMeter(double value, Color urgencyColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI CONFIDENCE',
              style: TextStyle(
                fontSize: 10.5,
                color: _inkSoft,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              widget.diagnosis.confidencePercentage,
              style: TextStyle(
                fontSize: 12,
                color: urgencyColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: const Color(0xFFF1EEE8),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        urgencyColor.withOpacity(0.6),
                        urgencyColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Tab selector ───────────────────────────
  Widget _buildTabSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isActive = _currentPage == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index < _tabs.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? _ink : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isActive ? _ink : _hairline,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _ink.withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isActive ? tab.accent : _inkSoft,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : _ink,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tabs.length, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? PawfectColors.pawfectOrange : _hairline,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ─────────────────────────── Page cards ───────────────────────────
  Widget _buildExplanationCard() {
    return _buildInfoCard(
      tabIndex: 0,
      content: _cleanText(widget.diagnosis.explanation),
    );
  }

  Widget _buildFirstAidCard() {
    final steps = _extractSteps(
      _cleanText(widget.diagnosis.firstAidInstructions),
    );

    return _buildInfoCard(
      tabIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _tabs[1].accent,
                        _tabs[1].accent.withOpacity(0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return _buildInfoCard(
      tabIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.diagnosis.recommendations.map((rec) {
          return _bulletRow(
            accent: _tabs[2].accent,
            icon: Icons.check_rounded,
            text: _cleanText(rec),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTreatmentOptionsCard() {
    final treatments = widget.diagnosis.treatments.isNotEmpty
        ? widget.diagnosis.treatments
        : [
            'Consult with a veterinarian for proper diagnosis',
            'Follow prescribed medication schedules',
            'Provide supportive care at home',
            'Monitor for improvement or worsening symptoms',
            'Follow up with vet as recommended',
          ];

    return _buildInfoCard(
      tabIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: treatments.map((treatment) {
          return _bulletRow(
            accent: _tabs[3].accent,
            icon: Icons.local_hospital_rounded,
            text: _cleanText(treatment),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreventionCard() {
    const preventionTips = [
      'Regular health check-ups with your veterinarian',
      'Maintain a balanced diet and proper nutrition',
      'Keep your pet\'s environment clean and safe',
      'Stay up to date with vaccinations',
      'Monitor your pet\'s behavior and appetite daily',
      'Provide regular exercise and mental stimulation',
    ];

    return _buildInfoCard(
      tabIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: preventionTips.map((tip) {
          return _bulletRow(
            accent: _tabs[4].accent,
            icon: Icons.shield_rounded,
            text: tip,
          );
        }).toList(),
      ),
    );
  }

  Widget _bulletRow({
    required Color accent,
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required int tabIndex,
    String? content,
    Widget? child,
  }) {
    final tab = _tabs[tabIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ink, _inkDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle accent glow (top-right)
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tab.accent.withOpacity(0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tab.accent,
                            tab.accent.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: tab.accent.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(tab.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tabIndex + 1}/${_tabs.length} • ${tab.label.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pageTitleFor(tabIndex),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
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
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const _NoGlow(),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: content != null
                          ? Text(
                              content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.65,
                                letterSpacing: 0.1,
                              ),
                            )
                          : child ?? const SizedBox.shrink(),
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

  String _pageTitleFor(int index) {
    switch (index) {
      case 0:
        return 'What This Means';
      case 1:
        return 'First Aid Steps';
      case 2:
        return 'Action Plan';
      case 3:
        return 'Treatment Options';
      case 4:
        return 'Prevention Tips';
      default:
        return '';
    }
  }

  // ─────────────────────────── Disclaimer ───────────────────────────
  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        radius: 18,
        blur: 12,
        tintOpacity: 0.45,
        elevated: false,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _peach.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFFE07B2A),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'AI guidance — always confirm with a licensed veterinarian before acting.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: _inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Helpers ───────────────────────────
  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .trim();
  }

  List<String> _extractSteps(String text) {
    final lines = text.split('\n');
    final steps = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final cleaned = trimmed
          .replaceFirst(RegExp(r'^\d+\.\s*'), '')
          .replaceFirst(RegExp(r'^[-*•]\s*'), '');

      if (cleaned.isNotEmpty) {
        steps.add(cleaned);
      }
    }

    if (steps.isEmpty) {
      final sentences = text.split('. ');
      return sentences.where((s) => s.trim().isNotEmpty).take(6).toList();
    }

    return steps.take(6).toList();
  }

  Color _getUrgencyColor() {
    switch (widget.diagnosis.urgencyLevel) {
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

  void _shareResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CareTab {
  final String label;
  final IconData icon;
  final Color accent;

  const _CareTab(this.label, this.icon, this.accent);
}

class _NoGlow extends ScrollBehavior {
  const _NoGlow();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
