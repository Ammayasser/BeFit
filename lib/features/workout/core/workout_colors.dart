import 'package:flutter/material.dart';
import '../../../core/theme/befit_theme_extension.dart';

/// Canonical palette for workout feature screens, now theme-aware.
class WorkoutColors {
  WorkoutColors._();

  // ── Theme-aware Lookups ───────────────────────────────────────────────────

  static Color scaffold(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color card(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color surfaceMuted(BuildContext context) =>
      context.customColors.surfaceMuted;
  static Color fill(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color border(BuildContext context) => context.customColors.border;

  // ── Text ───────────────────────────────────────────────────────────────────
  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color onSurfaceMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color onSurfaceSubtle(BuildContext context) =>
      Theme.of(context).disabledColor;

  // ── Brand ──────────────────────────────────────────────────────────────────
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color primaryDark(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimaryContainer;
  static Color primaryMuted(BuildContext context) =>
      context.customColors.primaryMuted;
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  // ── Legacy / Specific accents ─────────────────────────────────────────────
  static Color lime(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color limeDark(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color limeMuted(BuildContext context) => context.customColors.primaryMuted;

  // ── Workout Status ────────────────────────────────────────────────────────
  static Color warmup(BuildContext context) => context.customColors.warmup;
  static Color dropSet(BuildContext context) => context.customColors.dropSet;
  static Color failure(BuildContext context) => context.customColors.failure;

  static List<BoxShadow> cardShadow(BuildContext context) => [
    BoxShadow(
      color: Theme.of(context).brightness == Brightness.light 
          ? Colors.black.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static BoxDecoration cardDecoration(
    BuildContext context, {
    double radius = 16,
  }) => BoxDecoration(
    color: card(context),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border(context)),
    boxShadow: cardShadow(context),
  );

  static BoxDecoration fillDecoration(
    BuildContext context, {
    double radius = 12,
  }) => BoxDecoration(
    color: fill(context),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border(context)),
  );
}
