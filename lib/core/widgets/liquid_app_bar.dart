import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Frosted glass app bar — sibling to [CustomAppBar].
///
/// Use with `Scaffold(extendBodyBehindAppBar: true)` so the
/// [LiquidBackground] orbs render beneath and the [BackdropFilter]
/// blurs them into a colourful frost strip.
class LiquidAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final bool showBackButton;

  const LiquidAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.62),
                Colors.white.withOpacity(0.34),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.55),
                width: 1,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (showBackButton)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
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
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF2D3142),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      _BrandGlyph(icon: icon),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3142),
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5A5F72),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PawfectColors.pawfectOrange.withOpacity(0.65),
                          PawfectColors.pawfectOrange.withOpacity(0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandGlyph extends StatelessWidget {
  final IconData icon;
  const _BrandGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
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
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: PawfectColors.pawfectOrange.withOpacity(0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}
