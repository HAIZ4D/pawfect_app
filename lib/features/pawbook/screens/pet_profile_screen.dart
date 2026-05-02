import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../models/pet_model.dart';
import '../providers/pet_provider.dart';
import 'add_pet_screen.dart';
import 'pet_medical_history_screen.dart';
import 'poisoning_incidents_screen.dart';

/// Premium pet profile — peach hero card (matches dashboard pattern),
/// stat orbs, and frosted glass surfaces consistent with the rest of
/// the Pawfect language.
class PetProfileScreen extends StatefulWidget {
  final PetModel pet;

  const PetProfileScreen({super.key, required this.pet});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late PetModel _currentPet;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _peach = Color(0xFFFFEAD5);
  static const Color _mint = Color(0xFFD9F2E6);
  static const Color _sky = Color(0xFFDCE9FF);
  static const Color _rose = Color(0xFFFFDCE3);

  static const Color _emergency = Color(0xFFD32F2F);
  static const Color _success = Color(0xFF2E8A68);

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
  }

  // ─────────────────────────── Actions ───────────────────────────
  Future<void> _handleEdit() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPetScreen(pet: _currentPet),
      ),
    );

    if (result == true && mounted) {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final updatedPet = await petProvider.getPet(_currentPet.id!);
      if (updatedPet != null && mounted) {
        setState(() => _currentPet = updatedPet);
      }
    }
  }

  void _viewMedicalHistory() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetMedicalHistoryScreen(pet: _currentPet),
      ),
    );
  }

  void _viewPoisoningIncidents() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoisoningIncidentsScreen(pet: _currentPet),
      ),
    );
  }

  Future<void> _handleDelete() async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          radius: 24,
          blur: 24,
          tintOpacity: 0.7,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _emergency.withOpacity(0.9),
                          const Color(0xFFE5719A).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Delete this pet?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "${_currentPet.name}'s profile and history will be permanently removed. This cannot be undone.",
                style: const TextStyle(
                  fontSize: 13,
                  color: _inkSoft,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _emergency,
                              _emergency.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _emergency.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
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
    );

    if (confirmed == true && mounted) {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final success = await petProvider.deletePet(_currentPet.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_currentPet.name} deleted',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                petProvider.errorMessage ?? 'Failed to delete pet',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _emergency,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ─────────────────────────── Build ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: LiquidAppBar(
        title: _currentPet.name,
        subtitle: 'Pet profile',
        icon: Icons.pets_rounded,
        showBackButton: true,
        actions: [
          GestureDetector(
            onTap: _handleEdit,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 18,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, topInset + 132, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 22),
                _buildSectionEyebrow('VITAL STATS'),
                const SizedBox(height: 12),
                _buildStatGrid(),
                const SizedBox(height: 22),
                _buildSectionEyebrow('IDENTITY'),
                const SizedBox(height: 12),
                _buildIdentityCard(),
                const SizedBox(height: 22),
                _buildSectionEyebrow('CARE & HISTORY'),
                const SizedBox(height: 12),
                _buildHistoryTile(
                  tint: _peach,
                  accent: const Color(0xFFE07B2A),
                  icon: Icons.medical_services_rounded,
                  title: 'Medical Records',
                  subtitle: 'Diagnoses, vaccines & treatments',
                  onTap: _viewMedicalHistory,
                ),
                const SizedBox(height: 10),
                _buildHistoryTile(
                  tint: _rose,
                  accent: _emergency,
                  icon: Icons.shield_rounded,
                  title: 'Poisoning Incidents',
                  subtitle: 'Past exposures & first-aid actions',
                  onTap: _viewPoisoningIncidents,
                ),
                const SizedBox(height: 22),
                _buildFooterActions(),
                const SizedBox(height: 14),
                _buildDisclaimer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Hero card ───────────────────────────
  Widget _buildHeroCard() {
    final radius = BorderRadius.circular(28);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8EC), Color(0xFFFFE7C9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.75),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1FFDA002),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _speciesPill(),
                            _memberPill(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentPet.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -0.6,
                            height: 1.05,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentPet.breed,
                          style: const TextStyle(
                            fontSize: 14,
                            color: PawfectColors.pawfectOrange,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentPet.getAge(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _inkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Top sheen — light reflection over hero
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: radius,
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.55),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Decorative paw, top-right inside hero
        Positioned(
          top: 6,
          right: 4,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.35,
              child: Icon(
                Icons.pets_rounded,
                size: 96,
                color: PawfectColors.pawfectOrange.withOpacity(0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroAvatar() {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF0D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: PawfectColors.pawfectOrange.withOpacity(0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: _currentPet.imageBase64 != null
            ? _currentPet.getDecodedImage()
            : Center(
                child: Icon(
                  _speciesIcon(_currentPet.species),
                  size: 48,
                  color: PawfectColors.pawfectOrange,
                ),
              ),
      ),
    );
  }

  Widget _speciesPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            PawfectColors.pawfectOrange,
            Color(0xFFFFB347),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PawfectColors.pawfectOrange.withOpacity(0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _speciesIcon(_currentPet.species),
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            _currentPet.species.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 11,
            color: Color(0xFFE5719A),
          ),
          const SizedBox(width: 5),
          Text(
            _formatMemberSince(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Stat grid ───────────────────────────
  Widget _buildStatGrid() {
    final tiles = <_StatSpec>[
      _StatSpec(
        label: 'Age',
        value: _shortAge(),
        icon: Icons.cake_rounded,
        tint: _peach,
        accent: const Color(0xFFE07B2A),
      ),
      _StatSpec(
        label: 'Weight',
        value: _currentPet.weight != null ? '${_currentPet.weight} kg' : '—',
        icon: Icons.monitor_weight_rounded,
        tint: _mint,
        accent: _success,
      ),
      _StatSpec(
        label: 'Gender',
        value: _currentPet.gender,
        icon: _currentPet.gender.toLowerCase() == 'female'
            ? Icons.female_rounded
            : Icons.male_rounded,
        tint: _sky,
        accent: const Color(0xFF3E6BC6),
      ),
      _StatSpec(
        label: 'Color',
        value: _currentPet.color ?? '—',
        icon: Icons.palette_rounded,
        tint: _rose,
        accent: const Color(0xFFD16B87),
      ),
    ];

    return Row(
      children: [
        Expanded(child: _statTile(tiles[0])),
        const SizedBox(width: 10),
        Expanded(child: _statTile(tiles[1])),
        const SizedBox(width: 10),
        Expanded(child: _statTile(tiles[2])),
        const SizedBox(width: 10),
        Expanded(child: _statTile(tiles[3])),
      ],
    );
  }

  Widget _statTile(_StatSpec s) {
    return GlassCard(
      radius: 18,
      blur: 14,
      tintOpacity: 0.5,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  s.tint.withOpacity(0.95),
                  s.tint.withOpacity(0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: s.accent.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(s.icon, size: 18, color: s.accent),
          ),
          const SizedBox(height: 10),
          Text(
            s.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 8.5,
              color: _inkSoft,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.value,
            style: const TextStyle(
              fontSize: 13,
              color: _ink,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Identity card ───────────────────────────
  Widget _buildIdentityCard() {
    final rows = <Widget>[];

    rows.add(_detailRow(
      icon: Icons.event_rounded,
      label: 'Birthdate',
      value: _formatBirthdate(),
      tint: _peach,
      accent: const Color(0xFFE07B2A),
    ));

    if (_currentPet.microchipId != null && _currentPet.microchipId!.isNotEmpty) {
      rows.add(_divider());
      rows.add(_detailRow(
        icon: Icons.qr_code_rounded,
        label: 'Microchip ID',
        value: _currentPet.microchipId!,
        tint: _sky,
        accent: const Color(0xFF3E6BC6),
        monospace: true,
      ));
    }

    if (_currentPet.notes != null && _currentPet.notes!.isNotEmpty) {
      rows.add(_divider());
      rows.add(_detailRow(
        icon: Icons.sticky_note_2_rounded,
        label: 'Notes',
        value: _currentPet.notes!,
        tint: _mint,
        accent: _success,
        multiline: true,
      ));
    }

    return GlassCard(
      radius: 22,
      blur: 18,
      tintOpacity: 0.55,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white.withOpacity(0.5),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
    required Color accent,
    bool multiline = false,
    bool monospace = false,
  }) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          margin: EdgeInsets.only(top: multiline ? 2 : 0),
          decoration: BoxDecoration(
            color: tint.withOpacity(0.85),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  color: _inkSoft,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: monospace ? 13 : 14,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: monospace ? 0.4 : -0.1,
                  height: 1.4,
                  fontFamily: monospace ? 'monospace' : null,
                ),
                maxLines: multiline ? 4 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── History tile ───────────────────────────
  Widget _buildHistoryTile({
    required Color tint,
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      radius: 20,
      blur: 16,
      tintOpacity: 0.52,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tint.withOpacity(0.95),
                  tint.withOpacity(0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Footer actions ───────────────────────────
  Widget _buildFooterActions() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _handleEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    PawfectColors.pawfectOrange,
                    Color(0xFFFFB347),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: PawfectColors.pawfectOrange.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            radius: 18,
            blur: 14,
            tintOpacity: 0.55,
            elevated: false,
            padding: const EdgeInsets.symmetric(vertical: 15),
            onTap: _handleDelete,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: _emergency,
                ),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _emergency,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Disclaimer ───────────────────────────
  Widget _buildDisclaimer() {
    return GlassCard(
      radius: 18,
      blur: 12,
      tintOpacity: 0.45,
      elevated: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: _inkSoft.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Profile data is private to your account. Share via QR code from PawBook for vet visits.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: _inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Section eyebrow ───────────────────────────
  Widget _buildSectionEyebrow(String label) {
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
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _ink,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Helpers ───────────────────────────
  IconData _speciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'cat':
        return Icons.pets_rounded;
      case 'dog':
        return Icons.pets_rounded;
      case 'bird':
        return Icons.flutter_dash_rounded;
      case 'rabbit':
        return Icons.cruelty_free_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  String _shortAge() {
    final age = DateTime.now().difference(_currentPet.birthdate);
    if (age.inDays < 30) return '${age.inDays}d';
    if (age.inDays < 365) {
      final months = (age.inDays / 30).floor();
      return '${months}mo';
    }
    final years = (age.inDays / 365).floor();
    return '${years}y';
  }

  String _formatBirthdate() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = _currentPet.birthdate;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatMemberSince() {
    final created = _currentPet.createdAt ?? _currentPet.birthdate;
    final diff = DateTime.now().difference(created);
    if (diff.inDays < 1) return 'NEW MEMBER';
    if (diff.inDays < 30) return '${diff.inDays}D AGO';
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '${months}MO AGO';
    }
    final years = (diff.inDays / 365).floor();
    return '${years}Y AGO';
  }
}

class _StatSpec {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color accent;

  const _StatSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.accent,
  });
}
