// lib/features/auth/presentation/widgets/auth_error_banner.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';

/// A premium, dismissible error banner that displays authentication errors.
///
/// Features:
/// - Smooth fade and slide animation upon appearance.
/// - Designed to be fully accessible with Semantics.
/// - Consumes standard custom theme tokens for correct error background and icon colors.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = context.customColors;

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Error: $message',
      child: Container(
        margin: EdgeInsets.only(bottom: 24 * s),
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
        decoration: BoxDecoration(
          color: theme.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: theme.error.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8 * s),
              decoration: BoxDecoration(
                color: theme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: theme.error,
                size: 20 * s,
              ),
            ),
            SizedBox(width: 14 * s),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.montserrat(
                  color: theme.error,
                  fontSize: Responsive.fontScale(context, 13),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Dismiss error',
              child: IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.error.withValues(alpha: 0.5),
                  size: 20 * s,
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .slideY(begin: -0.15, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
    );
  }
}