import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_app_bar.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pawbook/providers/pet_provider.dart';

/// Profile — editorial / masthead style.
///
/// Layout intent (top to bottom):
///   1. Editorial header (rule + display + italic accent)
///   2. Magazine-style hero card (avatar + name + email + member-since)
///   3. Account dossier strip (italic mini-bio between hairlines)
///   4. Preferences section (editorial tiles)
///   5. Support section (editorial tiles)
///   6. Sign out — text-link CTA in red
///   7. Signature mark
///
/// Strict palette: cream / white / orange / ink. Red is reserved for
/// the sign-out action only.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ─── Controllers preserved verbatim ───────────────────────────────
  final TextEditingController _nameController = TextEditingController();

  // ─── Palette ──────────────────────────────────────────────────────
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _emergency = Color(0xFFD32F2F);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ─── AuthProvider helpers (verbatim) ─────────────────────────────
  String _displayName(AuthProvider auth) =>
      auth.userData?.displayName ??
      auth.firebaseUser?.displayName ??
      'Pet Parent';

  String _displayEmail(AuthProvider auth) =>
      auth.userData?.email ?? auth.firebaseUser?.email ?? '';

  String? _photoUrl(AuthProvider auth) =>
      auth.userData?.profileImageUrl ?? auth.firebaseUser?.photoURL;

  DateTime _memberSince(AuthProvider auth) =>
      auth.userData?.createdAt ?? DateTime.now();

  // ─────────────────────────── Build ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final auth = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final petCount = petProvider.petsCount;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: PawfectColors.pawfectCream,
      appBar: const LiquidAppBar(
        title: 'Profile',
        subtitle: 'Manage your account',
        icon: Icons.person_rounded,
      ),
      body: Stack(
        children: [
          const LiquidBackground(density: 0.55),
          // Atmospheric peach halo near the top
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditorialHeader(auth),
                  const SizedBox(height: 26),
                  const _Ornament(),
                  const SizedBox(height: 22),
                  _buildHeroCard(auth, petCount),
                  const SizedBox(height: 22),
                  _buildAccountDossier(auth),
                  const SizedBox(height: 32),
                  const _Ornament(),
                  const SizedBox(height: 22),
                  _buildSection(
                    eyebrow: 'PREFERENCES',
                    suffix: 'TUNE',
                    children: [
                      _SettingTile(
                        title: 'Edit profile',
                        description: 'Name, photo, contact details.',
                        icon: Icons.person_outline_rounded,
                        onTap: () => _showEditNameDialog(),
                      ),
                      _SettingTile(
                        title: 'Notifications',
                        description: 'Care reminders and alerts.',
                        icon: Icons.notifications_outlined,
                        onTap: () => _showComingSoon('Notifications'),
                      ),
                      _SettingTile(
                        title: 'Language',
                        description: 'English (US).',
                        icon: Icons.language_rounded,
                        onTap: () => _showComingSoon('Language settings'),
                      ),
                      _SettingTile(
                        title: 'Privacy and data',
                        description: 'Control how your data is used.',
                        icon: Icons.privacy_tip_outlined,
                        onTap: () => _showComingSoon('Privacy settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    eyebrow: 'SUPPORT',
                    suffix: 'HELLO',
                    children: [
                      _SettingTile(
                        title: 'Help center',
                        description: 'FAQs and contact support.',
                        icon: Icons.help_outline_rounded,
                        onTap: () => _showComingSoon('Help Center'),
                      ),
                      _SettingTile(
                        title: 'About Pawfect',
                        description: 'Version 1.0.0.',
                        icon: Icons.info_outline_rounded,
                        onTap: _showAbout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSignOutLink(),
                  const SizedBox(height: 30),
                  _buildSignatureMark(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Editorial header ─────────────────────
  Widget _buildEditorialHeader(AuthProvider auth) {
    final firstName = _displayName(auth).split(' ').first;
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
              'PROFILE',
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
              'YOU',
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
        // Single-line "Hello, [name]." — RichText keeps both spans on
        // the same baseline. The italic orange first-name is the
        // personality moment.
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.8,
              height: 1.05,
            ),
            children: [
              const TextSpan(text: 'Hello, '),
              TextSpan(
                text: '$firstName.',
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: PawfectColors.pawfectOrange,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Hero card ───────────────────────────
  Widget _buildHeroCard(AuthProvider auth, int petCount) {
    final email = _displayEmail(auth);
    final memberSince = _formatMemberSince(auth);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
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
            color: Color(0x1FFDA002),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with orange ring
          GestureDetector(
            onTap: _showEditNameDialog,
            child: Container(
              width: 110,
              height: 110,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    PawfectColors.pawfectOrange,
                    Color(0xFFFFB347),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PawfectColors.pawfectOrange.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _photoUrl(auth) != null &&
                          _photoUrl(auth)!.isNotEmpty
                      ? Image.network(
                          _photoUrl(auth)!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name with edit affordance
          GestureDetector(
            onTap: _showEditNameDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _displayName(auth),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: -0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: _inkSoft,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? 'No email on file' : email,
            style: const TextStyle(
              fontSize: 12.5,
              color: _inkSoft,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          // Stat row — three quiet stats in a row, divided by hairlines
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.85),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _heroStat(
                    label: petCount == 1 ? 'PET' : 'PETS',
                    value: petCount.toString().padLeft(2, '0'),
                  ),
                ),
                _heroDivider(),
                Expanded(
                  child: _heroStat(
                    label: 'MEMBER',
                    value: memberSince,
                  ),
                ),
                _heroDivider(),
                Expanded(
                  child: _heroStat(
                    label: 'STATUS',
                    value: 'Active',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.4,
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: _inkSoft,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 28,
      color: _inkSoft.withOpacity(0.18),
    );
  }

  // ─────────────────────────── Account dossier ───────────────────────
  /// Editorial mini-bio between hairlines — the same rhythm as the
  /// pet dossier on the dashboard.
  Widget _buildAccountDossier(AuthProvider auth) {
    final email = _displayEmail(auth);
    final fragments = <String>[
      'Pawfect member',
      _formatJoinedDate(auth),
      if (email.isNotEmpty) email.split('@').first,
      'Standard plan',
    ];

    return Column(
      children: [
        Container(width: double.infinity, height: 1, color: _hairline),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              for (var i = 0; i < fragments.length; i++) ...[
                Text(
                  fragments[i],
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                    letterSpacing: 0.1,
                  ),
                ),
                if (i < fragments.length - 1)
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: PawfectColors.pawfectOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
        Container(width: double.infinity, height: 1, color: _hairline),
      ],
    );
  }

  // ─────────────────────────── Section ────────────────────────────
  Widget _buildSection({
    required String eyebrow,
    required String suffix,
    required List<Widget> children,
  }) {
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
            Text(
              eyebrow,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 24, height: 1, color: _hairline),
            const SizedBox(width: 12),
            Text(
              suffix,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _inkSoft,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ─────────────────────────── Sign out link ──────────────────────
  Widget _buildSignOutLink() {
    return Center(
      child: GestureDetector(
        onTap: _showLogoutDialog,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SIGN OUT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: _emergency,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 22, height: 1, color: _emergency),
              const SizedBox(width: 6),
              const Icon(
                Icons.logout_rounded,
                size: 14,
                color: _emergency,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Signature mark ───────────────────────
  /// The Pawfect brand logo as a footer colophon. Sits beneath the
  /// sign-out link with a quiet italic tagline beneath the mark.
  Widget _buildSignatureMark() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tiny hairline rule + open orange ring above the logo,
        // anchoring it as the page's closing colophon.
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

  // ─────────────────────────── Helpers ─────────────────────────────
  String _formatMemberSince(AuthProvider auth) {
    final diff = DateTime.now().difference(_memberSince(auth));
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '${months}mo';
    }
    final years = (diff.inDays / 365).floor();
    return '${years}y';
  }

  String _formatJoinedDate(AuthProvider auth) {
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
    final d = _memberSince(auth);
    return 'Joined ${months[d.month - 1]} ${d.year}';
  }

  // ─────────────────────────── Edit name dialog ─────────────────────
  void _showEditNameDialog() {
    HapticFeedback.lightImpact();
    // Capture references from the OUTER (screen) context so the SAVE
    // handler can use them after the dialog is popped — using the
    // dialog's BuildContext after Navigator.pop reaches into a torn
    // down element and silently no-ops the provider call.
    final auth = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    _nameController.text = _displayName(auth);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF6E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    'EDIT NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'How should we call you?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.9),
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: _ink,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(
                      color: _inkSoft.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: PawfectColors.pawfectOrange,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      label: 'CANCEL',
                      isPrimary: false,
                      onTap: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogButton(
                      label: 'SAVE',
                      isPrimary: true,
                      onTap: () async {
                        final newName = _nameController.text.trim();
                        Navigator.pop(dialogContext);
                        if (newName.isEmpty) return;
                        // Use the captured outer references — never the
                        // dialog's context after pop.
                        final ok = await auth.updateUserProfile(
                          displayName: newName,
                        );
                        if (!mounted) return;
                        if (!ok) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ??
                                    'Could not update name. Try again.',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _emergency,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
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

  Widget _dialogButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [_ink, _inkDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 1.2,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: _ink.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: isPrimary ? Colors.white : _ink,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Logout dialog ────────────────────────
  void _showLogoutDialog() {
    HapticFeedback.lightImpact();
    // Capture references from the outer screen context so the
    // confirmation handler can use them after the dialog is popped.
    final auth = context.read<AuthProvider>();
    final pets = context.read<PetProvider>();
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF0F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _emergency,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SIGN OUT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Leaving so soon?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "You'll need to sign in again to see your pets and care history.",
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft.withOpacity(0.92),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      label: 'STAY',
                      isPrimary: false,
                      onTap: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        // Use captured outer references — never the
                        // dialog's context after pop.
                        await auth.signOut();
                        pets.clear();
                        if (!mounted) return;
                        navigator.popUntil((route) => route.isFirst);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _emergency,
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
                            'SIGN OUT',
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
    );
  }

  // ─────────────────────────── Coming soon snackbar ─────────────────
  void _showComingSoon(String feature) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature. Coming soon.',
          style: const TextStyle(
            color: Colors.white,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ─────────────────────────── About dialog ──────────────────────────
  void _showAbout() {
    HapticFeedback.lightImpact();
    showAboutDialog(
      context: context,
      applicationName: 'Pawfect',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              PawfectColors.pawfectOrange,
              Color(0xFFFFB347),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: PawfectColors.pawfectOrange.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.pets_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'AI-powered pet healthcare. Illness detection, '
            'poisoning emergency guidance, and a digital PawBook for '
            'continuous, vet-ready care.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Avatar fallback ───────────────────────
class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFFFF0D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 50,
          color: PawfectColors.pawfectOrange,
        ),
      ),
    );
  }
}

// ─────────────────────────── Setting tile ──────────────────────────
class _SettingTile extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  bool _pressed = false;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(18),
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
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PawfectColors.pawfectOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: PawfectColors.pawfectOrange.withOpacity(0.28),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: PawfectColors.pawfectOrange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
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
                      widget.description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: _inkSoft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: PawfectColors.pawfectOrange,
              ),
            ],
          ),
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
