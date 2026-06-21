// lib/core/utils/responsive.dart

import 'package:flutter/material.dart';

enum DeviceType { smallPhone, phone, largePhone, smallTablet, tablet, largeTablet }

class Responsive {
  Responsive._();

  // ── Device Detection ──────────────────────────────────────
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double pixelRatio(BuildContext context) =>
      MediaQuery.of(context).devicePixelRatio;

  static EdgeInsets safeArea(BuildContext context) =>
      MediaQuery.of(context).padding;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static DeviceType deviceType(BuildContext context) {
    final width = screenWidth(context);
    if (width < 375) return DeviceType.smallPhone;
    if (width < 415) return DeviceType.phone;
    if (width < 600) return DeviceType.largePhone;
    if (width < 720) return DeviceType.smallTablet;
    if (width < 1024) return DeviceType.tablet;
    return DeviceType.largeTablet;
  }

  static bool isPhone(BuildContext context) =>
      screenWidth(context) < 600;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 600;

  static bool isSmallPhone(BuildContext context) =>
      screenWidth(context) < 375;

  // ── Fluid Scaling ─────────────────────────────────────────
  // Scale a value relative to a 390px base (iPhone 14 design base)
  static double scale(BuildContext context, double value) {
    final ratio = screenWidth(context) / 390;
    return value * ratio.clamp(0.75, 1.4);
  }

  // Scale font size — tighter clamp than layout scale
  static double fontScale(BuildContext context, double value) {
    final ratio = screenWidth(context) / 390;
    return value * ratio.clamp(0.85, 1.25);
  }

  // ── Spacing ───────────────────────────────────────────────
  static double horizontalPadding(BuildContext context) {
    final type = deviceType(context);
    switch (type) {
      case DeviceType.smallPhone:   return 12;
      case DeviceType.phone:        return 16;
      case DeviceType.largePhone:   return 20;
      case DeviceType.smallTablet:  return 32;
      case DeviceType.tablet:       return 48;
      case DeviceType.largeTablet:  return 80;
    }
  }

  static double cardBorderRadius(BuildContext context) =>
      isTablet(context) ? 28 : 20;

  static double bottomNavHeight(BuildContext context) =>
      isTablet(context) ? 72 : 60;

  // ── Content Width (for tablets — cap content) ─────────────
  // Tablets should not stretch content edge to edge
  static double contentMaxWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1024) return 720;
    if (width >= 720)  return 600;
    return width;
  }

  // ── Grid Columns ──────────────────────────────────────────
  static int workoutGridColumns(BuildContext context) =>
      isTablet(context) ? 3 : 2;

  static int programGridColumns(BuildContext context) {
    final type = deviceType(context);
    if (type == DeviceType.largeTablet) return 4;
    if (type == DeviceType.tablet)      return 3;
    return 2;
  }

  // ── Font Sizes (responsive) ───────────────────────────────
  static double heroFontSize(BuildContext context) =>
      fontScale(context, isTablet(context) ? 72 : 56);

  static double titleFontSize(BuildContext context) =>
      fontScale(context, isTablet(context) ? 26 : 20);

  static double bodyFontSize(BuildContext context) =>
      fontScale(context, isTablet(context) ? 16 : 14);

  static double labelFontSize(BuildContext context) =>
      fontScale(context, 12);
}
