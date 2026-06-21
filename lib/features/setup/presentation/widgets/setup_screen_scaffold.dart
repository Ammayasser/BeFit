import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/content_wrapper.dart';
import 'setup_progress_bar.dart';

class SetupScreenScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget body;
  final String primaryButtonLabel;
  final VoidCallback? onPrimaryButtonPressed;
  final bool isPrimaryButtonEnabled;
  final Widget? headerTrailing;
  final Widget? bottomHelper;

  const SetupScreenScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.primaryButtonLabel,
    required this.onPrimaryButtonPressed,
    this.isPrimaryButtonEnabled = true,
    this.headerTrailing,
    this.bottomHelper,
  });

  bool get _hasSubtitle => subtitle.trim().isNotEmpty;
  bool get _hasEyebrow => eyebrow.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    final s = Responsive.scale(context, 1);

    return Scaffold(
      backgroundColor: theme.setupBg,
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.setupBg,
                  Color.lerp(theme.setupBg, theme.bgSecondary, 0.2) ??
                      theme.setupBg,
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _AccentGlow(
              color: theme.setupPrimary.withValues(alpha: 0.16),
              size: 240,
            ),
          ),
          Positioned(
            top: 140,
            left: -100,
            child: _AccentGlow(
              color: theme.setupPrimary.withValues(alpha: 0.08),
              size: 220,
            ),
          ),
          SafeArea(
            child: ContentWrapper(
              addHorizontalPadding: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8 * s),
                    Row(
                      children: [
                        _HeaderButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: onBack,
                        ),
                        const Spacer(),
                        headerTrailing ??
                            _StepBadge(
                              currentStep: currentStep,
                              totalSteps: totalSteps,
                            ),
                      ],
                    ),
                    SizedBox(height: 18 * s),
                    SetupProgressBar(
                      progress: currentStep / totalSteps,
                      currentStep: currentStep,
                      totalSteps: totalSteps,
                    ),
                    SizedBox(height: 24 * s),
                    if (_hasEyebrow) ...[
                      Text(
                        eyebrow,
                        style: GoogleFonts.montserrat(
                          fontSize: Responsive.fontScale(context, 12),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: theme.setupPrimary,
                        ),
                      ),
                      SizedBox(height: 12 * s),
                    ],
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: Responsive.fontScale(context, 33),
                        fontWeight: FontWeight.w800,
                        height: 1.02,
                        letterSpacing: -1.2,
                        color: theme.setupTextPrimary,
                      ),
                    ),
                    if (_hasSubtitle) ...[
                      SizedBox(height: 10 * s),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: Responsive.fontScale(context, 14),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: theme.setupTextSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: 24 * s),
                    Expanded(child: body),
                    if (bottomHelper != null) ...[
                      SizedBox(height: 14 * s),
                      bottomHelper!,
                    ],
                    SizedBox(height: 16 * s),
                    SizedBox(
                      width: double.infinity,
                      height: 58 * s,
                      child: ElevatedButton(
                        onPressed: isPrimaryButtonEnabled
                            ? onPrimaryButtonPressed
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.setupPrimary,
                          foregroundColor: theme.setupOnPrimary,
                          disabledBackgroundColor: theme.setupPrimary
                              .withValues(alpha: 0.28),
                          disabledForegroundColor: theme.setupOnPrimary
                              .withValues(alpha: 0.5),
                          elevation: isPrimaryButtonEnabled ? 10 : 0,
                          shadowColor: theme.setupPrimary.withValues(
                            alpha: 0.28,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          primaryButtonLabel,
                          style: GoogleFonts.montserrat(
                            fontSize: Responsive.fontScale(context, 16),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18 * s),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SetupInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const SetupInfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.setupCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.setupPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: theme.setupTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.setupCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: theme.setupTextPrimary, size: 18),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepBadge({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.setupPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.setupPrimary.withValues(alpha: 0.16)),
      ),
      child: Text(
        '$currentStep/$totalSteps',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: theme.setupPrimary,
        ),
      ),
    );
  }
}

class _AccentGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AccentGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
