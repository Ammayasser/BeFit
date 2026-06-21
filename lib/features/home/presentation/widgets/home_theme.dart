library;

import 'package:flutter/material.dart';

const double kHorizontalPadding = 20.0;
const double kCardInnerPadding = 20.0;
const double kCardBorderRadius = 24.0;
const double kSectionGap = 16.0;
const double kSmallGap = 8.0;
const double kBottomNavPadding = 120.0;

const Duration kEntryDuration = Duration(milliseconds: 400);
const Duration kStaggerDelay = Duration(milliseconds: 50);
const Duration kRingAnimDuration = Duration(milliseconds: 1200);
const double kSlideYBegin = 0.03;

const int kDefaultStepsGoal = 8000;
const int kDefaultCalorieGoal = 2000;
const int kDefaultWorkoutMinutesGoal = 60;

BoxDecoration cardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(kCardBorderRadius),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFF111827).withValues(alpha: 0.05),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
        blurRadius: isDark ? 18 : 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

BoxDecoration metricTileDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(kCardBorderRadius),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFF111827).withValues(alpha: 0.05),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.03),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

String greetingForTimeOfDay() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String firstName(String displayName) {
  final raw = displayName.trim();
  if (raw.isEmpty) return 'Athlete';
  final parts = raw.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty);
  return parts.isEmpty ? 'Athlete' : parts.first;
}

String formatNumber(int n) {
  return n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

class HomeUi {
  static const borderRadius = BorderRadius.all(Radius.circular(24));

  static Color accent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
  }

  static Color accentSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  }

  static Color accentWarm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  }

  static Color pageBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF111318) : const Color(0xFFF6F8F7);
  }

  static Gradient pageGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [Color(0xFF111318), Color(0xFF17191E)]
          : const [Color(0xFFF6F8F7), Color(0xFFFFFFFF)],
    );
  }

  static Color cardBg(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color border(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF111827).withValues(alpha: 0.05);
  }

  static List<BoxShadow> premiumShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

