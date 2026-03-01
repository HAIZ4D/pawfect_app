import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/colors.dart';

/// Beautiful AI loading animation with pulsing circles and rotating gradient
class AILoadingAnimation extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<LoadingStep> steps;

  const AILoadingAnimation({
    super.key,
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  @override
  State<AILoadingAnimation> createState() => _AILoadingAnimationState();
}

class _AILoadingAnimationState extends State<AILoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    // Rotation animation for outer circle
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Pulse animation for circles
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Wave animation for background
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Auto-progress through steps
    _startStepProgress();
  }

  void _startStepProgress() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _currentStep < widget.steps.length - 1) {
        setState(() => _currentStep++);
        _startStepProgress();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PawfectColors.pawfectCream,
            Colors.orange.shade50,
            PawfectColors.pawfectCream,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated wave background
          _buildWaveBackground(),

          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated loading circles
                    _buildAnimatedCircles(),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Progress steps
                    _buildStepsList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            animation: _waveController.value,
            color: PawfectColors.pawfectOrange.withOpacity(0.05),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedCircles() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating gradient circle
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        PawfectColors.pawfectOrange.withOpacity(0.1),
                        PawfectColors.pawfectOrange.withOpacity(0.5),
                        PawfectColors.pawfectOrange.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Middle pulsing circle
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.2);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        PawfectColors.pawfectOrange.withOpacity(0.3),
                        PawfectColors.pawfectOrange.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner solid circle with icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final opacity = 0.8 + (_pulseController.value * 0.2);
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PawfectColors.pawfectOrange.withOpacity(opacity),
                      PawfectColors.pawfectOrange.withOpacity(opacity - 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PawfectColors.pawfectOrange.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 50,
                ),
              );
            },
          ),

          // Orbiting small circles
          ..._buildOrbitingCircles(),
        ],
      ),
    );
  }

  List<Widget> _buildOrbitingCircles() {
    return List.generate(3, (index) {
      final angle = (index * 2 * math.pi / 3);
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          final currentAngle = angle + (_rotationController.value * 2 * math.pi);
          final x = math.cos(currentAngle) * 90;
          final y = math.sin(currentAngle) * 90;

          return Transform.translate(
            offset: Offset(x, y),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PawfectColors.pawfectOrange,
                boxShadow: [
                  BoxShadow(
                    color: PawfectColors.pawfectOrange.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildStepsList() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: widget.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final isPending = index > _currentStep;

          return _buildStepItem(
            step: step,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isPending: isPending,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepItem({
    required LoadingStep step,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
  }) {
    IconData iconData;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      iconData = Icons.check_circle;
      iconColor = PawfectColors.success;
      textColor = Colors.black87;
    } else if (isCurrent) {
      iconData = Icons.autorenew;
      iconColor = PawfectColors.pawfectOrange;
      textColor = Colors.black87;
    } else {
      iconData = Icons.circle_outlined;
      iconColor = Colors.grey[400]!;
      textColor = Colors.grey[500]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.0, end: isCurrent ? 1.0 : 0.0),
        builder: (context, value, child) {
          return Row(
            children: [
              // Icon with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? iconColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: isCurrent
                    ? RotationTransition(
                        turns: _rotationController,
                        child: Icon(iconData, color: iconColor, size: 20),
                      )
                    : Icon(iconData, color: iconColor, size: 20),
              ),

              const SizedBox(width: 16),

              // Text with emoji
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Row(
                    children: [
                      if (step.emoji.isNotEmpty) ...[
                        Text(step.emoji),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: Text(step.text)),
                    ],
                  ),
                ),
              ),

              // Progress indicator for current step
              if (isCurrent) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Wave painter for background animation
class WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  WavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    for (var i = 0; i < 3; i++) {
      final yOffset = size.height * (0.3 + i * 0.2);
      final amplitude = 30.0 + (i * 10);
      final frequency = 0.02 - (i * 0.005);
      final phase = animation * 2 * math.pi + (i * math.pi / 3);

      path.reset();
      path.moveTo(0, yOffset);

      for (var x = 0.0; x <= size.width; x += 5) {
        final y = yOffset + math.sin((x * frequency) + phase) * amplitude;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Model for loading steps
class LoadingStep {
  final String emoji;
  final String text;

  const LoadingStep({
    required this.emoji,
    required this.text,
  });
}
