import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'text_styles.dart';

/// PawFect Official App Theme - Modern Material Design 3 🎨
/// Following the official color guidelines and modern design principles
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: PawfectColors.pawfectOrange,
      scaffoldBackgroundColor: PawfectColors.pawfectCream, // Warm cream background

      // 🎨 Color Scheme (Official PawFect Colors)
      colorScheme: const ColorScheme.light(
        primary: PawfectColors.pawfectOrange, // Orange for primary actions
        secondary: PawfectColors.pawfectCream, // Cream for secondary
        surface: PawfectColors.pawfectWhite, // White for cards/surfaces
        error: PawfectColors.error,
        onPrimary: PawfectColors.pawfectWhite, // White text on orange
        onSecondary: PawfectColors.pawfectBlack, // Black text on cream
        onSurface: PawfectColors.textPrimary, // Black text on white
        onError: PawfectColors.pawfectWhite,
        outline: PawfectColors.border, // Black at 20% opacity
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: PawfectColors.pawfectOrange,
        foregroundColor: PawfectColors.pawfectWhite,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: PawfectColors.pawfectOrange,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: PawfectColors.pawfectWhite,
        ),
        iconTheme: IconThemeData(
          color: PawfectColors.pawfectWhite,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: PawfectTextStyles.h1,
        displayMedium: PawfectTextStyles.h2,
        displaySmall: PawfectTextStyles.h3,
        headlineMedium: PawfectTextStyles.h4,
        headlineSmall: PawfectTextStyles.h5,
        titleLarge: PawfectTextStyles.h4,
        titleMedium: PawfectTextStyles.h5,
        titleSmall: PawfectTextStyles.label,
        bodyLarge: PawfectTextStyles.bodyLarge,
        bodyMedium: PawfectTextStyles.bodyMedium,
        bodySmall: PawfectTextStyles.bodySmall,
        labelLarge: PawfectTextStyles.button,
        labelMedium: PawfectTextStyles.label,
        labelSmall: PawfectTextStyles.labelSmall,
      ),

      // 🔘 Button Themes (Following official guidelines)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PawfectColors.buttonPrimary, // Orange
          foregroundColor: PawfectColors.buttonText, // White
          disabledBackgroundColor: PawfectColors.buttonDisabled, // Orange at 40%
          disabledForegroundColor: PawfectColors.textDisabled, // Black at 40%
          elevation: 2,
          shadowColor: const Color(0x26000000), // Button shadow (15% opacity)
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: PawfectTextStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PawfectColors.pawfectOrange,
          disabledForegroundColor: PawfectColors.textDisabled,
          side: const BorderSide(
            color: PawfectColors.pawfectOrange,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: PawfectTextStyles.button.copyWith(
            color: PawfectColors.pawfectOrange,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PawfectColors.pawfectOrange,
          disabledForegroundColor: PawfectColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: PawfectTextStyles.button.copyWith(
            color: PawfectColors.pawfectOrange,
          ),
        ),
      ),

      // 📝 Input Decoration Theme (White cards with borders)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PawfectColors.pawfectWhite, // White input fields
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PawfectColors.borderLight), // Light border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PawfectColors.borderLight), // Light border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PawfectColors.pawfectOrange, // Orange when focused
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PawfectColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PawfectColors.error, width: 2),
        ),
        labelStyle: PawfectTextStyles.label,
        hintStyle: PawfectTextStyles.inputHint,
        errorStyle: PawfectTextStyles.errorText,
      ),

      // 🎴 Card Theme (White cards with subtle shadow)
      cardTheme: const CardTheme(
        elevation: 2,
        shadowColor: Color(0x0D000000), // Black at 5% opacity
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: PawfectColors.pawfectWhite, // White cards
      ),

      // 🏷️ Chip Theme
      chipTheme: const ChipThemeData(
        backgroundColor: PawfectColors.pawfectCream, // Cream background
        deleteIconColor: PawfectColors.textHint,
        disabledColor: PawfectColors.textDisabled,
        selectedColor: PawfectColors.pawfectOrange, // Orange when selected
        secondarySelectedColor: Color(0x33FDA002), // Orange at 20% opacity
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: PawfectTextStyles.labelSmall,
        secondaryLabelStyle: PawfectTextStyles.labelSmall,
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // 🔘 Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: PawfectColors.pawfectOrange, // Orange FAB
        foregroundColor: PawfectColors.pawfectWhite, // White icon
        elevation: 4,
      ),

      // 📱 Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PawfectColors.pawfectWhite, // White background
        selectedItemColor: PawfectColors.pawfectOrange, // Orange when selected
        unselectedItemColor: PawfectColors.textHint, // Hint color when unselected
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: PawfectTextStyles.labelSmall,
        unselectedLabelStyle: PawfectTextStyles.labelSmall,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: PawfectColors.pawfectWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: PawfectTextStyles.h4,
        contentTextStyle: PawfectTextStyles.bodyMedium,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PawfectColors.textPrimary,
        contentTextStyle: PawfectTextStyles.bodyMedium.copyWith(
          color: PawfectColors.pawfectWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: PawfectColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: PawfectColors.textPrimary,
        size: 24,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PawfectColors.pawfectOrange,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PawfectColors.pawfectOrange;
          }
          return PawfectColors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x80FDA002); // Orange at 50% opacity
          }
          return const Color(0x40000000); // Black at 25% opacity
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PawfectColors.pawfectOrange;
          }
          return null;
        }),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PawfectColors.pawfectOrange;
          }
          return null;
        }),
      ),
    );
  }
}
