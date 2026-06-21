// lib/features/auth/presentation/widgets/auth_back_button.dart

import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';

/// A reusable, premium back button design used in auth screens.
class AuthBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const AuthBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = context.customColors;

    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44 * s,
          height: 44 * s,
          decoration: BoxDecoration(
            color: theme.setupTextPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14 * s),
            border: Border.all(color: theme.setupTextPrimary.withValues(alpha: 0.08)),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.setupTextPrimary,
            size: 18 * s,
          ),
        ),
      ),
    );
  }
}
