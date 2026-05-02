import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/toxic_substance_model.dart';
import '../data/toxic_substances_database.dart';
import 'report_poisoning_incident_screen.dart';
import '../../poisoning_detection/screens/vet_finder_screen.dart';

/// Poison alert — emergency directory of toxic substances.
///
/// Editorial structure: red emergency hero (the only red surface),
/// followed by a calm white reading list of substances. The page
/// stays composed even when the topic is urgent.
class PoisoningDetectionScreen extends StatefulWidget {
  const PoisoningDetectionScreen({super.key});

  @override
  State<PoisoningDetectionScreen> createState() =>
      _PoisoningDetectionScreenState();
}

class _PoisoningDetectionScreenState extends State<PoisoningDetectionScreen> {
  // ─── State preserved verbatim ────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // ─── Palette ─────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _emergency = Color(0xFFD32F2F);

  List<ToxicSubstanceModel> get _filteredSubstances {
    List<ToxicSubstanceModel> substances;

    if (_selectedCategory == 'All') {
      substances = ToxicSubstancesDatabase.getAllSubstances();
    } else {
      substances =
          ToxicSubstancesDatabase.getSubstancesByCategory(_selectedCategory);
    }

    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      substances = substances.where((substance) {
        return substance.name.toLowerCase().contains(queryLower) ||
            substance.keywords
                .any((keyword) => keyword.toLowerCase().contains(queryLower)) ||
            substance.alternativeNames
                .any((name) => name.toLowerCase().contains(queryLower));
      }).toList();
    }

    return substances;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final substances = _filteredSubstances;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Poison Alert',
        subtitle: 'Tap a substance to report',
        icon: Icons.shield_rounded,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.45),
          Positioned.fill(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
              children: [
                _buildEmergencyHero(),
                const SizedBox(height: 22),
                const _Ornament(),
                const SizedBox(height: 20),
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildCategoryFilter(),
                const SizedBox(height: 22),
                _buildResultsEyebrow(substances.length),
                const SizedBox(height: 12),
                if (substances.isEmpty)
                  _buildEmptyState()
                else
                  ...substances.map(_buildSubstanceCard),
                const SizedBox(height: 28),
                _buildDisclaimer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Emergency hero ───────────────────────
  Widget _buildEmergencyHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [_emergency, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _emergency.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Ghost numeral on the right — editorial signature
            Positioned(
              top: -22,
              right: -12,
              child: Text(
                '!',
                style: TextStyle(
                  fontSize: 184,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.08),
                  height: 1.0,
                  letterSpacing: -8,
                ),
              ),
            ),
            // Decorative shield watermark
            Positioned(
              bottom: -16,
              right: 12,
              child: Transform.rotate(
                angle: -0.32,
                child: Icon(
                  Icons.shield_rounded,
                  size: 96,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EMERGENCY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 28,
                        height: 1,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TRIAGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.78),
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Suspect\npoisoning?',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search what they ate. Then act fast.',
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.92),
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Vet finder CTA — white, caps, rule + arrow
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VetFinderScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: _emergency,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'FIND NEAREST VET',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: _emergency,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 22,
                            height: 1,
                            color: _emergency,
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: _emergency,
                          ),
                        ],
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

  // ─────────────────────────── Search field ─────────────────────────
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        style: const TextStyle(
          fontSize: 14,
          color: _ink,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search chocolate, lily, paracetamol…',
          hintStyle: TextStyle(
            fontSize: 13.5,
            color: _inkSoft.withOpacity(0.85),
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.search_rounded,
              color: _ink.withOpacity(0.7),
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _inkSoft,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─────────────────────────── Category filter ──────────────────────
  Widget _buildCategoryFilter() {
    final categories = ['All', ...ToxicSubstancesDatabase.getAllCategories()];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_ink, _inkDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _ink
                      : Colors.white.withOpacity(0.85),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _ink.withOpacity(0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : _ink,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────── Results eyebrow ──────────────────────
  Widget _buildResultsEyebrow(int count) {
    return Row(
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
          'TOXIC SUBSTANCES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        Text(
          '${count.toString().padLeft(2, "0")} ${count == 1 ? "MATCH" : "MATCHES"}',
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

  // ─────────────────────────── Substance card ───────────────────────
  Widget _buildSubstanceCard(ToxicSubstanceModel substance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportPoisoningIncidentScreen(
                  substance: substance,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Red icon orb — restrained, hairline-bordered
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _emergency.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _emergency.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: _emergency,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        substance.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        substance.category,
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
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _emergency,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Empty state ──────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _emergency.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _emergency.withOpacity(0.32),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 24,
              color: _emergency,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No matches.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different keyword or category.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _inkSoft.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Disclaimer ──────────────────────────
  Widget _buildDisclaimer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 1,
              color: _hairline,
            ),
            const SizedBox(height: 12),
            Text(
              'In any emergency, call your vet immediately.\nThis guide is informational only.',
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
