import 'package:flutter/material.dart';
import 'colors.dart';

/// PawFect Official Text Styles - Modern & Clean Typography 📝
/// Following the official text hierarchy guidelines
class PawfectTextStyles {
  // 🎯 HEADINGS (Primary Black - Full opacity)

  /// H1 - Large display text
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: PawfectColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// H2 - Section headers
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: PawfectColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// H3 - Subsection headers
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: PawfectColors.textPrimary,
    height: 1.3,
    letterSpacing: 0,
  );

  /// H4 - Card titles
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: PawfectColors.textPrimary,
    height: 1.4,
    letterSpacing: 0,
  );

  /// H5 - Small titles
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: PawfectColors.textPrimary,
    height: 1.4,
    letterSpacing: 0,
  );

  // 📖 BODY TEXT (Black at 80% opacity)

  /// Body Large - Primary content
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textBody,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Body Medium - Standard content
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textBody,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Body Small - Secondary content
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textBody,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // 🔘 BUTTON TEXT (White on Orange)

  /// Primary button text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: PawfectColors.buttonText,
    letterSpacing: 0.5,
  );

  /// Small button text
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: PawfectColors.buttonText,
    letterSpacing: 0.5,
  );

  // 💬 HINT TEXT (Black at 50% opacity)

  /// Hint/Secondary text
  static const TextStyle hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textHint,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Small hint text
  static const TextStyle hintSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textHint,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // 🏷️ LABELS

  /// Standard label
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: PawfectColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Small label
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: PawfectColors.textBody,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // 📝 INPUT FIELDS

  /// Input field text
  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Input hint/placeholder text
  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textHint,
    height: 1.5,
    letterSpacing: 0.15,
  );

  // 🎯 SPECIAL STYLES

  /// Caption text for small labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: PawfectColors.textHint,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Link/Clickable text
  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: PawfectColors.pawfectOrange,
    decoration: TextDecoration.underline,
    decorationColor: PawfectColors.pawfectOrange,
    letterSpacing: 0.1,
  );

  /// Error message text
  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: PawfectColors.error,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Success message text
  static const TextStyle successText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: PawfectColors.success,
    height: 1.4,
    letterSpacing: 0.1,
  );
}
