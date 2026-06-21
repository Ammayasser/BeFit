// lib/core/constants/app_decorations.dart

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shadows.dart';

/// Centralized BoxDecoration presets used across the app.
/// Replaces repeated inline BoxDecoration definitions.
class AppDecorations {
  AppDecorations._();

  /// Standard surface card — used for most list/section cards.
  static BoxDecoration surfaceCard({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: AppShadows.card,
      );

  /// Elevated card — for floating modals and action sheets.
  static BoxDecoration elevatedCard({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: AppShadows.elevated,
      );

  /// Gradient card — for hero/stats cards with gradient backgrounds.
  static BoxDecoration gradientCard(LinearGradient gradient) => BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.elevated,
      );

  /// Light-mode card — used in profile, setup, and edit screens.
  static BoxDecoration lightCard({double radius = 16}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      );

  /// Selected option card — used in setup selection screens.
  static BoxDecoration selectedCard({
    required bool isSelected,
    Color selectedColor = AppColors.primary,
    double radius = 24,
  }) =>
      BoxDecoration(
        color: isSelected
            ? selectedColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isSelected
              ? selectedColor
              : AppColors.setupTextSecondary.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? AppShadows.glow(selectedColor) : AppShadows.subtle,
      );
}
// ✓ Enhanced: Extracted all repeated BoxDecoration patterns into shared presets
