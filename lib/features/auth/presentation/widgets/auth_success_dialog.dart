// lib/features/auth/presentation/widgets/auth_success_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';

/// A premium, animated success dialog shown upon account registration.
///
/// Features:
/// - Smooth progress bar simulation.
/// - Elastic spring animations for the check icon.
/// - Handles routing redirect to `AppRoutes.planGeneration` upon completion.
class AuthSuccessDialog extends StatefulWidget {
  final String userName;

  const AuthSuccessDialog({
    super.key,
    required this.userName,
  });

  /// Displays the dialog within the provided [context].
  static void show(BuildContext context, String userName) {
    final theme = context.customColors;
    final s = Responsive.scale(context, 1);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "SuccessDialog",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (dialogContext, anim1, anim2) {
        return AlertDialog(
          backgroundColor: theme.setupBg,
          surfaceTintColor: Colors.transparent,
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28 * s),
            side: BorderSide(
              color: theme.setupTextPrimary.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 24 * s,
            vertical: 36 * s,
          ),
          content: AuthSuccessDialog(userName: userName),
        );
      },
      transitionBuilder: (transitionContext, anim1, anim2, child) {
        final curveValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.8 + (curveValue * 0.2),
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AuthSuccessDialog> createState() => _AuthSuccessDialogState();
}

class _AuthSuccessDialogState extends State<AuthSuccessDialog> {
  double _progress = 0.0;
  Timer? _progressTimer;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    
    const totalDuration = Duration(milliseconds: 2500);
    const interval = Duration(milliseconds: 50);
    final totalSteps = totalDuration.inMilliseconds / interval.inMilliseconds;
    
    _progressTimer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 1.0 / totalSteps;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
        }
      });
    });

    _navigationTimer = Timer(totalDuration, () {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss dialog
        context.go(AppRoutes.planGeneration); // Redirect
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    final s = Responsive.scale(context, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium success icon
        Container(
          width: 96 * s,
          height: 96 * s,
          decoration: BoxDecoration(
            color: theme.setupPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 72 * s,
            height: 72 * s,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.setupPrimary,
                  theme.setupPrimary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.setupPrimary.withValues(alpha: 0.35),
                  blurRadius: 18 * s,
                  offset: Offset(0, 8 * s),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_rounded,
              color: theme.setupOnPrimary,
              size: 40 * s,
            ),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ).rotate(
            begin: -0.5,
            end: 0,
            duration: 700.ms,
            curve: Curves.elasticOut,
          ),
        ),
        SizedBox(height: 28 * s),

        // Welcome Title
        Text(
          "Welcome, ${widget.userName}!",
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: theme.setupTextPrimary,
            fontSize: 22 * s,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),
        SizedBox(height: 10 * s),

        // Description text
        Text(
          "Your account has been created successfully. Preparing your workout dashboard...",
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: theme.setupTextSecondary,
            fontSize: 14 * s,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),
        SizedBox(height: 32 * s),

        // Custom animated loading progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10 * s),
          child: SizedBox(
            height: 6 * s,
            width: double.infinity,
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: theme.setupTextPrimary.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(theme.setupPrimary),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        SizedBox(height: 12 * s),
        Text(
          "Initializing...",
          style: GoogleFonts.montserrat(
            color: theme.setupTextSecondary.withValues(alpha: 0.6),
            fontSize: 12 * s,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
      ],
    );
  }
}
