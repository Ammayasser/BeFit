// lib/features/auth/presentation/widgets/auth_submit_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';

/// A professional CTA button designed for auth submit actions.
///
/// Features:
/// - Connects to the custom `BeFitThemeExtension`.
/// - Supports scale-on-press animation.
/// - Incorporates loading state.
/// - Incorporates medium impact haptic feedback on successful press.
class AuthSubmitButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onSubmit;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<AuthSubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onSubmit != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    if (widget.onSubmit != null && !widget.isLoading) {
      HapticFeedback.mediumImpact();
      widget.onSubmit!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = context.customColors;
    final isEnabled = widget.onSubmit != null;

    return Semantics(
      button: true,
      enabled: isEnabled && !widget.isLoading,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: double.infinity,
            height: 56 * s,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isEnabled
                    ? theme.setupPrimary
                    : theme.setupPrimary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: widget.isLoading
                  ? SizedBox(
                      height: 24 * s,
                      width: 24 * s,
                      child: CircularProgressIndicator(
                        color: theme.setupOnPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: GoogleFonts.montserrat(
                        color: theme.setupOnPrimary,
                        fontSize: Responsive.fontScale(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
