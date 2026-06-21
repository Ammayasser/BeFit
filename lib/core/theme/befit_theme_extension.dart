import 'package:flutter/material.dart';

class BeFitThemeExtension extends ThemeExtension<BeFitThemeExtension> {
  // Backgrounds & Surfaces
  final Color bgPrimary;
  final Color bgSecondary;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color border;

  // Status Colors
  final Color primaryMuted;
  final Color success;
  final Color warning;
  final Color error;

  // Workout Specific
  final Color warmup;
  final Color dropSet;
  final Color failure;

  // Nutrition colors
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color hydration;
  final Color calorieRing;

  // Setup Flow colors
  final Color setupBg;
  final Color setupPrimary;
  final Color setupOnPrimary;
  final Color setupCard;
  final Color setupTextPrimary;
  final Color setupTextSecondary;

  // Chart Colors
  final Color chartGridLine;
  final Color chartLabel;

  BeFitThemeExtension({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.border,
    required this.primaryMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.warmup,
    required this.dropSet,
    required this.failure,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.hydration,
    required this.calorieRing,
    required this.setupBg,
    required this.setupPrimary,
    required this.setupOnPrimary,
    required this.setupCard,
    required this.setupTextPrimary,
    required this.setupTextSecondary,
    required this.chartGridLine,
    required this.chartLabel,
  });

  @override
  ThemeExtension<BeFitThemeExtension> copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? border,
    Color? primaryMuted,
    Color? success,
    Color? warning,
    Color? error,
    Color? warmup,
    Color? dropSet,
    Color? failure,
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? hydration,
    Color? calorieRing,
    Color? setupBg,
    Color? setupPrimary,
    Color? setupOnPrimary,
    Color? setupCard,
    Color? setupTextPrimary,
    Color? setupTextSecondary,
    Color? chartGridLine,
    Color? chartLabel,
  }) {
    return BeFitThemeExtension(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      warmup: warmup ?? this.warmup,
      dropSet: dropSet ?? this.dropSet,
      failure: failure ?? this.failure,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      hydration: hydration ?? this.hydration,
      calorieRing: calorieRing ?? this.calorieRing,
      setupBg: setupBg ?? this.setupBg,
      setupPrimary: setupPrimary ?? this.setupPrimary,
      setupOnPrimary: setupOnPrimary ?? this.setupOnPrimary,
      setupCard: setupCard ?? this.setupCard,
      setupTextPrimary: setupTextPrimary ?? this.setupTextPrimary,
      setupTextSecondary: setupTextSecondary ?? this.setupTextSecondary,
      chartGridLine: chartGridLine ?? this.chartGridLine,
      chartLabel: chartLabel ?? this.chartLabel,
    );
  }

  @override
  ThemeExtension<BeFitThemeExtension> lerp(
    ThemeExtension<BeFitThemeExtension>? other,
    double t,
  ) {
    if (other is! BeFitThemeExtension) {
      return this;
    }
    return BeFitThemeExtension(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      warmup: Color.lerp(warmup, other.warmup, t)!,
      dropSet: Color.lerp(dropSet, other.dropSet, t)!,
      failure: Color.lerp(failure, other.failure, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      hydration: Color.lerp(hydration, other.hydration, t)!,
      calorieRing: Color.lerp(calorieRing, other.calorieRing, t)!,
      setupBg: Color.lerp(setupBg, other.setupBg, t)!,
      setupPrimary: Color.lerp(setupPrimary, other.setupPrimary, t)!,
      setupOnPrimary: Color.lerp(setupOnPrimary, other.setupOnPrimary, t)!,
      setupCard: Color.lerp(setupCard, other.setupCard, t)!,
      setupTextPrimary: Color.lerp(
        setupTextPrimary,
        other.setupTextPrimary,
        t,
      )!,
      setupTextSecondary: Color.lerp(
        setupTextSecondary,
        other.setupTextSecondary,
        t,
      )!,
      chartGridLine: Color.lerp(chartGridLine, other.chartGridLine, t)!,
      chartLabel: Color.lerp(chartLabel, other.chartLabel, t)!,
    );
  }

  static BeFitThemeExtension get light => BeFitThemeExtension(
    bgPrimary: const Color(0xFFF8FAFB),
    bgSecondary: const Color(0xFFFFFFFF),
    surfaceCard: const Color(0xFFFFFFFF),
    surfaceElevated: const Color(0xFFEEF1EF),
    surfaceMuted: const Color(0xFFF1F5F2),
    border: const Color(0xFFDCE3DE),
    primaryMuted: const Color(0xFFE8F0EC),
    success: const Color(0xFF10B981),
    warning: const Color(0xFFF59E0B),
    error: const Color(0xFFEF4444),
    warmup: const Color(0xFFEA580C),
    dropSet: const Color(0xFF9333EA),
    failure: const Color(0xFFDC2626),
    protein: const Color(0xFF3B82F6),
    carbs: const Color(0xFFF59E0B),
    fat: const Color(0xFFEF4444),
    hydration: const Color(0xFF06B6D4),
    calorieRing: const Color(0xFF22C55E),
    setupBg: const Color(0xFFF7FBF8),
    setupPrimary: const Color(0xFF16A34A),
    setupOnPrimary: Colors.white,
    setupCard: Colors.white,
    setupTextPrimary: const Color(0xFF111827),
    setupTextSecondary: const Color(0xFF4B6354),
    chartGridLine: const Color(0xFFE2E8E4),
    chartLabel: const Color(0xFF8A938E),
  );

  static BeFitThemeExtension get dark => BeFitThemeExtension(
    bgPrimary: const Color(0xFF17191E), // Scaffold
    bgSecondary: const Color(0xFF111318), // Main background
    surfaceCard: const Color(0xFF21242B),
    surfaceElevated: const Color(0xFF2B2F3A),
    surfaceMuted: const Color(0xFF1C1F26),
    border: const Color(0xFF353A47),
    primaryMuted: const Color(0xFF21242B),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFF87171),
    warmup: const Color(0xFFEA580C),
    dropSet: const Color(0xFF9333EA),
    failure: const Color(0xFFDC2626),
    protein: const Color(0xFF60A5FA),
    carbs: const Color(0xFFFBBF24),
    fat: const Color(0xFFF87171),
    hydration: const Color(0xFF22D3EE),
    calorieRing: const Color(0xFF4ADE80),
    setupBg: const Color(0xFF17191E),
    setupPrimary: const Color(0xFF4ADE80),
    setupOnPrimary: const Color(0xFF17191E),
    setupCard: const Color(0xFF21242B),
    setupTextPrimary: const Color(0xFFFFFFFF),
    setupTextSecondary: const Color(0xFFA0A3AB),
    chartGridLine: const Color(0xFF353A47),
    chartLabel: const Color(0xFF6B6E76),
  );
}

extension BeFitThemeExtensionHelper on BuildContext {
  BeFitThemeExtension get customColors =>
      Theme.of(this).extension<BeFitThemeExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? BeFitThemeExtension.dark
          : BeFitThemeExtension.light);
}
