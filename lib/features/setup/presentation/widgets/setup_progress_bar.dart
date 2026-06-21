import 'package:flutter/material.dart';

import '../../../../core/theme/befit_theme_extension.dart';

class SetupProgressBar extends StatelessWidget {
  final double progress;
  final int currentStep;
  final int totalSteps;

  const SetupProgressBar({
    super.key,
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    final value = progress.clamp(0.0, 1.0);

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: theme.border.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * value,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      theme.setupPrimary.withValues(alpha: 0.88),
                      theme.setupPrimary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.setupPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
