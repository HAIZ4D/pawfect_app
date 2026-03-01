import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB74D),
                  Color(0xFFFFA726),
                  PawfectColors.pawfectOrange,
                ],
              ),
            ),
          ),

          // EXTRA BIG Cat Image
          Positioned(
            right: -size.width * 0.2,
            bottom: size.height * 0.05,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                height: size.height * 0.8,
                width: size.width * 0.99999,
                child: Image.asset(
                  'assets/images/cat-tabby.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ),

          // Paw decorations
          Positioned(
            top: 60,
            right: 40,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(
                Icons.pets,
                size: 50,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: 110,
            right: 100,
            child: Transform.rotate(
              angle: -0.4,
              child: Icon(
                Icons.pets,
                size: 50,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: 160,
            right: 60,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(
                Icons.pets,
                size: 50,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),

                  // BIG TEXT SECTION
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to',
                            style: PawfectTextStyles.h3.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pawfect',
                            style: PawfectTextStyles.h1.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: size.width * 0.7,
                            child: Text(
                              'Your Pet’s Perfect Health Companion',
                              style: PawfectTextStyles.bodyMedium.copyWith(
                                fontSize: 16,
                                height: 1.6,
                                color: const Color(0xFF2D3142).withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Get Started Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildGetStartedButton(context),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/home');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D3142),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "Let's GO!",
          style: PawfectTextStyles.h4.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
