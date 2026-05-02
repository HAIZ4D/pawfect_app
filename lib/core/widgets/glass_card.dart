import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Liquid-glass surface used throughout Pawfect.
///
/// Wraps content in a frosted [BackdropFilter] with a translucent tint,
/// hairline highlight border, and soft drop shadow. When [onTap] is
/// supplied, the card scales down briefly and triggers a haptic on press.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;
  final double tintOpacity;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final Border? border;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.blur = 18,
    this.tint = Colors.white,
    this.tintOpacity = 0.55,
    this.onTap,
    this.shadows,
    this.border,
    this.elevated = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);

    final shadows = widget.shadows ??
        (widget.elevated
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : const <BoxShadow>[]);

    final border = widget.border ??
        Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.2,
        );

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.tint.withOpacity(
                    (widget.tintOpacity + 0.12).clamp(0.0, 1.0),
                  ),
                  widget.tint.withOpacity(
                    (widget.tintOpacity - 0.05).clamp(0.0, 1.0),
                  ),
                ],
              ),
              border: border,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    final scaled = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: card,
    );

    if (widget.onTap == null) return scaled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap!();
      },
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: scaled,
    );
  }
}

/// Tiny glass pill — used for status badges, eyebrows, tags.
/// Skips the heavy [BackdropFilter] for performance; renders a flat
/// translucent tint that reads as glass over the liquid background.
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double tintOpacity;
  final double radius;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.tint = Colors.white,
    this.tintOpacity = 0.7,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint.withOpacity(tintOpacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.55),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
