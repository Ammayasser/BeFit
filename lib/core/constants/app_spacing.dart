// lib/core/constants/app_spacing.dart

import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Centralized spacing constants used across the entire app.
/// Eliminates magic numbers for padding, margin, and gap values.
class AppSpacing {
  AppSpacing._();

  // Static constants (for non-context situations)
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;

  /// Standard horizontal screen padding.
  static const double screenH = 24;

  /// Standard bottom nav clearance.
  static const double navClearance = 100;

  // Responsive spacing (scales with screen)
  static double r(BuildContext context, double value) =>
      Responsive.scale(context, value);

  // Responsive SizedBox helpers
  static Widget vGap(BuildContext context, double value) =>
      SizedBox(height: r(context, value));

  static Widget hGap(BuildContext context, double value) =>
      SizedBox(width: r(context, value));

  // Responsive EdgeInsets helpers
  static EdgeInsets all(BuildContext context, double value) =>
      EdgeInsets.all(r(context, value));

  static EdgeInsets symmetric(BuildContext context, {
    double vertical = 0,
    double horizontal = 0,
  }) => EdgeInsets.symmetric(
    vertical: r(context, vertical),
    horizontal: r(context, horizontal),
  );

  static EdgeInsets only(BuildContext context, {
    double top = 0, double bottom = 0,
    double left = 0, double right = 0,
  }) => EdgeInsets.only(
    top: r(context, top), bottom: r(context, bottom),
    left: r(context, left), right: r(context, right),
  );

  // Screen-aware page padding
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: Responsive.horizontalPadding(context),
    vertical: r(context, 16),
  );
}
