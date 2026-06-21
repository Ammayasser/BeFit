import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Colors ───────────────────────────────────────────
  static const Color primaryGreen    = Color(0xFF7CA794); // Muted sage green
  static const Color textBlack       = Color(0xFF1E1E1E); // Dark black

  // ── Backgrounds ────────────────────────────────────────────
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundDark  = Color(0xFF17191E); // Updated to Midnight Charcoal Scaffold

  // ── Setup Flow (Light Theme) ───────────────────────────────
  static const Color setupBackground    = Color(0xFFE8F5E9);
  static const Color setupPrimaryDark   = Color(0xFF1B5E20);
  static const Color setupTextPrimary   = Color(0xFF0D2B12);
  static const Color setupTextSecondary = Color(0xFF757575);

  // ── Surfaces (dark theme) ──────────────────────────────────
  static const Color background      = Color(0xFF111318);
  static const Color surfaceCard     = Color(0xFF21242B);
  static const Color surfaceElevated = Color(0xFF2B2F3A);
  static const Color surfaceBorder   = Color(0xFF353A47);

  // ── Midnight Charcoal Palette (Dark Theme) ──────────────────
  static const Color darkBgPrimary      = Color(0xFF111318);
  static const Color darkBgSecondary    = Color(0xFF17191E);
  static const Color darkSurfaceCard    = Color(0xFF21242B);
  static const Color darkSurfaceElevated= Color(0xFF2B2F3A);
  static const Color darkBorder         = Color(0xFF353A47);
  static const Color darkPrimaryAccent  = Color(0xFF4ADE80);
  static const Color darkSecondaryAccent= Color(0xFF22C55E);
  static const Color darkTextPrimary    = Color(0xFFFFFFFF);
  static const Color darkTextSecondary  = Color(0xFFA0A3AB);
  static const Color darkTextMuted      = Color(0xFF6B6E76);

  // ── Primary Variants ───────────────────────────────────────
  static const Color primary         = Color(0xFF7CA794);
  static const Color primaryDark     = Color(0xFF5E8A78);
  static const Color primaryGlow     = Color(0x267CA794);

  // ── Accent Colors ──────────────────────────────────────────
  static const Color accentPurple    = Color(0xFF7C6FA0);
  static const Color accentOrange    = Color(0xFFD4845A);
  static const Color accentBlue      = Color(0xFF5A8FA8);
  static const Color accentRed       = Color(0xFFBF5B5B);

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFFFFFFFF);
  static const Color textSecondary   = Color(0xFF8A8A8A);
  static const Color textTertiary    = Color(0xFF4A4A4A);

  // ── Difficulty ─────────────────────────────────────────────
  static const Color diffBeginner    = Color(0xFF7CA794);
  static const Color diffIntermediate= Color(0xFFD4845A);
  static const Color diffAdvanced    = Color(0xFFBF5B5B);

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7CA794), Color(0xFF5E8A78)],
  );

  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 1.0],
    colors: [
      Color(0x00000000),
      Color(0x55000000),
      Color(0xF2121212),
    ],
  );

  // ── Chat ───────────────────────────────────────────────────
  static const Color bubbleUser    = Color(0xFFCBE0D0); // Light green from design
  static const Color surface       = Color(0xFFF3F4F6); // Light grey AI bubble
  static const Color textBody      = Color(0xFF1E1E1E); // Black text for bubbles
  static const Color surfaceGreen  = Color(0xFFF0F9F4); // Very light green for cards
  static const Color success       = Color(0xFF4AAB5B); // Vibrant green for buttons/icons
  static const Color textMeta      = Color(0xFF9CA3AF); // Grey timestamp text
  static const Color errorBright   = Color(0xFFEF4444); // Red

  // ── Nutrition Feature UI Colors ─────────────────────────────
  static const Color nutPrimary    = Color(0xFF3FAE2A); // Primary Green
  static const Color nutDark       = Color(0xFF1B5E20); // Dark Green
  static const Color nutBackground = Color(0xFFF5F7F4); // Very soft off-white/greenish
  static const Color nutCardBg     = Color(0xFFFFFFFF); // Card Background
  static const Color nutTextMain   = Color(0xFF1B5E20); // Main Titles (Dark Green)
  static const Color nutTextBody   = Color(0xFF757575); // Body Text
  static const Color nutProtein    = Color(0xFF3FAE2A); // Green
  static const Color nutCarbs      = Color(0xFF2196F3); // Blue
  static const Color nutFats       = Color(0xFFFF9800); // Orange
}
