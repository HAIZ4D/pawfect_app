import 'package:flutter/material.dart';

/// PawFect Official Color Theme - Modern & Beautiful 🐾
/// Brand Feel: Friendly, Warm & Caring, Trustworthy, Energetic & Playful
class PawfectColors {
  // 🎨 OFFICIAL BRAND COLORS

  /// 🧡 Primary Color (Brand / Action) - Orange
  /// Use for: Primary buttons, Highlights, Icons, Active states
  static const Color pawfectOrange = Color(0xFFFDA002);

  /// 🤍 Background Color (Main UI) - Warm Cream
  /// Use for: App background, Screens & sections, Soft containers
  static const Color pawfectCream = Color(0xFFFFF4DB);

  /// ⚫ Text & Contrast - Black
  /// Use for: Headings, Important labels, Primary text
  static const Color pawfectBlack = Colors.black;

  /// ⚪ Neutral / Cards - White
  /// Use for: Cards, Modals, Input fields, Bottom sheets
  static const Color pawfectWhite = Colors.white;

  // 📝 TEXT HIERARCHY

  /// Primary text - Full black
  static const Color textPrimary = pawfectBlack;

  /// Body text - Black at 80% opacity
  static const Color textBody = Color(0xCC000000); // 80% opacity

  /// Hint/Secondary text - Black at 50% opacity
  static const Color textHint = Color(0x80000000); // 50% opacity

  /// Disabled text - Black at 40% opacity
  static const Color textDisabled = Color(0x66000000); // 40% opacity

  // 🎯 BUTTON STATES

  /// Primary button background
  static const Color buttonPrimary = pawfectOrange;

  /// Primary button text
  static const Color buttonText = pawfectWhite;

  /// Disabled button - Orange at 40% opacity
  static const Color buttonDisabled = Color(0x66FDA002); // 40% opacity

  // ✅ STATUS COLORS (Complementary to theme)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // 🚨 URGENCY LEVEL COLORS (For illness detection)
  static const Color urgencyLow = Color(0xFF4CAF50);
  static const Color urgencyModerate = Color(0xFFFF9800);
  static const Color urgencyHigh = Color(0xFFFF5722);
  static const Color urgencyEmergency = Color(0xFFE53935);

  // 🎨 GRADIENTS

  /// Primary gradient for backgrounds and headers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pawfectOrange, Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft cream gradient for subtle backgrounds
  static const LinearGradient creamGradient = LinearGradient(
    colors: [pawfectCream, Color(0xFFFFF8E7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // 🌑 SHADOWS (Black with opacity as per modern design)

  /// Card shadow - Black at 5-10% opacity
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0D000000), // ~5% opacity
    blurRadius: 8,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  /// Elevated shadow for floating elements
  static const BoxShadow elevatedShadow = BoxShadow(
    color: Color(0x1A000000), // ~10% opacity
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  /// Button shadow for depth
  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x26000000), // ~15% opacity
    blurRadius: 8,
    offset: Offset(0, 3),
    spreadRadius: 0,
  );

  // 🎯 DIVIDERS
  static const Color divider = Color(0x1A000000); // Black at 10% opacity

  // 🔲 BORDERS
  static const Color border = Color(0x33000000); // Black at 20% opacity
  static const Color borderLight = Color(0x1A000000); // Black at 10% opacity

  // 🧊 LIQUID GLASS TOKENS
  /// Glass surfaces sit on top of the LiquidBackground orbs. These
  /// tokens are the standard tint/border/shadow values used by GlassCard
  /// and the screens that compose with it.
  static const Color frostHigh = Color(0xB3FFFFFF); // 70% white — primary
  static const Color frostMid = Color(0x99FFFFFF); // 60% white — secondary
  static const Color frostLow = Color(0x66FFFFFF); // 40% white — pills/chips
  static const Color frostBorder = Color(0x99FFFFFF); // 60% white border
  static const Color frostStroke = Color(0x4DFFFFFF); // 30% inner highlight
  static const Color frostShadow = Color(0x14000000); // soft drop shadow

  /// Premium ink tokens (dark text + hero gradients on glass screens)
  static const Color ink = Color(0xFF2D3142);
  static const Color inkSoft = Color(0xFF5A5F72);
  static const Color hairline = Color(0x14000000);

  /// Premium pastel accents (used by hero badges and orb tints)
  static const Color peach = Color(0xFFFFEAD5);
  static const Color mint = Color(0xFFD9F2E6);
  static const Color sky = Color(0xFFDCE9FF);
  static const Color rose = Color(0xFFFFDCE3);
}
