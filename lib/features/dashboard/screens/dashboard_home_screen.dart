import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/colors.dart';
import '../../../models/pet_model.dart';
import '../../pawbook/providers/pet_provider.dart';
import '../../pawbook/screens/pet_profile_screen.dart';
import '../../pawbook/screens/add_pet_screen.dart';
import '../../detector/screens/illness_detector_camera_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/pet_care_tip_service.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen>
    with SingleTickerProviderStateMixin {
  final PetCareTipService _tipService = PetCareTipService();
  String _currentTip = 'Loading tip...';
  bool _isLoadingTip = true;
  int _selectedPetIndex = 0;

  // 0 = Overview, 1 = Medical, 2 = Activity
  int _profileTabIndex = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _initializeTipService();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeTipService() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isNotEmpty) await _tipService.initialize(apiKey);
      await _refreshTip();
    } catch (_) {
      setState(() {
        _currentTip =
            'Keep your pet happy with regular exercise and fresh water!';
        _isLoadingTip = false;
      });
    }
  }

  Future<void> _refreshTip() async {
    setState(() => _isLoadingTip = true);
    try {
      final petProvider = context.read<PetProvider>();
      String tip;
      if (petProvider.hasPets && _selectedPetIndex < petProvider.pets.length) {
        tip = await _tipService.generatePetCareTip(
          petProvider.pets[_selectedPetIndex],
        );
      } else {
        tip = await _tipService.generateGeneralTip();
      }
      if (mounted) {
        setState(() {
          _currentTip = tip;
          _isLoadingTip = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentTip = 'Fresh water and regular exercise keep your pet happy!';
          _isLoadingTip = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Microchip ID copied!'),
        backgroundColor: PawfectColors.pawfectOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await petProvider.loadPets();
            await _refreshTip();
          },
          color: PawfectColors.pawfectOrange,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Dark header (same colour as original) ──
              SliverToBoxAdapter(child: _buildHeader(petProvider)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    // ── Orange AI tip card (original style) ──
                    _buildAITipCard(),
                    const SizedBox(height: 24),
                    // ── Original 2-card quick actions ──
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    // ── Pet selector row with Add Pet ──
                    _buildPetSelector(context, petProvider),
                    const SizedBox(height: 20),
                    // ── Pet profile card with tabs ──
                    if (petProvider.hasPets) _buildPetProfileCard(petProvider),
                    const SizedBox(height: 28),
                    // ── Health check card ──
                    _buildHealthCheckCard(context),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER — original dark gradient + Good Morning greeting
  // Owner name is hardcoded (to connect to database later when displayName is stored)
  // To connect to auth in future:
  //   final authProvider = context.watch<AuthProvider>();
  //   final ownerName = authProvider.userDisplayName ?? 'Pet Owner';
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(PetProvider petProvider) {
    // Hardcoded owner name for now
    const String ownerName = 'Yasmin';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Owner avatar with orange border ring
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PawfectColors.pawfectOrange,
                width: 2.5,
              ),
              color: const Color(0xFF3D4157),
            ),
            child: const ClipOval(
              // TODO: swap Icon for real user photo:
              // child: Image.network(user.photoUrl!, fit: BoxFit.cover)
              child: Icon(Icons.person, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  ownerName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  petProvider.hasPets
                      ? 'Track your pet\'s health & wellness'
                      : 'Welcome to Pawfect!',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: () {}, // TODO: navigate to notifications
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: PawfectColors.pawfectOrange,
                      shape: BoxShape.circle,
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

  // ══════════════════════════════════════════════════════════════════════════
  // AI TIP CARD — original orange gradient (unchanged)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAITipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDA002), Color(0xFFFFB847)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PawfectColors.pawfectOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pet Care Tip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isLoadingTip ? null : _refreshTip,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      _isLoadingTip
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentTip,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'Powered by Gemini AI',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS — original 2-card row (unchanged)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PawfectColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.medical_services_rounded,
                label: 'Health Check',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IllnessDetectorCameraScreen(),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.pets_rounded,
                label: 'My Pets',
                onTap: () {
                  // TODO: Navigate to pawbook tab
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PET SELECTOR ROW — circular avatars + Add Pet button
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPetSelector(BuildContext context, PetProvider petProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Pets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: PawfectColors.textPrimary,
              ),
            ),
            if (petProvider.hasPets)
              Text(
                '${petProvider.petsCount} '
                '${petProvider.petsCount == 1 ? 'pet' : 'pets'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: PawfectColors.textHint,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (!petProvider.hasPets)
          _buildNoPetsCard()
        else
          SizedBox(
            height: 98,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...List.generate(petProvider.pets.length, (index) {
                  final pet = petProvider.pets[index];
                  final isSelected = index == _selectedPetIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildPetChip(context, pet, isSelected, index),
                  );
                }),
                _buildAddPetChip(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoPetsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PawfectColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PawfectColors.pawfectCream,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 40,
              color: PawfectColors.pawfectOrange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PawfectColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first pet to get started!',
            style: TextStyle(fontSize: 14, color: PawfectColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildPetChip(
    BuildContext context,
    PetModel pet,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPetIndex = index;
          _profileTabIndex = 0;
        });
        _refreshTip();
      },
      onDoubleTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)),
          ),
      child: Column(
        children: [
          // Golden sweep gradient ring when selected
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  isSelected
                      ? const SweepGradient(
                        colors: [
                          Color(0xFFFDA002),
                          Color(0xFFFFB847),
                          Color(0xFFFDA002),
                        ],
                      )
                      : null,
              color: isSelected ? null : const Color(0xFFE8DDD0),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child:
                    pet.imageBase64 != null
                        ? pet.getDecodedImage()
                        : Container(
                          color: const Color(0xFF2D3142),
                          child: Icon(
                            _getPetIcon(pet.species),
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pet.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color:
                  isSelected
                      ? PawfectColors.textPrimary
                      : PawfectColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPetChip() {
    return GestureDetector(
      onTap: () async {
        // Navigate to Add Pet screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPetScreen()),
        );

        // Refresh pets list if a pet was added
        if (result == true && mounted) {
          final petProvider = context.read<PetProvider>();
          await petProvider.loadPets();

          // Reset selected pet index if this is the first pet
          if (petProvider.pets.length == 1) {
            setState(() {
              _selectedPetIndex = 0;
            });
            await _refreshTip();
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDD5CA), width: 2),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: PawfectColors.textHint,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add Pet',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: PawfectColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PET PROFILE CARD — Overview / Medical / Activity tabs
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPetProfileCard(PetProvider petProvider) {
    if (_selectedPetIndex >= petProvider.pets.length) {
      _selectedPetIndex = 0;
    }
    final pet = petProvider.pets[_selectedPetIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${pet.name}\'s Profile',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: PawfectColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Active status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2ECC71),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'ACTIVE STATUS',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF27AE60),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PetProfileScreen(pet: pet),
                        ),
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: PawfectColors.pawfectOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                _buildTab('Overview', 0),
                const SizedBox(width: 22),
                _buildTab('Medical', 1),
                const SizedBox(width: 22),
                _buildTab('Activity', 2),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withOpacity(0.12),
          ),

          // ── Tab content ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildTabContent(pet),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int idx) {
    final active = _profileTabIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _profileTabIndex = idx),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color:
                  active ? PawfectColors.pawfectOrange : PawfectColors.textHint,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.5,
            width: active ? 28.0 : 0.0,
            decoration: BoxDecoration(
              color: PawfectColors.pawfectOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(PetModel pet) {
    switch (_profileTabIndex) {
      case 1:
        return _buildPlaceholderTab(
          Icons.medical_services_rounded,
          'Medical records coming soon',
        );
      case 2:
        return _buildPlaceholderTab(
          Icons.directions_run_rounded,
          'Activity tracking coming soon',
        );
      default:
        return _buildOverviewTab(pet);
    }
  }

  Widget _buildPlaceholderTab(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(
              icon,
              size: 38,
              color: PawfectColors.textHint.withOpacity(0.35),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: PawfectColors.textHint.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(PetModel pet) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile('Age', pet.getAge())),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatTile(
                'Weight',
                pet.weight != null ? '${pet.weight}kg' : 'N/A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatTile('Species', pet.species)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatTile('Color', pet.color ?? 'N/A')),
          ],
        ),
        if (pet.microchipId != null && pet.microchipId!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildMicrochipTile(pet.microchipId!),
        ],
      ],
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PawfectColors.pawfectCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: PawfectColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PawfectColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Microchip tile with copy-to-clipboard button
  Widget _buildMicrochipTile(String chipId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PawfectColors.pawfectCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Microchip ID',
                  style: TextStyle(
                    fontSize: 11,
                    color: PawfectColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#$chipId',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PawfectColors.textPrimary,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Copy button
          GestureDetector(
            onTap: () => _copyToClipboard(chipId),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: PawfectColors.pawfectOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK CARD — original dark style
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHealthCheckCard(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IllnessDetectorCameraScreen(),
            ),
          ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D3142), Color(0xFF1F232E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Health Check',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan your pet for potential health issues',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  IconData _getPetIcon(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.water;
      case 'rabbit':
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }
}
