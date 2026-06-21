// lib/core/widgets/responsive_layout.dart

import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return phone;
  }
}
