/// today_plan_card.dart
/// Shows the user's workout plan for today.
///
/// If a smart workout plan exists, displays [SmartPlanTodayCard]; otherwise
/// falls back to [QuickStartCard].
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:befit/core/router/navigation_provider.dart';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:befit/features/smart_plan/presentation/providers/smart_plan_provider.dart';
import 'package:befit/features/workout/presentation/providers/workout_hub_provider.dart';
import 'package:befit/features/workout/presentation/widgets/smart_plan_today_card.dart';
import 'package:befit/features/workout/presentation/widgets/workout_screen/quick_start_card.dart';

class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final smartPlan = context.watch<SmartPlanProvider>();
    final hubProvider = context.watch<WorkoutHubProvider>();
    
    // Show premium visual shimmer skeleton loader until both providers are fully initialized
    if (!smartPlan.isInitialized || !hubProvider.isInitialized) {
      return const _TodayPlanShimmer();
    }

    final workoutDays = smartPlan.workoutDays;
    final hasPlan = smartPlan.hasWorkoutPlan;
    
    final theme = Theme.of(context);
    final customColors = context.customColors;

    final trainedToday = hubProvider.stats.trainedToday;

    // Resolve state for header status
    Color indicatorColor = theme.colorScheme.primary;
    String statusLabel = 'ACTIVE PLAN TARGET';

    if (hasPlan && workoutDays != null) {
      final todayDay = workoutDays.firstWhere(
        (d) => d.dayIndex == DateTime.now().weekday,
        orElse: () => workoutDays.first,
      );
      final isRest = todayDay.isRestDay;

      if (trainedToday) {
        indicatorColor = customColors.success;
        statusLabel = 'WORKOUT COMPLETED';
      } else if (isRest) {
        indicatorColor = customColors.hydration;
        statusLabel = 'RECOVERY PHASE';
      } else {
        indicatorColor = customColors.calorieRing;
        statusLabel = 'DAILY WORKOUT TARGET';
      }
    } else {
      indicatorColor = theme.colorScheme.primary;
      statusLabel = 'QUICK START SESSION';
    }

    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Redesigned Section Title ---
        Padding(
          padding: EdgeInsets.only(left: 4 * s, bottom: 14 * s),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Plan",
                      style: GoogleFonts.montserrat(
                        fontSize: 18 * fs,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7 * s,
                          height: 7 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: indicatorColor,
                            boxShadow: [
                              BoxShadow(
                                color: indicatorColor.withValues(alpha: 0.6),
                                blurRadius: 6 * s,
                                spreadRadius: 1 * s,
                              ),
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.2, 1.2),
                              duration: 1200.ms,
                            )
                            .fadeIn(begin: 0.5, duration: 1200.ms),
                        SizedBox(width: 6 * s),
                        Expanded(
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.montserrat(
                              fontSize: 10 * fs,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- Plan Content Card ---
        if (hasPlan && workoutDays != null)
          SmartPlanTodayCard(
            day: workoutDays.firstWhere(
              (d) => d.dayIndex == DateTime.now().weekday,
              orElse: () => workoutDays.first,
            ),
            allDays: workoutDays,
          )
        else
          QuickStartCard(
            onTap: () => context.read<NavigationProvider>().setIndex(1), // Workout hub
          ),
      ],
    );
  }
}

class _TodayPlanShimmer extends StatelessWidget {
  const _TodayPlanShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    final baseShimmerColor = isDark 
        ? Colors.white.withValues(alpha: 0.06) 
        : Colors.black.withValues(alpha: 0.05);
    final highlightShimmerColor = isDark 
        ? Colors.white.withValues(alpha: 0.12) 
        : Colors.black.withValues(alpha: 0.08);

    Widget skeletonBlock({required double width, required double height, double radius = 8}) {
      return Container(
        width: width * s,
        height: height * s,
        decoration: BoxDecoration(
          color: baseShimmerColor,
          borderRadius: BorderRadius.circular(radius * s),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 1500.ms,
            color: highlightShimmerColor,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Redesigned Section Title (Static title, shimmering subtitle) ---
        Padding(
          padding: EdgeInsets.only(left: 4 * s, bottom: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Plan",
                style: GoogleFonts.montserrat(
                  fontSize: 18 * fs,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 7 * s,
                    height: 7 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: baseShimmerColor,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 1500.ms, color: highlightShimmerColor),
                  SizedBox(width: 6 * s),
                  skeletonBlock(width: 120, height: 10, radius: 4),
                ],
              ),
            ],
          ),
        ),

        // --- Shimmer Content Card ---
        Container(
          width: double.infinity,
          height: 250 * s,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28 * s),
            color: isDark ? const Color(0xFF0F0F10) : Colors.white,
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.04) 
                  : Colors.black.withValues(alpha: 0.04),
              width: 1.0 * s,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 20 * s,
                offset: Offset(0, 8 * s),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(22 * s),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    skeletonBlock(width: 110, height: 20, radius: 10),
                    skeletonBlock(width: 85, height: 20, radius: 10),
                  ],
                ),

                // Bottom Section: Details & Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          skeletonBlock(width: 200, height: 26, radius: 6),
                          const SizedBox(height: 8),
                          skeletonBlock(width: 150, height: 14, radius: 4),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              skeletonBlock(width: 75, height: 24, radius: 10),
                              const SizedBox(width: 8),
                              skeletonBlock(width: 80, height: 24, radius: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Action button shimmer
                    Container(
                      width: 52 * s,
                      height: 52 * s,
                      decoration: BoxDecoration(
                        color: baseShimmerColor,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .shimmer(
                          duration: 1500.ms,
                          color: highlightShimmerColor,
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

