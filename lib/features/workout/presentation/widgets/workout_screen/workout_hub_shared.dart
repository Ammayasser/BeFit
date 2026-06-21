// lib/features/workout/presentation/widgets/workout_screen/workout_hub_shared.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit/core/constants/app_colors.dart';
import 'package:flutter/services.dart';

/// Design tokens for the Workout Hub components.
class WorkoutHubTokens {
  static const Color lime = Color(0xFFC0FF00);
  static const Color amber = Color(0xFFF59E0B);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color gold = Color(0xFFFFD700);
  static const Color emerald = Color(0xFF4ADE80);
  static const Color red = Color(0xFFFF4747);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);

  static const double rXL = 24;
  static const double rLG = 20;
  static const double rMD = 16;
  static const double rSM = 12;
  static const double rPill = 100;

  static List<BoxShadow> lift({
    required Color color,
    required double s,
    double cBlur = 8,
    double fBlur = 28,
    double cDy = 2,
    double fDy = 10,
  }) => [
    BoxShadow(
      color: color.withValues(alpha: 0.18),
      blurRadius: cBlur * s,
      offset: Offset(0, cDy * s),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.10),
      blurRadius: fBlur * s,
      offset: Offset(0, fDy * s),
    ),
  ];
}

/// Shared section header with title + "See all" affordance.
class WorkoutHubSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final double s;
  final double fs;

  const WorkoutHubSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 20 * fs,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSeeAll?.call();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * s,
                      vertical: 6 * s,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        WorkoutHubTokens.rPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all',
                          style: GoogleFonts.montserrat(
                            fontSize: 11 * fs,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 4 * s),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10 * s,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6 * s),
          Container(
            width: 32 * s,
            height: 3 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared micro progress bar for stats and challenges.
class WorkoutHubMicroProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double s;
  final double height;
  final bool glow;

  const WorkoutHubMicroProgressBar({
    super.key,
    required this.progress,
    required this.color,
    required this.s,
    this.height = 4,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, box) {
        final trackW = box.maxWidth;
        final fillW = trackW * clamped;

        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              Container(
                height: height * s,
                width: trackW,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.10)),
              ),
              Container(
                height: height * s,
                width: fillW,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.55), color],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: glow
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
