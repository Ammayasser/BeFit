// lib/features/nutrition/presentation/widgets/nutrition_ui_utils.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'nutrition_colors.dart';

class NutritionUi {
  static void showSuccessSnackBar(BuildContext context, String message, {Duration? duration}) {
    _showLuxurySnackBar(
      context: context,
      message: message,
      icon: Iconsax.tick_circle,
      color: NColors.accentPrimary(context),
      duration: duration,
    );
  }

  static void showErrorSnackBar(BuildContext context, String message, {Duration? duration}) {
    _showLuxurySnackBar(
      context: context,
      message: message,
      icon: Iconsax.info_circle,
      color: Colors.redAccent,
      duration: duration,
    );
  }

  static void showInfoSnackBar(BuildContext context, String message, {SnackBarAction? action, IconData? icon, Color? color, Duration? duration}) {
    _showLuxurySnackBar(
      context: context,
      message: message,
      icon: icon ?? Iconsax.info_circle,
      color: color ?? Colors.blueAccent,
      action: action,
      duration: duration,
    );
  }

  static void _showLuxurySnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Color? color,
    SnackBarAction? action,
    Duration? duration,
  }) {
    final s = MediaQuery.of(context).size.width / 390;
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color ?? Colors.white, size: 20 * s),
              SizedBox(width: 12 * s),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.montserrat(
                  fontSize: 14 * s,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF111827).withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 20 * s),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18 * s),
          side: BorderSide(
            color: (color ?? Colors.white).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        duration: duration ?? const Duration(milliseconds: 1000),
        action: action,
      ),
    );
  }
}
