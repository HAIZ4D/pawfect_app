import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/pet_model.dart';
import '../providers/pet_provider.dart';
import 'add_pet_screen.dart';
import 'pet_profile_screen.dart';

/// PawBook home — editorial archive of the pack.
///
/// Layout intent (top to bottom):
///   1. Editorial header: rule + display headline + italic accent
///   2. Ornament rule
///   3. Search field (white surface, italic placeholder)
///   4. Section eyebrow with pet count
///   5. Magazine-cover pet cards (tall, full-bleed photos)
///   6. Add-companion editorial card at the end of the list
///   7. Or, when empty: a quiet editorial card inviting the first pet
///
/// Strict palette: cream / white / orange / ink. State and provider
/// wiring (search, load, navigation) preserved verbatim.
class PawbookHomeScreen extends StatefulWidget {
  const PawbookHomeScreen({super.key});

  @override
  State<PawbookHomeScreen> createState() => _PawbookHomeScreenState();
}

class _PawbookHomeScreenState extends State<PawbookHomeScreen> {
  // ─── State preserved verbatim ────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ─── Palette ─────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPets());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    await context.read<PetProvider>().loadPets();
  }

  Future<void> _handleSearch(String query) async {
    setState(() => _searchQuery = query);
    await context.read<PetProvider>().searchPets(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    context.read<PetProvider>().searchPets('');
  }

  void _navigateToAddPet() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
    if (result == true) _loadPets();
  }

  void _navigateToPetProfile(PetModel pet) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)),
    );
    if (result == true) _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'PawBook',
        subtitle: 'Your pets, beautifully remembered',
        icon: Icons.menu_book_rounded,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.55),
          // Atmospheric peach halo near the top — same warmth as the
          // home screens.
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
            child: Consumer<PetProvider>(
              builder: (_, provider, __) {
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    topInset + 132,
                    24,
                    130,
                  ),
                  children: [
                    _buildEditorialHeader(provider),
                    const SizedBox(height: 26),
                    const _Ornament(),
                    const SizedBox(height: 22),
                    _buildSearchField(),
                    const SizedBox(height: 28),
                    if (provider.isLoading && provider.pets.isEmpty)
                      _buildLoading()
                    else if (!provider.hasPets && _searchQuery.isEmpty)
                      _buildEmptyState()
                    else if (!provider.hasPets && _searchQuery.isNotEmpty)
                      _buildNoMatches()
                    else ...[
                      _buildResultsEyebrow(provider),
                      const SizedBox(height: 16),
                      for (var i = 0; i < provider.pets.length; i++) ...[
                        _buildMagazinePetCard(
                          provider.pets[i],
                          i + 1,
                          provider.pets.length,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildAddCompanionCard(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Editorial header ─────────────────────
  Widget _buildEditorialHeader(PetProvider provider) {
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
              'PAWBOOK',
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
              'ARCHIVE',
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
          'Their stories.',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'All under one roof.',
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
        Text(
          'Photos, vaccinations, scans — kept together so a vet anywhere can pick up where you left off.',
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
        onChanged: _handleSearch,
        style: const TextStyle(
          fontSize: 14,
          color: _ink,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or breed…',
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
                  onPressed: _clearSearch,
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

  // ─────────────────────────── Results eyebrow ──────────────────────
  Widget _buildResultsEyebrow(PetProvider provider) {
    final count = provider.pets.length;
    final label = _searchQuery.isNotEmpty ? 'MATCHES' : 'YOUR PACK';
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
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        Text(
          '${count.toString().padLeft(2, "0")} ${count == 1 ? "PET" : "PETS"}',
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

  // ─────────────────────────── Magazine pet card ────────────────────
  Widget _buildMagazinePetCard(PetModel pet, int index, int total) {
    return GestureDetector(
      onTap: () => _navigateToPetProfile(pet),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.26),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: PawfectColors.pawfectOrange.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo — full bleed
              if (pet.imageBase64 != null)
                pet.getDecodedImage()
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        PawfectColors.pawfectOrange,
                        Color(0xFFFFB347),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.pets_rounded,
                      size: 100,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ),

              // Long bottom gradient — soft and intentional
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                      Colors.black.withOpacity(0.78),
                    ],
                    stops: const [0.42, 0.66, 1.0],
                  ),
                ),
              ),

              // Hairline white border (premium framing)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.32),
                    width: 1.2,
                  ),
                ),
              ),

              // Top-right pagination annotation
              if (total > 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${index.toString().padLeft(2, "0")} / ${total.toString().padLeft(2, "0")}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),

              // Bottom-left editorial overlay
              Positioned(
                left: 22,
                right: 22,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pet.species.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.72),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pet.name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.breed} · ${pet.gender} · ${pet.getAge()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Add companion card ───────────────────
  Widget _buildAddCompanionCard() {
    return GestureDetector(
      onTap: _navigateToAddPet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF6E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: PawfectColors.pawfectOrange.withOpacity(0.4),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: PawfectColors.pawfectOrange.withOpacity(0.16),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Soft paw watermark
              Positioned(
                bottom: -14,
                right: -8,
                child: Transform.rotate(
                  angle: -0.32,
                  child: Icon(
                    Icons.pets_rounded,
                    size: 92,
                    color: PawfectColors.pawfectOrange.withOpacity(0.1),
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
                        height: 12,
                        decoration: BoxDecoration(
                          color: PawfectColors.pawfectOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'GROW THE PACK',
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
                    'Add a companion.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personalised AI care for every pet you keep.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: _inkSoft.withOpacity(0.92),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'ADD A PET',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: PawfectColors.pawfectOrange,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 22,
                        height: 1,
                        color: PawfectColors.pawfectOrange,
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: PawfectColors.pawfectOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Empty state ──────────────────────────
  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _navigateToAddPet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF6E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 24,
              offset: Offset(0, 12),
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
                  'BEGIN HERE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'No pets yet.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start their story.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: PawfectColors.pawfectOrange,
                letterSpacing: -0.4,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A photo, a name, a breed. Everything else fills in over time.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: _inkSoft.withOpacity(0.92),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Text(
                  'ADD A PET',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: PawfectColors.pawfectOrange,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 22,
                  height: 1,
                  color: PawfectColors.pawfectOrange,
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: PawfectColors.pawfectOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── No matches ──────────────────────────
  Widget _buildNoMatches() {
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
              color: PawfectColors.pawfectOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PawfectColors.pawfectOrange.withOpacity(0.32),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 24,
              color: PawfectColors.pawfectOrange,
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
            'Try a different name or breed.',
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

  // ─────────────────────────── Loading ─────────────────────────────
  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PawfectColors.pawfectOrange,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Fetching the pack…',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _inkSoft.withOpacity(0.85),
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
