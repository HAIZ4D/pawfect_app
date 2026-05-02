import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Saturated pastel-orb canvas that sits beneath every glass surface.
///
/// The blobs and brand paw provide the colour the [BackdropFilter] of
/// each [GlassCard] blurs to produce the liquid-glass look. Wrapped in
/// [RepaintBoundary] so the static layer doesn't repaint when scroll
/// listeners or animated cards rebuild above it.
class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key, this.density = 1.0});

  /// Multiplier for orb opacity. Drop to ~0.7 on screens that already
  /// have a strong hero gradient.
  final double density;

  static const _peach = Color(0xFFFFEAD5);
  static const _mint = Color(0xFFD9F2E6);
  static const _sky = Color(0xFFDCE9FF);
  static const _rose = Color(0xFFFFDCE3);

  double _o(double base) => (base * density).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
              // Brand paw, top-right — Pawfect signature
              Positioned(
                top: -40,
                right: -50,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Icon(
                    Icons.pets_rounded,
                    size: 220,
                    color: PawfectColors.pawfectOrange.withOpacity(_o(0.18)),
                  ),
                ),
              ),
              // Top-left peach halo
              Positioned(
                top: -80,
                left: -90,
                child: _orb(260, _peach.withOpacity(_o(0.85))),
              ),
              // Mid-left mint pool
              Positioned(
                top: 280,
                left: -110,
                child: _orb(220, _mint.withOpacity(_o(0.7))),
              ),
              // Mid-right rose puff
              Positioned(
                top: 360,
                right: -80,
                child: _orb(180, _rose.withOpacity(_o(0.6))),
              ),
              // Bottom-right sky depth
              Positioned(
                bottom: -110,
                right: -60,
                child: _orb(260, _sky.withOpacity(_o(0.75))),
              ),
              // Bottom-left peach echo
              Positioned(
                bottom: 200,
                left: -60,
                child: _orb(150, _peach.withOpacity(_o(0.55))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
