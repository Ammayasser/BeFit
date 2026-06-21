// lib/core/constants/app_shadows.dart

import 'package:flutter/material.dart';

/// Centralized shadow definitions used across the entire app.
/// Eliminates repeated BoxShadow lists in widget files.
class AppShadows {
  AppShadows._();

  /// Standard card shadow — subtle depth for cards on surfaces.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  /// Elevated card shadow — for floating elements.
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Glow shadow — colored glow used for selected/active states.
  static List<BoxShadow> glow(Color color, {double opacity = 0.2}) => [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ];

  /// Subtle shadow — minimal depth for small elements.
  static List<BoxShadow> get subtle => [
        const BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];
}
// ✓ Enhanced: Extracted all repeated BoxShadow definitions into shared constants
