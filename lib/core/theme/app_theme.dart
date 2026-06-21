import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_typography.dart';
import 'befit_theme_extension.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme Constants ──────────────────────────────────────────────────
  static const Color _lightBgPrimary = Color(0xFFF8FAFB);
  static const Color _lightBgSecondary = Color(0xFFFFFFFF);
  static const Color _lightOnSurface = Color(0xFF1A1D1C);
  static const Color _lightOnSurfaceVariant = Color(0xFF5C6560);
  static const Color _lightOnSurfaceMuted = Color(0xFF8A938E);
  static const Color _lightBorder = Color(0xFFDCE3DE);
  static const Color _lightDivider = Color(0xFFE2E8E4);

  // ── Dark Theme Constants (Midnight Charcoal) ──────────────────────────────
  static const Color _darkBgPrimary = Color(0xFF111318);      // Deep Midnight
  static const Color _darkBgSecondary = Color(0xFF17191E);    // Midnight Scaffold
  static const Color _darkSurfaceCard = Color(0xFF21242B);    // Subtle Surface
  static const Color _darkSurfaceElevated = Color(0xFF2B2F3A); // Elevated Surface
  static const Color _darkBorder = Color(0xFF353A47);         // Definition Border
  static const Color _darkTextPrimary = Color(0xFFFFFFFF);    // High Contrast White
  static const Color _darkTextSecondary = Color(0xFFA0A3AB);  // Soft Gray-Blue
  static const Color _darkTextMuted = Color(0xFF6B6E76);      // Dim Gray
  static const Color _darkPrimaryAccent = Color(0xFF4ADE80);  // Vibrant Green
  static const Color _darkSecondaryAccent = Color(0xFF22C55E);

  // ── Typography ─────────────────────────────────────────────────────────────

  static TextTheme _beFitTextTheme(Color textColor, Color secondaryColor, Color mutedColor) {
    final base = AppTypography.buildTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: textColor),
      displayMedium: base.displayMedium?.copyWith(color: textColor),
      displaySmall: base.displaySmall?.copyWith(color: textColor),
      headlineLarge: base.headlineLarge?.copyWith(color: textColor),
      headlineMedium: base.headlineMedium?.copyWith(color: textColor),
      headlineSmall: base.headlineSmall?.copyWith(color: textColor),
      titleLarge: base.titleLarge?.copyWith(color: textColor),
      titleMedium: base.titleMedium?.copyWith(color: textColor),
      titleSmall: base.titleSmall?.copyWith(color: textColor),
      bodyLarge: base.bodyLarge?.copyWith(color: textColor),
      bodyMedium: base.bodyMedium?.copyWith(color: textColor),
      bodySmall: base.bodySmall?.copyWith(color: secondaryColor),
      labelLarge: base.labelLarge?.copyWith(color: textColor),
      labelMedium: base.labelMedium?.copyWith(color: secondaryColor),
      labelSmall: base.labelSmall?.copyWith(color: mutedColor),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accentPurple,
        onSecondary: Colors.white,
        surface: _lightBgSecondary,
        onSurface: _lightOnSurface,
        surfaceContainerHighest: Color(0xFFEEF1EF),
        onSurfaceVariant: _lightOnSurfaceVariant,
        outline: _lightBorder,
        outlineVariant: _lightDivider,
        error: AppColors.accentRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _lightBgPrimary,
      textTheme: _beFitTextTheme(_lightOnSurface, _lightOnSurfaceVariant, _lightOnSurfaceMuted),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          color: _lightOnSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _lightOnSurface, size: 24),
      ),

      cardTheme: CardThemeData(
        color: _lightBgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEF1EF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightBgSecondary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: _lightOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(color: _lightDivider, thickness: 1, space: 1),
      
      extensions: [BeFitThemeExtension.light],
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryAccent,
        onPrimary: _darkBgSecondary,
        secondary: _darkSecondaryAccent,
        onSecondary: _darkBgSecondary,
        surface: _darkSurfaceCard,
        onSurface: _darkTextPrimary,
        surfaceContainerHighest: _darkSurfaceElevated,
        onSurfaceVariant: _darkTextSecondary,
        outline: _darkBorder,
        outlineVariant: _darkBorder,
        error: Color(0xFFF87171),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _darkBgSecondary,
      textTheme: _beFitTextTheme(_darkTextPrimary, _darkTextSecondary, _darkTextMuted),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          color: _darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _darkTextPrimary, size: 24),
      ),

      cardTheme: CardThemeData(
        color: _darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryAccent,
          foregroundColor: _darkBgPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkPrimaryAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurfaceCard,
        selectedItemColor: _darkPrimaryAccent,
        unselectedItemColor: _darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1, space: 1),

      extensions: [BeFitThemeExtension.dark],
    );
  }
}
