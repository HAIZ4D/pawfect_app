import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/diagnosis_model.dart';
import '../../../models/pet_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_background.dart';
import '../repositories/illness_detector_repository.dart';
import '../widgets/ai_scan_reveal.dart';

/// Premium results screen for AI Illness Detector
class IllnessResultScreen extends StatefulWidget {
  final DiagnosisModel diagnosis;
  final File? capturedImage;
  final PetModel? pet;

  const IllnessResultScreen({
    super.key,
    required this.diagnosis,
    this.capturedImage,
    this.pet,
  });

  @override
  State<IllnessResultScreen> createState() => _IllnessResultScreenState();
}

class _IllnessResultScreenState extends State<IllnessResultScreen>
    with TickerProviderStateMixin {
  final IllnessDetectorRepository _repository = IllnessDetectorRepository();
  late PageController _pageController;
  late AnimationController _contentReveal;
  bool _isSaving = false;
  bool _isSaved = false;
  bool _showScanReveal = false;
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
    _CareTab('Vet Prep', Icons.medical_information_rounded, Color(0xFF7AC4FF)),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _contentReveal = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );
    _showScanReveal = widget.capturedImage != null;
    if (!_showScanReveal) {
      _contentReveal.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentReveal.dispose();
    super.dispose();
  }

  void _onScanRevealComplete() {
    if (!mounted) return;
    setState(() => _showScanReveal = false);
    _contentReveal.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      body: Stack(
        children: [
          const LiquidBackground(),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _contentReveal,
              curve: Curves.easeOutCubic,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        children: [
                          if (widget.capturedImage != null) ...[
                            const SizedBox(height: 4),
                            _buildHeroImage(),
                          ],
                          const SizedBox(height: 16),
                          _buildConditionCard(),
                          const SizedBox(height: 18),
                          _buildActionTimeline(),
                          const SizedBox(height: 22),
                          _buildTabSelector(),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 460,
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (i) =>
                                  setState(() => _currentPage = i),
                              children: [
                                _buildExplanationCard(),
                                _buildFirstAidCard(),
                                _buildRecommendationsCard(),
                                _buildTreatmentOptionsCard(),
                                _buildPreventionCard(),
                                _buildVetPrepCard(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPageDots(),
                          const SizedBox(height: 20),
                          _buildDisclaimer(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _contentReveal,
              curve: Curves.easeOutCubic,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildStickyActions(),
            ),
          ),
          if (_showScanReveal && widget.capturedImage != null)
            AIScanReveal(
              image: widget.capturedImage!,
              diagnosis: widget.diagnosis,
              onComplete: _onScanRevealComplete,
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
          const Expanded(
            child: Column(
              children: [
                Text(
                  'DIAGNOSIS RESULTS',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _inkSoft,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'AI Assessment Complete',
                  style: TextStyle(
                    fontSize: 13,
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
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
    if (widget.capturedImage == null) return const SizedBox.shrink();

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
            Image.file(widget.capturedImage!, fit: BoxFit.cover),
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
                      'SCAN IMAGE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: 1,
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
                    border: Border.all(color: urgencyColor.withOpacity(0.25)),
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
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
              Container(height: 8, color: const Color(0xFFF1EEE8)),
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
                  border: Border.all(color: isActive ? _ink : _hairline),
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
      case 5:
        return 'Vet Visit Prep';
      default:
        return '';
    }
  }

  // ─────────────────────────── Action timeline ───────────────────────────
  Widget _buildActionTimeline() {
    final urgencyColor = _getUrgencyColor();
    final steps = _timelineStepsFor(widget.diagnosis.urgencyLevel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        radius: 24,
        blur: 18,
        tintOpacity: 0.52,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'YOUR ACTION TIMELINE',
                style: TextStyle(
                  fontSize: 10.5,
                  color: _inkSoft,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bolt_rounded,
                size: 14,
                color: urgencyColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final connectorActive = i < 2;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 13),
                    height: 2,
                    decoration: BoxDecoration(
                      color: connectorActive
                          ? urgencyColor.withOpacity(0.5)
                          : _hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final step = steps[stepIndex];
              final isFirst = stepIndex == 0;
              return _timelineStep(step, urgencyColor, isFirst);
            }),
          ),
        ],
      ),
      ),
    );
  }

  Widget _timelineStep(_TimelineStep step, Color urgencyColor, bool active) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? urgencyColor : Colors.white,
              border: Border.all(
                color: active ? urgencyColor : _hairline,
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: urgencyColor.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              step.icon,
              size: 14,
              color: active ? Colors.white : _inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.when,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            step.action,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: _inkSoft,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  List<_TimelineStep> _timelineStepsFor(String urgency) {
    switch (urgency) {
      case 'EMERGENCY':
        return const [
          _TimelineStep('NOW', 'Emergency vet', Icons.emergency_rounded),
          _TimelineStep('24H', 'Treatment', Icons.medical_services_rounded),
          _TimelineStep('3 DAYS', 'Recovery', Icons.healing_rounded),
          _TimelineStep('1 WEEK', 'Follow-up', Icons.event_available_rounded),
        ];
      case 'HIGH':
        return const [
          _TimelineStep('NOW', 'Call vet', Icons.call_rounded),
          _TimelineStep('24H', 'Vet visit', Icons.medical_services_rounded),
          _TimelineStep('3 DAYS', 'Begin care', Icons.healing_rounded),
          _TimelineStep('1 WEEK', 'Re-check', Icons.event_available_rounded),
        ];
      case 'MODERATE':
        return const [
          _TimelineStep('NOW', 'Document signs', Icons.notes_rounded),
          _TimelineStep('24H', 'Book vet', Icons.event_rounded),
          _TimelineStep('3 DAYS', 'Vet visit', Icons.medical_services_rounded),
          _TimelineStep('1 WEEK', 'Follow plan', Icons.task_alt_rounded),
        ];
      case 'LOW':
      default:
        return const [
          _TimelineStep('NOW', 'Monitor', Icons.visibility_rounded),
          _TimelineStep('24H', 'Note changes', Icons.edit_note_rounded),
          _TimelineStep('3 DAYS', 'Re-assess', Icons.refresh_rounded),
          _TimelineStep(
            '1 WEEK',
            'Routine vet',
            Icons.event_available_rounded,
          ),
        ];
    }
  }

  // ─────────────────────────── Vet prep card ───────────────────────────
  Widget _buildVetPrepCard() {
    final petName = widget.pet?.name ?? 'your pet';
    final condition = _cleanText(widget.diagnosis.condition);
    final questions = _vetQuestionsFor(condition, petName);
    final checklist = _vetChecklistItems();

    return _buildInfoCard(
      tabIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _vetSectionHeader(
            'QUESTIONS TO ASK',
            Icons.question_answer_rounded,
          ),
          const SizedBox(height: 12),
          ...questions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _tabs[5].accent,
                          _tabs[5].accent.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        'Q${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 14),
          _vetSectionHeader('BRING WITH YOU', Icons.checklist_rounded),
          const SizedBox(height: 10),
          ...checklist.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _tabs[5].accent.withOpacity(0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: _tabs[5].accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
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

  Widget _vetSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _tabs[5].accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  List<String> _vetQuestionsFor(String condition, String petName) {
    return [
      'What is causing $petName\'s $condition, and how confident are you in the diagnosis?',
      'What treatment plan do you recommend, and what are the alternatives?',
      'What side effects or warning signs should I watch for at home?',
      'How long until I should see improvement, and what does recovery look like?',
      'When should we schedule a follow-up, and what should trigger an earlier visit?',
    ];
  }

  List<String> _vetChecklistItems() {
    return [
      'This AI diagnosis report (open the PawBook entry on your phone)',
      'Photos or a short video showing the symptoms over time',
      'A list of current foods, treats, and any new products in the home',
      'Vaccination records and any past medical history',
      'Notes on when symptoms started and how they\'ve progressed',
      'A list of all current medications and supplements',
    ];
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

  // ─────────────────────────── Sticky action bar ───────────────────────────
  Widget _buildStickyActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _saveButton(),
          ),
          const SizedBox(width: 10),
          _vetButton(),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaved || _isSaving ? null : _saveToPawBook,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          decoration: BoxDecoration(
            gradient: _isSaved
                ? const LinearGradient(
                    colors: [Color(0xFF2E8A68), Color(0xFF3EA97D)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PawfectColors.pawfectOrange,
                      Color(0xFFFFB847),
                    ],
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (_isSaved
                        ? const Color(0xFF2E8A68)
                        : PawfectColors.pawfectOrange)
                    .withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  _isSaved
                      ? Icons.check_circle_rounded
                      : Icons.bookmark_add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Text(
                _isSaving
                    ? 'Saving...'
                    : _isSaved
                        ? 'Saved to PawBook'
                        : 'Save to PawBook',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vetButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _findNearbyVet,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 22,
          ),
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
        .replaceAll('__', '')
        .replaceAll('_', '')
        .replaceAll('~~', '')
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

  Future<void> _saveToPawBook() async {
    setState(() => _isSaving = true);

    try {
      String? diagnosisId;

      if (widget.capturedImage != null) {
        diagnosisId = await _repository.saveDiagnosisWithImage(
          widget.diagnosis,
          widget.capturedImage!,
        );
      } else {
        diagnosisId = await _repository.saveDiagnosis(widget.diagnosis);
      }

      if (diagnosisId != null && mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to PawBook successfully'),
            backgroundColor: Color(0xFF2E8A68),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  void _findNearbyVet() {
    Navigator.pushNamed(context, '/vet-finder');
  }
}

class _CareTab {
  final String label;
  final IconData icon;
  final Color accent;

  const _CareTab(this.label, this.icon, this.accent);
}

class _TimelineStep {
  final String when;
  final String action;
  final IconData icon;

  const _TimelineStep(this.when, this.action, this.icon);
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
