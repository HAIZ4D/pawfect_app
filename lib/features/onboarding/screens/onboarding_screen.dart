import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';

/// Premium 2-page onboarding flow.
/// Page 1 — Welcome (cat hero, gentle breathing motion).
/// Page 2 — Auth choice (Google · Sign Up · Log In, with pulsing logo).
/// Floating paws drift continuously across both pages for visual life.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // One-shot entrance animation
  late final AnimationController _controller;
  late final Animation<double> _bgFade;
  late final Animation<double> _catFade;
  late final Animation<Offset> _catSlide;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  // Looping animations — paws drifting, cat breathing, logo pulsing.
  late final AnimationController _ambientController;

  late final PageController _pageController;
  int _currentPage = 0;

  static const Color _ink = Color(0xFF2D3142);
  static const int _totalPages = 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1900),
      vsync: this,
    );

    _bgFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _catFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
    );
    _catSlide = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.6, curve: Curves.easeOutCubic),
    ));
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
    ));

    _controller.forward();

    // Single ambient ticker drives every looping motion (paws + cat
    // breathe + logo pulse). One controller is cheaper than three and
    // stays in phase across them.
    _ambientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ambientController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
    // On the last page, the Continue CTA is swapped out for the auth
    // buttons via AnimatedSwitcher — so this branch isn't reachable.
  }

  bool _isSigningIn = false;

  Future<void> _continueWithGoogle() async {
    if (_isSigningIn) return;
    HapticFeedback.lightImpact();
    setState(() => _isSigningIn = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isSigningIn = false);
    if (!ok) {
      // Cancellation by the user is silent — surfaced as the same generic
      // error string from the provider. Skip the snackbar in that case.
      final msg = auth.errorMessage ?? '';
      if (!msg.toLowerCase().contains('cancel')) {
        _showSnack(msg.isEmpty ? 'Google sign-in failed. Please try again.' : msg);
      }
    }
    // On success, AuthGate (root) will rebuild to HomeScreen. Onboarding
    // is the gate's current child, so it gets swapped automatically.
  }

  void _goToLogin() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToRegister() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Multi-stop orange gradient background ──
          Positioned.fill(
            child: FadeTransition(
              opacity: _bgFade,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD08A),
                      Color(0xFFFFB347),
                      PawfectColors.pawfectOrange,
                      Color(0xFFE6840A),
                    ],
                    stops: [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Soft top-right radial highlight ──
          Positioned(
            top: -120,
            right: -120,
            child: FadeTransition(
              opacity: _bgFade,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.32),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Decorative paw watermarks ──
          Positioned(
            top: 90,
            right: 36,
            child: FadeTransition(
              opacity: _bgFade,
              child: Transform.rotate(
                angle: -0.4,
                child: Icon(
                  Icons.pets_rounded,
                  size: 130,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -28,
            child: FadeTransition(
              opacity: _bgFade,
              child: Transform.rotate(
                angle: 0.32,
                child: Icon(
                  Icons.pets_rounded,
                  size: 86,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 60,
            child: FadeTransition(
              opacity: _bgFade,
              child: Transform.rotate(
                angle: 0.6,
                child: Icon(
                  Icons.pets_rounded,
                  size: 54,
                  color: Colors.white.withOpacity(0.16),
                ),
              ),
            ),
          ),

          // ── Drifting paw watermarks (always-on ambient motion) ──
          Positioned.fill(
            child: FadeTransition(
              opacity: _bgFade,
              child: _FloatingPaws(controller: _ambientController),
            ),
          ),

          // ── PageView ──
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (page) {
              HapticFeedback.lightImpact();
              setState(() => _currentPage = page);
            },
            children: [
              _buildWelcomePage(size),
              _buildAuthPage(size),
            ],
          ),

          // ── Bottom: page indicator + CTA / auth buttons ──
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomInset + 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPageIndicator(),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _currentPage < _totalPages - 1
                      ? _buildContinueCTA(
                          key: const ValueKey('continue'),
                        )
                      : _buildAuthButtons(
                          key: const ValueKey('auth'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Page 1: Welcome ───────────────────────────
  Widget _buildWelcomePage(Size size) {
    return Stack(
      children: [
        // Cat — hero mascot. Anchored low so the head/ears sit just
        // below the title block, leaving the title clean on the left
        // half. Static (entrance fade/slide only) — no breathing.
        Positioned(
          right: -size.width * 0.16,
          bottom: -size.height * 0.08,
          child: SlideTransition(
            position: _catSlide,
            child: FadeTransition(
              opacity: _catFade,
              child: SizedBox(
                width: size.width * 1.35,
                height: size.height * 0.88,
                child: Image.asset(
                  'assets/images/cat-tabby.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),

        // Top-left welcome content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 240),
            child: SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _contentFade,
                child: _buildWelcomeContent(size),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeContent(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow
        Row(
          children: [
            Container(
              width: 28,
              height: 1.6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'PAWFECT',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.92),
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Hero headline — three short lines for visual rhythm. The poetic
        // first line creates the emotional hook; line two anchors it to
        // a pet truth; line three hints at the magic of the product.
        Text(
          'When they\ncan\'t tell you,',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.6,
            height: 1.02,
            shadows: [
              Shadow(
                offset: const Offset(0, 3),
                blurRadius: 10,
                color: _ink.withOpacity(0.16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Italic accent line — handwritten/script feel via FontStyle
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'we listen.',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: -1.6,
                height: 1.02,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 3),
                    blurRadius: 14,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Glowing dot accent
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Tagline — punchy product promise.
        SizedBox(
          width: size.width * 0.62,
          child: Text(
            'AI that reads the signs they can\'t speak. Vet-ready care, in seconds.',
            style: TextStyle(
              fontSize: 14,
              color: _ink.withOpacity(0.82),
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Page 2: Auth ───────────────────────────
  Widget _buildAuthPage(Size size) {
    return SafeArea(
      child: Padding(
        // Tight horizontal padding so the brand logo can dominate the
        // viewport on the welcome page.
        padding: const EdgeInsets.fromLTRB(8, 48, 8, 280),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand mark — Pawfect logo with a gentle heartbeat pulse so
            // the welcome page feels alive instead of static.
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final t = _ambientController.value * 2 * math.pi;
                final scale = 1.0 + math.sin(t) * 0.025;
                return Transform.scale(scale: scale, child: child);
              },
              child: Image.asset(
                'assets/images/pawfect-logo.png',
                width: size.width * 0.95,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            // Eyebrow
            Text(
              "LET'S BEGIN",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.92),
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 12),
            // Title
            const Text(
              'Welcome to Pawfect',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -1.2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                "Sign up or log in to start tracking your\ncompanion's care.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _ink.withOpacity(0.78),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Page indicator ───────────────────────────
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ─────────────────────────── Continue CTA (page 0) ─────────────────
  Widget _buildContinueCTA({Key? key}) {
    final radius = BorderRadius.circular(24);
    return GestureDetector(
      key: key,
      onTap: _next,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_ink, Color(0xFF1F232E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ink.withOpacity(0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
          // Sheen
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
                            Colors.white.withOpacity(0.14),
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
        ],
      ),
    );
  }

  // ─────────────────────────── Auth buttons (page 2) ───────────────────
  Widget _buildAuthButtons({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Continue with Google — frost glass
        _glassAuthButton(
          icon: Icons.g_mobiledata_rounded,
          iconSize: 26,
          label: _isSigningIn ? 'Signing in…' : 'Continue with Google',
          onTap: _continueWithGoogle,
          loading: _isSigningIn,
        ),
        const SizedBox(height: 10),
        // Sign Up with Email — primary ink gradient
        _primaryAuthButton(
          icon: Icons.mail_outline_rounded,
          label: 'Sign Up with Email',
          onTap: _goToRegister,
        ),
        const SizedBox(height: 14),
        // Log in link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: _goToLogin,
              child: const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                  decorationThickness: 1.6,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _glassAuthButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double iconSize = 22,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.36),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
                width: 1.4,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_ink),
                    ),
                  )
                else
                  Icon(icon, size: iconSize, color: _ink),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryAuthButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(22);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_ink, Color(0xFF1F232E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ink.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
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
                            Colors.white.withOpacity(0.14),
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
        ],
      ),
    );
  }
}

// ─────────────────────────── Floating paws (ambient) ────────────────
/// Drifting paw watermarks that loop forever. They sit between the
/// gradient background and the page content, so they're always behind
/// text/buttons but on top of the gradient.
class _FloatingPaws extends StatelessWidget {
  const _FloatingPaws({required this.controller});

  final Animation<double> controller;

  // Each paw has its own base position (as fraction of the screen),
  // size, phase offset (so they're not in lock-step), drift radius,
  // base rotation, and target opacity peak.
  static const List<_PawSpec> _paws = [
    _PawSpec(left: 0.10, top: 0.18, size: 38, phase: 0.00, drift: 22, rotate: 0.40, peak: 0.22),
    _PawSpec(left: 0.78, top: 0.12, size: 30, phase: 0.30, drift: 18, rotate: -0.55, peak: 0.20),
    _PawSpec(left: 0.06, top: 0.55, size: 46, phase: 0.55, drift: 28, rotate: 0.20, peak: 0.18),
    _PawSpec(left: 0.86, top: 0.62, size: 26, phase: 0.18, drift: 16, rotate: -0.30, peak: 0.22),
    _PawSpec(left: 0.42, top: 0.06, size: 32, phase: 0.72, drift: 20, rotate: 0.55, peak: 0.18),
    _PawSpec(left: 0.58, top: 0.78, size: 40, phase: 0.88, drift: 24, rotate: -0.15, peak: 0.20),
    _PawSpec(left: 0.30, top: 0.42, size: 22, phase: 0.45, drift: 14, rotate: 0.25, peak: 0.16),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            children: _paws.map((p) {
              final t = (controller.value + p.phase) % 1.0;
              final twoPi = 2 * math.pi;
              final dy = math.sin(t * twoPi) * p.drift;
              final dx = math.cos(t * twoPi) * p.drift * 0.55;
              // Opacity breathes in and out over the loop.
              final opacity =
                  (math.sin(t * twoPi) * 0.5 + 0.5) * p.peak + 0.05;
              return Positioned(
                left: size.width * p.left + dx,
                top: size.height * p.top + dy,
                child: Transform.rotate(
                  angle: p.rotate + math.sin(t * twoPi) * 0.18,
                  child: Icon(
                    Icons.pets_rounded,
                    size: p.size,
                    color: Colors.white.withOpacity(opacity),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _PawSpec {
  final double left;   // 0..1 of screen width
  final double top;    // 0..1 of screen height
  final double size;
  final double phase;  // 0..1 phase offset along the loop
  final double drift;  // px max excursion from base position
  final double rotate; // base rotation (radians)
  final double peak;   // max opacity reached during the cycle
  const _PawSpec({
    required this.left,
    required this.top,
    required this.size,
    required this.phase,
    required this.drift,
    required this.rotate,
    required this.peak,
  });
}
