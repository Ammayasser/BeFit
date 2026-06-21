import 'package:flutter/material.dart';
import '../../../../core/theme/befit_theme_extension.dart';

/// Nutrition feature specific color palette
/// Now theme-aware using BeFitThemeExtension
class NColors {
  NColors._();

  // ── Backgrounds ────────────────────────────────────────────
  static Color bgPrimary(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color bgSecondary(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color bgElevated(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;

  // ── Accents ────────────────────────────────────────────────
  static Color accentPrimary(BuildContext context) => context.customColors.calorieRing;
  static Color accentSecondary(BuildContext context) => context.customColors.protein;
  static Color warningAccent(BuildContext context) => context.customColors.carbs;
  static Color dangerAccent(BuildContext context) => context.customColors.fat;
  static Color hydration(BuildContext context) => context.customColors.hydration;
  static const Color purple = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF06B6D4);

  // ── Text ───────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textTertiary(BuildContext context) => Theme.of(context).disabledColor;

  // ── Misc ───────────────────────────────────────────────────
  static Color divider(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;

  // ── Gradients ──────────────────────────────────────────────
  static LinearGradient calorieRingGradient(BuildContext context) => LinearGradient(
    colors: [accentPrimary(context), context.customColors.hydration],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Meal Colors (Toned down for visual comfort) ────────
  static Color mealColor(BuildContext context, String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFF0D9488); // Teal
      case 'lunch':
        return const Color(0xFF4F46E5); // Indigo
      case 'dinner':
        return const Color(0xFF9333EA); // Purple
      case 'snacks':
        return const Color(0xFFEA580C); // Orange
      default:
        return accentPrimary(context);
    }
  }

  // ── NutriScore Colors ──────────────────────────────────────
  static Color nutriScoreColor(BuildContext context, String? grade) {
    switch (grade?.toLowerCase()) {
      case 'a':
        return const Color(0xFF1A9E3F);
      case 'b':
        return const Color(0xFF56B947);
      case 'c':
        return const Color(0xFFF5D200);
      case 'd':
        return const Color(0xFFE77825);
      case 'e':
        return const Color(0xFFE63E11);
      default:
        return textTertiary(context);
    }
  }

  // ── Border Radius ──────────────────────────────────────────
  static const double radiusCard = 20.0;
  static const double radiusChip = 12.0;
  static const double radiusButton = 14.0;
  static const double radiusInput = 16.0;
  static const double radiusModal = 28.0;

  // ── Spacing ────────────────────────────────────────────────
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;

  // ── Shadows ────────────────────────────────────────────────
  static List<BoxShadow> cardGlow(BuildContext context, [Color? color]) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> activeCardGlow(BuildContext context, [Color? color]) => [
    BoxShadow(
      color: (color ?? accentPrimary(context)).withValues(alpha: 0.12),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];
}
