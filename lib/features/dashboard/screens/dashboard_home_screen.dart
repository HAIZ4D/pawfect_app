import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/diagnosis_model.dart';
import '../../../models/pet_model.dart';
import '../../../models/weight_record_model.dart';
import '../../../repositories/health_repository.dart';
import '../../pawbook/providers/pet_provider.dart';
import '../../pawbook/screens/pet_profile_screen.dart';
import '../../pawbook/screens/add_pet_screen.dart';
import '../../pawbook/screens/pet_medical_history_screen.dart';
import '../../detector/repositories/illness_detector_repository.dart';
import '../../detector/screens/illness_detector_camera_screen.dart';
import '../../detector/screens/illness_result_screen.dart';
import '../../../services/pet_care_tip_service.dart';

/// Dashboard — editorial / magazine-cover home with atmospheric warmth.
///
/// Layered visual stack (back to front):
///   • Cream page + paw watermarks
///   • Soft peach radial halo behind the pet hero (the warm light
///     source the page composes around)
///   • Editorial greeting (date rule + display salute + italic accent)
///   • Magazine-cover pet hero with editorial overlay
///   • Pagination rule (sliding bar, not dots)
///   • Pet dossier strip (italic mini-bio between hairlines)
///   • Pull-quote daily insight (giant ghost quotation mark)
///   • Primary dark CTA + whisper-link secondaries
///
/// Strict palette: cream / white / orange / ink. Red is reserved for
/// the poison-alert whisper link.
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  // ─── State preserved verbatim from previous design ───────────────
  final PetCareTipService _tipService = PetCareTipService();
  String _currentTip = 'Loading…';
  bool _isLoadingTip = true;

  late final PageController _petPageController;
  int _currentPage = 0;

  // ─── New: health-data repos & cached results ─────────────────────
  final RemindersRepository _remindersRepo = RemindersRepository();
  final WeightRepository _weightRepo = WeightRepository();
  final IllnessDetectorRepository _diagnosisRepo =
      IllnessDetectorRepository();

  List<ReminderModel> _upcomingReminders = const [];
  List<DiagnosisModel> _recentScans = const [];
  List<WeightRecordModel> _weightLogs = const [];
  bool _isLoggingWeight = false;
  String? _activePetIdForData;

  // ─── Palette (only these in this screen) ─────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);

  @override
  void initState() {
    super.initState();
    // Tighter viewport fraction = narrower cards = portrait feel.
    _petPageController = PageController(viewportFraction: 0.74);
    _initializeTipService();
    _loadGlobalReminders();
  }

  @override
  void dispose() {
    _petPageController.dispose();
    super.dispose();
  }

  // ─── Tip service (verbatim) ───────────────────────────────────────
  Future<void> _initializeTipService() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isNotEmpty) {
        await _tipService.initialize(apiKey);
      }
      await _refreshTip();
    } catch (_) {
      setState(() {
        _currentTip = 'Fresh water and a gentle walk make most days better.';
        _isLoadingTip = false;
      });
    }
  }

  Future<void> _refreshTip() async {
    setState(() => _isLoadingTip = true);
    try {
      final petProvider = context.read<PetProvider>();
      String tip;
      if (petProvider.hasPets && _currentPage < petProvider.pets.length) {
        final selectedPet = petProvider.pets[_currentPage];
        tip = await _tipService.generatePetCareTip(selectedPet);
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
          _currentTip = 'Fresh water and a gentle walk make most days better.';
          _isLoadingTip = false;
        });
      }
    }
  }

  void _onPetPageChanged(int page, int petCount) {
    HapticFeedback.lightImpact();
    setState(() => _currentPage = page);
    if (page < petCount) {
      _refreshTip();
      // Load the per-pet data (recent scans + weight logs) when the
      // active card changes. Not awaited — UI can render the previous
      // values until the new ones arrive.
      _loadPetSpecificData(context.read<PetProvider>().pets[page]);
    }
  }

  // ─── Health-data loaders ──────────────────────────────────────────
  Future<void> _loadGlobalReminders() async {
    final items = await _remindersRepo.getUpcoming(limit: 3);
    if (mounted) setState(() => _upcomingReminders = items);
  }

  Future<void> _loadPetSpecificData(PetModel pet) async {
    final petKey = pet.id ?? pet.name;
    if (_activePetIdForData == petKey) return;
    _activePetIdForData = petKey;

    // Recent scans (uses existing diagnosis repository).
    if (pet.id != null) {
      final scans = await _diagnosisRepo.getPetDiagnoses(pet.id!);
      if (mounted) {
        setState(() => _recentScans = scans.take(3).toList());
      }
      final weights = await _weightRepo.getPetWeights(pet.id!);
      if (mounted) setState(() => _weightLogs = weights);
    } else {
      if (mounted) {
        setState(() {
          _recentScans = const [];
          _weightLogs = const [];
        });
      }
    }
  }

  Future<void> _markReminderDone(ReminderModel reminder) async {
    if (reminder.id == null) return;
    HapticFeedback.lightImpact();
    final ok = await _remindersRepo.markComplete(reminder.id!);
    if (ok) {
      await _loadGlobalReminders();
    }
  }

  Future<void> _logWeight(PetModel pet) async {
    if (pet.id == null) return;
    final weight = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _LogWeightSheet(
        currentLatest: _weightLogs.isNotEmpty
            ? _weightLogs.last.weight
            : pet.weight,
      ),
    );
    if (weight == null || !mounted) return;
    setState(() => _isLoggingWeight = true);
    try {
      await _weightRepo.add(petId: pet.id!, weight: weight);
      if (!mounted) return;
      setState(() => _isLoggingWeight = false);
      // Reload chart data so the new point shows.
      _activePetIdForData = null;
      await _loadPetSpecificData(pet);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingWeight = false);
      // Surface the real error message so Firestore-rules issues are
      // diagnosable. PERMISSION_DENIED reads as "rules need updating"
      // for the developer; anything else points at network/data.
      final raw = e.toString();
      final friendly = raw.contains('permission-denied') ||
              raw.contains('PERMISSION_DENIED')
          ? 'Permission denied. Update firestore.rules in the Firebase '
              'Console (the weight_records collection needs the new '
              'rules deployed).'
          : 'Could not save weight. $raw';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendly,
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 6),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ─────────────────────────── Build ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;

    if (_currentPage >= pets.length && pets.isNotEmpty) {
      _currentPage = 0;
    }

    // Trigger per-pet data load on first build with pets.
    if (pets.isNotEmpty && _currentPage < pets.length) {
      final activePet = pets[_currentPage];
      final petKey = activePet.id ?? activePet.name;
      if (_activePetIdForData != petKey) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadPetSpecificData(activePet);
        });
      }
    }

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Dashboard',
        subtitle: 'Your pack at a glance',
        icon: Icons.dashboard_rounded,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.7),
          // Atmospheric peach halo — soft warm radial that draws focus
          // toward the carousel area.
          Positioned(
            top: topInset + 220,
            left: -120,
            right: -120,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0),
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
            child: RefreshIndicator(
              onRefresh: () async {
                await petProvider.loadPets();
                await _refreshTip();
              },
              color: PawfectColors.pawfectOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(0, topInset + 132, 0, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildEditorialGreeting(petProvider),
                    ),
                    const SizedBox(height: 18),
                    // Daily insight sits right under the greeting so
                    // it's the first thing the user reads each session.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPullQuote(),
                    ),
                    if (_upcomingReminders.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildTodayStrip(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const _Ornament(),
                    ),
                    const SizedBox(height: 22),
                    if (pets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildEmptyHero(),
                      )
                    else ...[
                      // Carousel + info card composed in a Stack so the
                      // tall portrait card paints in FRONT of the info
                      // card. Overlap = (carousel height) -
                      // (info card top padding).
                      _buildHeroStack(pets),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildPaginationRule(pets.length + 1),
                      ),
                      // Weight trend first — always visible for a real
                      // pet (not the Add Pet ghost), even when empty.
                      if (_currentPage < pets.length) ...[
                        const SizedBox(height: 28),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildWeightTrendCard(pets[_currentPage]),
                        ),
                      ],
                      // Recent scans section under weight — only when
                      // active pet has any scans.
                      if (_currentPage < pets.length &&
                          _recentScans.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildRecentScansSection(pets[_currentPage]),
                      ],
                    ],
                    const SizedBox(height: 36),
                    _buildSignatureMark(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Editorial greeting ───────────────────
  Widget _buildEditorialGreeting(PetProvider petProvider) {
    final now = DateTime.now();
    final hour = now.hour;
    String salute;
    if (hour < 12) {
      salute = 'Good morning,';
    } else if (hour < 17) {
      salute = 'Good afternoon,';
    } else {
      salute = 'Good evening,';
    }

    final petName =
        petProvider.hasPets && _currentPage < petProvider.pets.length
            ? petProvider.pets[_currentPage].name
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial date eyebrow with hairline rule + pet count
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
            Text(
              _formatDateLong(now).toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: _hairline)),
            const SizedBox(width: 12),
            if (petProvider.hasPets)
              Text(
                '${petProvider.petsCount} ${petProvider.petsCount == 1 ? "PET" : "PETS"}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _inkSoft,
                  letterSpacing: 1.6,
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          salute,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          petName != null ? "$petName's human." : 'lovely human.',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: PawfectColors.pawfectOrange,
            letterSpacing: -0.6,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        // Subtle contextual line — italic ink-soft, lowers the energy
        // gracefully into the carousel below.
        Text(
          petName != null
              ? 'A few quiet minutes with $petName.'
              : 'Add a companion to begin.',
          style: TextStyle(
            fontSize: 13.5,
            color: _inkSoft.withOpacity(0.92),
            height: 1.55,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatDateLong(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[dt.weekday - 1]} · ${dt.day} ${months[dt.month - 1]}';
  }

  // ─────────────────────────── Hero stack (carousel + info) ──────────
  /// Layered composition: the info card sits in the page-flow with a
  /// large top padding equal to (carouselHeight - overlap). The
  /// carousel is positioned at the top of the stack so it paints AFTER
  /// the info card, putting the card visually in front.
  Widget _buildHeroStack(List<PetModel> pets) {
    const carouselHeight = 420.0;
    const overlap = 84.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Info card — drawn first, hosts the Stack's intrinsic size.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            carouselHeight - overlap,
            24,
            0,
          ),
          child: _buildInfoCard(pets),
        ),
        // Carousel — positioned at the top, painted on top of the
        // info card's overlap region.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: carouselHeight,
          child: _buildPetCarousel(pets),
        ),
      ],
    );
  }

  // ─────────────────────────── Pet carousel (magazine cover) ─────────
  Widget _buildPetCarousel(List<PetModel> pets) {
    return SizedBox(
      height: 420,
      child: PageView.builder(
        controller: _petPageController,
        physics: const BouncingScrollPhysics(),
        itemCount: pets.length + 1,
        onPageChanged: (page) => _onPetPageChanged(page, pets.length),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _petPageController,
            builder: (context, child) {
              double pageOffset = 0;
              if (_petPageController.position.haveDimensions) {
                pageOffset = (_petPageController.page ?? 0) - index;
              }
              final scale =
                  (1 - (pageOffset.abs() * 0.06)).clamp(0.9, 1.0);
              final opacity =
                  (1 - (pageOffset.abs() * 0.4)).clamp(0.55, 1.0);
              return Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: index == pets.length
                  ? _buildAddPetCard()
                  : _buildPetMagazineCard(pets[index], index, pets.length),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPetMagazineCard(PetModel pet, int index, int totalPets) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.26),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
            // Warm peach lift — subtle, brand-coloured ambient
            BoxShadow(
              color: PawfectColors.pawfectOrange.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Pet photo — full bleed
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
                      size: 110,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ),

              // Editorial bottom gradient — long, soft, dark
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
                    stops: const [0.45, 0.7, 1.0],
                  ),
                ),
              ),

              // Hairline white border (premium framing)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.32),
                    width: 1.2,
                  ),
                ),
              ),

              // Top-right: editorial pagination annotation
              if (totalPets > 1)
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
                      '${(index + 1).toString().padLeft(2, "0")} / ${totalPets.toString().padLeft(2, "0")}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),

              // Bottom-left: small editorial caps label only. The full
              // name + breed/age live in the info card below the
              // carousel so the photo can breathe.
              Positioned(
                left: 22,
                bottom: 22,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.32),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.28),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    pet.species.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPetCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPetScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF6E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '+',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: PawfectColors.pawfectOrange,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add a companion',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to begin.',
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
      ),
    );
  }

  // ─────────────────────────── Pagination rule ─────────────────────
  Widget _buildPaginationRule(int total) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: _hairline,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                AnimatedAlign(
                  alignment: Alignment(
                    total <= 1
                        ? -1
                        : ((_currentPage / (total - 1)) * 2 - 1),
                    0,
                  ),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: FractionallySizedBox(
                    widthFactor: total <= 1 ? 1 : 1 / total,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: _currentPage >= total - 1
                            ? _ink
                            : PawfectColors.pawfectOrange,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${(_currentPage + 1).toString().padLeft(2, "0")} / ${total.toString().padLeft(2, "0")}',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Info card ──────────────────────────
  /// Card-slider companion: sits visually beneath the carousel and
  /// updates with a fade + slide transition as the active card
  /// changes. Inspired by the Vue/GSAP card-slider pattern where the
  /// info section is the storyteller for the active card.
  Widget _buildInfoCard(List<PetModel> pets) {
    final isOnAddCard = _currentPage >= pets.length;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isOnAddCard
          ? _buildAddPetInfoCard(key: const ValueKey('add-info'))
          : _buildPetInfoCard(
              pets[_currentPage],
              key: ValueKey(
                'pet-info-${pets[_currentPage].id ?? pets[_currentPage].name}',
              ),
            ),
    );
  }

  Widget _buildPetInfoCard(PetModel pet, {Key? key}) {
    final fragments = <String>[
      pet.getAge(),
      if (pet.weight != null) '${pet.weight} kg',
      if (pet.color != null && pet.color!.isNotEmpty) pet.color!,
    ];

    // Poetic italic descriptor below the name. Combines color + breed
    // when both exist; falls back to breed alone.
    final descriptor = pet.color != null && pet.color!.isNotEmpty
        ? '${pet.color} ${pet.breed.toLowerCase()}.'
        : '${pet.breed}.';

    // Border radius matches the pet card so the two read as a layered
    // pair. Top padding > carousel overlap (84) so all content lives
    // below the pet card.
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAEE), Color(0xFFFFF1D6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.16),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
          // Peach ambient lift — same brand glow as the pet card
          BoxShadow(
            color: PawfectColors.pawfectOrange.withOpacity(0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative paw watermark — soft, brand-anchored,
          // bottom-right corner so it doesn't fight the headline.
          Positioned(
            bottom: -14,
            right: -10,
            child: Transform.rotate(
              angle: -0.32,
              child: Icon(
                Icons.pets_rounded,
                size: 96,
                color: PawfectColors.pawfectOrange.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow with species echo from the pet card chip.
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
                    'YOUR COMPANION',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 22, height: 1, color: _hairline),
                  const SizedBox(width: 12),
                  Text(
                    pet.species.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _inkSoft,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display pet name — the page's anchor moment.
              Text(
                pet.name,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -1.2,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Italic orange accent — the "personality" line.
              Text(
                descriptor,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: PawfectColors.pawfectOrange,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              // Hairline + open ring ornament — the same family of
              // ornament used elsewhere on the page.
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 1,
                    color: PawfectColors.pawfectOrange.withOpacity(0.4),
                  ),
                  const SizedBox(width: 10),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1, color: _hairline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Italic data row — separated by tiny orange dots
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < fragments.length; i++) ...[
                    Text(
                      fragments[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: _inkSoft.withOpacity(0.95),
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (i < fragments.length - 1)
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: PawfectColors.pawfectOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 26),
              // Vertical action stack: ink primary (Run a Scan) on top,
              // brand-orange secondary (Open Records) underneath. The
              // pet card itself still navigates to the profile on tap,
              // so a separate "View profile" button is redundant.
              _infoActionButton(
                label: 'RUN A SCAN',
                icon: Icons.health_and_safety_rounded,
                variant: _InfoButtonVariant.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          IllnessDetectorCameraScreen(selectedPet: pet),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _infoActionButton(
                label: 'OPEN RECORDS',
                icon: Icons.folder_copy_rounded,
                variant: _InfoButtonVariant.accent,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetMedicalHistoryScreen(pet: pet),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPetInfoCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAEE), Color(0xFFFFF1D6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: PawfectColors.pawfectOrange.withOpacity(0.32),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.16),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: PawfectColors.pawfectOrange.withOpacity(0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            bottom: -14,
            right: -10,
            child: Transform.rotate(
              angle: -0.32,
              child: Icon(
                Icons.pets_rounded,
                size: 96,
                color: PawfectColors.pawfectOrange.withOpacity(0.08),
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
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 22, height: 1, color: _hairline),
                  const SizedBox(width: 12),
                  const Text(
                    'BEGIN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _inkSoft,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Add a companion.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A photo, a name. The rest writes itself.',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: PawfectColors.pawfectOrange,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 1,
                    color: PawfectColors.pawfectOrange.withOpacity(0.4),
                  ),
                  const SizedBox(width: 10),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1, color: _hairline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Personalised AI care begins the moment you introduce them.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft.withOpacity(0.95),
                  letterSpacing: 0.1,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              _infoActionButton(
                label: 'ADD A PET',
                icon: Icons.add_rounded,
                variant: _InfoButtonVariant.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPetScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoActionButton({
    required String label,
    required IconData icon,
    required _InfoButtonVariant variant,
    required VoidCallback onTap,
  }) {
    final isPrimary = variant == _InfoButtonVariant.primary;
    final isAccent = variant == _InfoButtonVariant.accent;
    final foreground = isPrimary || isAccent ? Colors.white : _ink;

    Gradient? backgroundGradient;
    Color? backgroundColor;
    Border? backgroundBorder;
    List<BoxShadow>? backgroundShadow;

    if (isPrimary) {
      backgroundGradient = const LinearGradient(
        colors: [_ink, _inkDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      backgroundShadow = [
        BoxShadow(
          color: _ink.withOpacity(0.28),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
    } else if (isAccent) {
      // Brand orange-to-yellow gradient — same family as the pawfect
      // photo card fallback and the brand button gradients used on the
      // login / register screens.
      backgroundGradient = const LinearGradient(
        colors: [
          PawfectColors.pawfectOrange,
          Color(0xFFFFB347),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      backgroundShadow = [
        BoxShadow(
          color: PawfectColors.pawfectOrange.withOpacity(0.36),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    } else {
      // Secondary (white outlined) — kept available for future use
      backgroundColor = Colors.white.withOpacity(0.7);
      backgroundBorder = Border.all(
        color: Colors.white.withOpacity(0.85),
        width: 1.2,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: backgroundGradient,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: backgroundBorder,
          boxShadow: backgroundShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Leading: tiny brand dot for primary, icon for accent /
            // secondary. Keeps the visual rhythm distinct.
            if (isPrimary) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: foreground,
                letterSpacing: 1.6,
              ),
            ),
            // Trailing rule + arrow on primary / accent for an
            // editorial CTA feel.
            if (isPrimary || isAccent) ...[
              const SizedBox(width: 10),
              Container(width: 18, height: 1, color: foreground),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 14, color: foreground),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Pull-quote insight ────────────────────
  /// Compact daily-tip card. Slim padding, smaller quote mark and
  /// body type so the card sits comfortably right under the greeting
  /// without stealing focus from the carousel below.
  Widget _buildPullQuote() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 10,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 18, height: 1, color: _hairline),
              const SizedBox(width: 8),
              const Text(
                'INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isLoadingTip ? null : _refreshTip,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _hairline,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: _isLoadingTip
                      ? const SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: PawfectColors.pawfectOrange,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 12,
                          color: _ink,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -2,
                top: -10,
                child: Text(
                  '“',
                  style: TextStyle(
                    fontSize: 52,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: PawfectColors.pawfectOrange.withOpacity(0.24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 0, 0),
                child: Text(
                  _currentTip,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                    height: 1.5,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 18, height: 1, color: _inkSoft.withOpacity(0.3)),
              const SizedBox(width: 6),
              Text(
                'Curated by Gemini',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _inkSoft.withOpacity(0.75),
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Today strip ───────────────────────
  Widget _buildTodayStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 10,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 18, height: 1, color: _hairline),
              const SizedBox(width: 8),
              const Text(
                'CARE QUEUE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                '${_upcomingReminders.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: PawfectColors.pawfectOrange,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _upcomingReminders.length; i++) ...[
            _buildReminderRow(_upcomingReminders[i]),
            if (i < _upcomingReminders.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: _hairline,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderRow(ReminderModel reminder) {
    final dueColor = reminder.isOverdue
        ? const Color(0xFFD32F2F)
        : reminder.isDueToday
            ? PawfectColors.pawfectOrange
            : _inkSoft;
    final dueLabel = _formatDueLabel(reminder);
    return GestureDetector(
      onTap: () => _markReminderDone(reminder),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Type-coded leading icon — small, in a soft tinted square
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: PawfectColors.pawfectOrange.withOpacity(0.28),
                  width: 1,
                ),
              ),
              child: Icon(
                _iconForReminderType(reminder.type),
                size: 15,
                color: PawfectColors.pawfectOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: dueColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            // Tap-to-done check
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hairline,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForReminderType(ReminderType type) {
    switch (type) {
      case ReminderType.vaccination:
        return Icons.vaccines_rounded;
      case ReminderType.medication:
        return Icons.medication_rounded;
      case ReminderType.checkup:
        return Icons.local_hospital_rounded;
      case ReminderType.grooming:
        return Icons.content_cut_rounded;
      case ReminderType.feeding:
        return Icons.restaurant_rounded;
      case ReminderType.exercise:
        return Icons.directions_walk_rounded;
      case ReminderType.other:
        return Icons.event_rounded;
    }
  }

  String _formatDueLabel(ReminderModel reminder) {
    if (reminder.isOverdue) return 'Overdue.';
    if (reminder.isDueToday) return 'Today.';
    final days = reminder.dueDate.difference(DateTime.now()).inDays;
    if (days == 1) return 'Tomorrow.';
    if (days <= 7) return 'In $days days.';
    final dt = reminder.dueDate;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}.';
  }

  // ─────────────────────────── Recent scans rail ───────────────────
  Widget _buildRecentScansSection(PetModel pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
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
                'RECENT SCANS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: _hairline)),
              const SizedBox(width: 12),
              Text(
                '${_recentScans.length} OF ${_recentScans.length}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _inkSoft,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Health pulse chart — colored urgency dots on a smooth ink
        // line, oldest on the left, newest on the right. Higher dot =
        // more urgent. A flat low line reads as "consistently healthy".
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildHealthPulse(),
        ),
        const SizedBox(height: 18),
        SizedBox(
          // Bumped from 168 → 180 to absorb the small overflow caused
          // by 2-line condition text + urgency row + photo height +
          // card border. Gives ~6pt of breathing room.
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _recentScans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                _buildRecentScanCard(_recentScans[i], pet),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthPulse() {
    // Reverse so oldest is on the left, newest on the right.
    final ordered = _recentScans.reversed.toList();
    final points = ordered.map((d) {
      final urgencyValue = _urgencyScore(d.urgencyLevel); // 1..4
      return _PulsePoint(
        urgencyValue: urgencyValue,
        color: _urgencyColor(d.urgencyLevel),
      );
    }).toList();

    // Highest urgency seen sets the headline label color.
    final peak = ordered.fold<int>(
      1,
      (max, d) => math.max(max, _urgencyScore(d.urgencyLevel).round()),
    );
    final peakUrgency = _urgencyLabelForScore(peak);
    final peakColor = _urgencyColor(peakUrgency);
    final peakDescription = _pulseDescription(ordered);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: peakColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HEALTH PULSE',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 18, height: 1, color: _hairline),
              const SizedBox(width: 8),
              Text(
                peakUrgency.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: peakColor,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                'PEAK',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _inkSoft,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            peakDescription,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _inkSoft.withOpacity(0.92),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: CustomPaint(
              painter: _HealthPulsePainter(points: points),
            ),
          ),
          const SizedBox(height: 8),
          // Tiny axis labels — old / new
          Row(
            children: [
              Text(
                'OLDEST',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _inkSoft.withOpacity(0.7),
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                'LATEST',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _inkSoft.withOpacity(0.7),
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Maps an urgency string to a 1..4 score (LOW=1 ... EMERGENCY=4).
  double _urgencyScore(String urgency) {
    switch (urgency) {
      case 'EMERGENCY':
        return 4;
      case 'HIGH':
        return 3;
      case 'MODERATE':
        return 2;
      case 'LOW':
      default:
        return 1;
    }
  }

  String _urgencyLabelForScore(int score) {
    switch (score) {
      case 4:
        return 'EMERGENCY';
      case 3:
        return 'HIGH';
      case 2:
        return 'MODERATE';
      default:
        return 'LOW';
    }
  }

  /// Plain-language description of the recent-scans trend.
  String _pulseDescription(List<DiagnosisModel> ordered) {
    if (ordered.isEmpty) return 'No scans yet.';
    if (ordered.length == 1) {
      return 'Single scan reading on file.';
    }
    final first = _urgencyScore(ordered.first.urgencyLevel);
    final last = _urgencyScore(ordered.last.urgencyLevel);
    if (last < first) {
      return 'Recent scans show improvement over time.';
    } else if (last > first) {
      return 'Severity has risen since the earliest scan.';
    }
    return 'Trend is steady across recent scans.';
  }

  Widget _buildRecentScanCard(DiagnosisModel diagnosis, PetModel pet) {
    final urgency = diagnosis.urgencyLevel;
    final urgencyColor = _urgencyColor(urgency);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IllnessResultScreen(
              diagnosis: diagnosis,
              pet: pet,
            ),
          ),
        );
      },
      child: Container(
        width: 196,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: photo or fallback gradient
              SizedBox(
                height: 88,
                width: double.infinity,
                child: diagnosis.imageBase64 != null
                    ? Image.memory(
                        _decodeBase64(diagnosis.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _scanFallbackArt(),
                      )
                    : _scanFallbackArt(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: urgencyColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          urgency,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: urgencyColor,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatScanDate(diagnosis.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _inkSoft,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      diagnosis.condition,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
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

  Widget _scanFallbackArt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF6E2), Color(0xFFFFE7C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.health_and_safety_rounded,
        color: PawfectColors.pawfectOrange.withOpacity(0.32),
        size: 36,
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'EMERGENCY':
        return const Color(0xFFD32F2F);
      case 'HIGH':
        return const Color(0xFFE65100);
      case 'MODERATE':
        return PawfectColors.pawfectOrange;
      case 'LOW':
      default:
        return const Color(0xFF2E8A68);
    }
  }

  String _formatScanDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return 'NOW';
    if (diff.inDays < 1) return '${diff.inHours}H';
    if (diff.inDays < 7) return '${diff.inDays}D';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}W';
    return '${(diff.inDays / 30).floor()}MO';
  }

  // ─────────────────────────── Weight trend card ───────────────────
  Widget _buildWeightTrendCard(PetModel pet) {
    final hasLogs = _weightLogs.isNotEmpty;
    final latest = hasLogs ? _weightLogs.last.weight : null;
    final trend = _computeWeightTrend();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 10,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'WEIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 18, height: 1, color: _hairline),
              const SizedBox(width: 8),
              Text(
                hasLogs
                    ? '${_weightLogs.length} ${_weightLogs.length == 1 ? "ENTRY" : "ENTRIES"}'
                    : 'NEW',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isLoggingWeight ? null : () => _logWeight(pet),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PawfectColors.pawfectOrange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: PawfectColors.pawfectOrange.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLoggingWeight
                          ? const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.6,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.add_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                      const SizedBox(width: 4),
                      const Text(
                        'LOG',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasLogs) ...[
            // Big number + tiny trend chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  latest!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -1.4,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: _inkSoft.withOpacity(0.92),
                    ),
                  ),
                ),
                const Spacer(),
                if (trend != null) _buildTrendChip(trend),
              ],
            ),
            const SizedBox(height: 14),
            // Sparkline
            SizedBox(
              height: 62,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: _weightLogs.map((w) => w.weight).toList(),
                  lineColor: PawfectColors.pawfectOrange,
                  fillColor: PawfectColors.pawfectOrange.withOpacity(0.16),
                  dotColor: PawfectColors.pawfectOrange,
                ),
              ),
            ),
          ] else ...[
            // Empty state — friendly invite to log first weight
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No weight logs yet.',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap LOG to start tracking ${pet.name}\'s weight over time.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _inkSoft.withOpacity(0.92),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChip(double change) {
    final isUp = change > 0;
    final isFlat = change.abs() < 0.05;
    final color = isFlat
        ? _inkSoft
        : (isUp
            ? const Color(0xFF2E8A68) // green for up — usually good
            : const Color(0xFFE65100)); // orange for down — concerning
    final icon = isFlat
        ? Icons.remove_rounded
        : (isUp
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.32), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// First-to-last weight delta (signed). Null if fewer than 2 logs.
  double? _computeWeightTrend() {
    if (_weightLogs.length < 2) return null;
    return _weightLogs.last.weight - _weightLogs.first.weight;
  }

  Uint8List _decodeBase64(String b64) {
    // Some saved diagnoses prefix with `data:image/...;base64,`. Strip
    // it before decoding so Image.memory doesn't choke.
    final idx = b64.indexOf(',');
    final body = idx >= 0 ? b64.substring(idx + 1) : b64;
    return base64Decode(body);
  }

  // ─────────────────────────── Signature mark ──────────────────────
  /// Magazine colophon: hairline rule + open ring + the Pawfect brand
  /// logo + italic tagline. Mirrors the footer on the profile and
  /// detector screens.
  Widget _buildSignatureMark() {
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
          'AI-powered pet healthcare.',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: _inkSoft.withOpacity(0.7),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Empty state hero ───────────────────
  Widget _buildEmptyHero() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPetScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF6E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.88),
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
            const SizedBox(height: 16),
            const Text(
              'No pets yet.',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your first.',
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
              'Personalised AI care begins the moment you introduce your companion.',
              style: TextStyle(
                fontSize: 13.5,
                color: _inkSoft,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
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
}

// ─────────────────────────── Info button variant ──────────────────
/// Visual variant for the action buttons inside the carousel info
/// card. Primary = ink-dark gradient, accent = brand orange-yellow.
enum _InfoButtonVariant { primary, accent }

// ─────────────────────────── Log weight bottom sheet ───────────────
/// Compact bottom sheet for entering a new weight reading. Returns
/// the entered value (kg) on save, or null on cancel.
class _LogWeightSheet extends StatefulWidget {
  final double? currentLatest;
  const _LogWeightSheet({this.currentLatest});

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  late final TextEditingController _controller;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLatest != null
          ? widget.currentLatest!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0 || value > 200) {
      // Invalid — just keep sheet open; the field shows what was typed.
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: const BoxDecoration(
          color: PawfectColors.pawfectCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                const SizedBox(height: 20),
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
                      'LOG WEIGHT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'How much do they weigh today?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 18),
                // Big number field with kg suffix
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          onSubmitted: (_) => _save(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: -1.0,
                          ),
                          decoration: const InputDecoration(
                            hintText: '5.2',
                            hintStyle: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: _inkSoft,
                              letterSpacing: -1.0,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 22, bottom: 6),
                        child: Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: _inkSoft.withOpacity(0.92),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.85),
                              width: 1.2,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_ink, _inkDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _ink.withOpacity(0.28),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'SAVE',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Health pulse chart ───────────────────
/// Single dot in the health-pulse chart: how urgent (1..4) and the
/// urgency colour to render the dot in.
class _PulsePoint {
  final double urgencyValue; // 1..4
  final Color color;
  const _PulsePoint({required this.urgencyValue, required this.color});
}

/// Plots health-pulse points across a strip: x = chronology, y =
/// urgency (higher = more severe). Points are coloured by their
/// urgency level; the connecting line is a soft ink hairline. The
/// background has subtle horizontal grid lines at each urgency level
/// to give the values context.
class _HealthPulsePainter extends CustomPainter {
  final List<_PulsePoint> points;

  const _HealthPulsePainter({required this.points});

  static const Color _ink = Color(0xFF2D3142);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Background: 4 faint horizontal grid lines for the 4 urgency
    // levels. Top = most severe.
    final gridPaint = Paint()
      ..color = _ink.withOpacity(0.06)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = (i / 3) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Compute the dot positions. y = top when urgency=4, bottom when 1.
    final positions = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : (i / (points.length - 1)) * size.width;
      // Map 1..4 → 1..0 (so 4 = 0 = top, 1 = 1 = bottom).
      final norm = (4 - points[i].urgencyValue) / 3;
      final y = norm * size.height;
      positions.add(Offset(x, y));
    }

    if (positions.length > 1) {
      // Smooth path between dots
      final path = Path()..moveTo(positions[0].dx, positions[0].dy);
      for (var i = 0; i < positions.length - 1; i++) {
        final p0 = positions[i];
        final p1 = positions[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        if (i == positions.length - 2) {
          path.lineTo(p1.dx, p1.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _ink.withOpacity(0.28)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw each dot — white halo, then coloured fill.
    for (var i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final color = points[i].color;
      canvas.drawCircle(pos, 6, Paint()..color = Colors.white);
      canvas.drawCircle(pos, 4.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _HealthPulsePainter old) =>
      old.points != points;
}

// ─────────────────────────── Sparkline painter ─────────────────────
/// Minimal sparkline: a smooth orange line with a soft fill underneath
/// and a small dot on the latest point. Auto-scales to the supplied
/// values' min/max with a small padding so the line doesn't kiss the
/// edges.
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;

  const _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    if (values.length == 1) {
      // Single point — draw a horizontal hairline through the centre.
      final mid = size.height / 2;
      final paint = Paint()
        ..color = lineColor.withOpacity(0.4)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, mid), Offset(size.width, mid), paint);
      // Single dot in the middle
      canvas.drawCircle(
        Offset(size.width / 2, mid),
        4,
        Paint()..color = dotColor,
      );
      return;
    }

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs();
    final pad = math.max(range * 0.18, 0.1);
    final yMin = minV - pad;
    final yMax = maxV + pad;
    final yRange = (yMax - yMin).abs();

    Offset pointAt(int i) {
      final x = (i / (values.length - 1)) * size.width;
      final norm = yRange == 0 ? 0.5 : (values[i] - yMin) / yRange;
      final y = size.height - (norm * size.height);
      return Offset(x, y);
    }

    final points = List.generate(values.length, pointAt);

    // Smooth path via Catmull-Rom-ish bezier interpolation between
    // adjacent points.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      if (i == points.length - 2) {
        path.lineTo(p1.dx, p1.dy);
      }
    }

    // Filled area under the curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = fillColor,
    );

    // The line itself
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dot on the latest point
    final last = points.last;
    canvas.drawCircle(
      last,
      5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      last,
      3.5,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values ||
      old.lineColor != lineColor ||
      old.fillColor != fillColor ||
      old.dotColor != dotColor;
}

// ─────────────────────────── Ornament rule ─────────────────────────
/// Same ornament used on the detector — paired hairlines flanking an
/// open orange ring. Anchors the brand visually at section breaks.
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
