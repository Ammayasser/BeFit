// lib/features/auth/presentation/widgets/password_strength_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';

enum PasswordStrengthLevel { weak, fair, good, strong }

/// An animated strength bar that evaluates password strength and displays a visual indicator.
class PasswordStrengthBar extends StatelessWidget {
  /// The current password value to evaluate.
  final String password;

  const PasswordStrengthBar({
    super.key,
    required this.password,
  });

  /// Evaluates [password] and returns a tuple (strength, label, level).
  static (double, String, PasswordStrengthLevel?) evaluate(String password) {
    if (password.isEmpty) {
      return (0.0, '', null);
    }

    double strength = 0;
    // Length checks
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 10) strength += 0.2;
    // Character checks
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;

    strength = strength.clamp(0.0, 1.0);

    if (strength <= 0.4) {
      return (strength, 'Weak', PasswordStrengthLevel.weak);
    } else if (strength <= 0.6) {
      return (strength, 'Fair', PasswordStrengthLevel.fair);
    } else if (strength <= 0.8) {
      return (strength, 'Good', PasswordStrengthLevel.good);
    } else {
      return (strength, 'Strong', PasswordStrengthLevel.strong);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final s = Responsive.scale(context, 1);
    final customColors = context.customColors;

    final (strength, label, level) = evaluate(password);

    Color color;
    switch (level) {
      case PasswordStrengthLevel.weak:
        color = customColors.error;
        break;
      case PasswordStrengthLevel.fair:
        color = customColors.warmup;
        break;
      case PasswordStrengthLevel.good:
        color = customColors.carbs;
        break;
      case PasswordStrengthLevel.strong:
        color = customColors.success;
        break;
      default:
        color = Colors.transparent;
    }

    return Padding(
      padding: EdgeInsets.only(top: 8 * s),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4 * s),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: strength),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: customColors.border.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5 * s,
                ),
              ),
            ),
          ),
          SizedBox(width: 10 * s),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: Responsive.fontScale(context, 11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}