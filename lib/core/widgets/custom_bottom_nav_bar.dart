import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

/// Floating glassmorphism bottom navigation.
///
/// Active tab: orange-gradient pill behind the icon + small accent
/// label below. Inactive tabs: dimmed icon only. Profile is rendered
/// as a circular avatar regardless of state, with an orange ring +
/// label when active.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _ink = Color(0xFF2D3142);

  // Tight finite height — required for BackdropFilter to clip cleanly.
  static const double _barHeight = 74;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset + 12,
      ),
      child: SizedBox(
        height: _barHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: _ink.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Stack(
                children: [
                  // Translucent white tint (matches LiquidAppBar opacity)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.62),
                          Colors.white.withOpacity(0.34),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 1.4,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  // Top sheen — glass surface highlight (same trick as
                  // the topbar / hero cards)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
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
                                    Colors.white.withOpacity(0.28),
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
                  // Tabs row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _IconNavItem(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          isActive: currentIndex == 0,
                          onTap: () => _handleTap(0),
                        ),
                        _IconNavItem(
                          icon: Icons.menu_book_rounded,
                          label: 'PawBook',
                          isActive: currentIndex == 1,
                          onTap: () => _handleTap(1),
                        ),
                        _IconNavItem(
                          icon: Icons.healing_rounded,
                          label: 'Detector',
                          isActive: currentIndex == 2,
                          onTap: () => _handleTap(2),
                        ),
                        _AvatarNavItem(
                          isActive: currentIndex == 3,
                          onTap: () => _handleTap(3),
                        ),
                      ],
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

  void _handleTap(int index) {
    if (currentIndex != index) {
      HapticFeedback.lightImpact();
    }
    onTap(index);
  }
}

/// Standard icon-based navigation tab.
/// Active: orange-gradient pill containing the icon + accent label below.
/// Inactive: icon only (soft ink).
class _IconNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _IconNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static const Color _inkSoft = Color(0xFF5A5F72);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Stack(
          children: [
            // Icon/pill is always centered in the same upper area, so
            // its vertical center stays put whether the item is active
            // or not — labels never push the icon around.
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.86, end: 1.0)
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: isActive
                      ? _ActivePill(
                          key: ValueKey('active-$label'),
                          icon: icon,
                        )
                      : SizedBox(
                          key: ValueKey('inactive-$label'),
                          height: 46,
                          child: Center(
                            child: Icon(
                              icon,
                              size: 32,
                              color: _inkSoft,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // Label always visible below the icon — color + weight
            // animate smoothly between inactive (soft ink) and active
            // (orange) on tab change.
            Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      isActive ? FontWeight.w800 : FontWeight.w700,
                  color: isActive
                      ? PawfectColors.pawfectOrange
                      : _inkSoft,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile/avatar tab — always renders as a circular avatar.
/// Active: avatar wrapped in orange-gradient ring + glow + accent label.
/// Inactive: subtle peach avatar with hairline ink border.
class _AvatarNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AvatarNavItem({
    required this.isActive,
    required this.onTap,
  });

  static const Color _inkSoft = Color(0xFF5A5F72);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.86, end: 1.0)
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: isActive
                      ? const _ActiveAvatarRing(key: ValueKey('active-avatar'))
                      : SizedBox(
                          key: const ValueKey('inactive-avatar'),
                          height: 46,
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: _inkSoft,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      isActive ? FontWeight.w800 : FontWeight.w700,
                  color: isActive
                      ? PawfectColors.pawfectOrange
                      : _inkSoft,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                child: const Text('Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Just the orange-glass pill with the icon — no label.
/// Label is rendered separately in the parent Stack so the icon
/// doesn't shift vertically between active/inactive states.
class _ActivePill extends StatelessWidget {
  final IconData icon;

  const _ActivePill({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final pillRadius = BorderRadius.circular(22);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                PawfectColors.pawfectOrange,
                Color(0xFFFFB347),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: pillRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: PawfectColors.pawfectOrange.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        // Top sheen — glass surface highlight
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: pillRadius,
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
                          Colors.white.withOpacity(0.34),
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
    );
  }
}

/// Active avatar — orange-glass ring with the avatar inside (no label).
/// Label is rendered separately by the parent Stack.
class _ActiveAvatarRing extends StatelessWidget {
  const _ActiveAvatarRing({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(3),
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
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: PawfectColors.pawfectOrange.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF0D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: PawfectColors.pawfectOrange,
              size: 22,
            ),
          ),
        ),
        // Top sheen — glass surface
        Positioned.fill(
          child: IgnorePointer(
            child: ClipOval(
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
                          Colors.white.withOpacity(0.32),
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
    );
  }
}

/// Alternative compact pill variant — kept for power-user toggles.
class CustomFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 12),
      child: SizedBox(
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D3142).withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.86),
                      Colors.white.withOpacity(0.66),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(4, (i) {
                      final icons = [
                        Icons.dashboard_rounded,
                        Icons.menu_book_rounded,
                        Icons.healing_rounded,
                        Icons.person_rounded,
                      ];
                      final isActive = currentIndex == i;
                      return GestureDetector(
                        onTap: () {
                          if (!isActive) HapticFeedback.lightImpact();
                          onTap(i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(
                                    colors: [
                                      PawfectColors.pawfectOrange,
                                      Color(0xFFFFB347),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: PawfectColors.pawfectOrange
                                          .withOpacity(0.42),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            icons[i],
                            size: 22,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF5A5F72),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
