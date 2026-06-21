// lib/features/workout/presentation/widgets/workout_discovery_widgets.dart

import 'dart:ui';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/fitbod_workout_model.dart';
import '../../data/models/muscle_recovery_model.dart';
import '../providers/workout_hub_provider.dart';
import '../screens/fitbod_workout_detail_screen.dart';
import '../widgets/workout_cover_image.dart';

class WorkoutDiscoverySection extends StatelessWidget {
  final String title;
  final List<FitbodWorkout> workouts;

  const WorkoutDiscoverySection({
    super.key,
    required this.title,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) return const SizedBox.shrink();
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 22 * s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 20 * fs,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.workoutDiscover);
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.montserrat(
                    fontSize: 13 * fs,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * s),
        SizedBox(
          height: 300 * s,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 22 * s),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) =>
                DiscoveryWorkoutCard(workout: workouts[index]),
            separatorBuilder: (context, index) => SizedBox(width: 16 * s),
            itemCount: workouts.length,
          ),
        ),
      ],
    );
  }
}

class DiscoveryWorkoutCard extends StatelessWidget {
  final FitbodWorkout workout;

  const DiscoveryWorkoutCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    final duration = (workout.exercises.length * 7).clamp(20, 90);
    final difficulty = workout.difficulty;

    // Check recovery state
    final hubProvider = context.watch<WorkoutHubProvider>();
    final blockResult = hubProvider.shouldBlockWorkout(workout);
    final hasFatigued = blockResult.shouldBlock;
    
    // Also check recovering
    bool hasRecovering = false;
    if (!hasFatigued && hubProvider.stats.fullBodyRecoveryState != null) {
      for (final m in workout.primaryMuscles) {
        final state = hubProvider.stats.fullBodyRecoveryState!.muscles[m.toLowerCase().trim()];
        if (state != null && state.recoveryTier == RecoveryTier.recovering) {
          hasRecovering = true;
          break;
        }
      }
    }

    final hasRecoveryBadge = hasFatigued || hasRecovering;
    final badgeColor = hasFatigued ? const Color(0xFFE53E3E) : const Color(0xFFECC94B);

    return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FitbodWorkoutDetailScreen(workout: workout),
              ),
            );
          },
          child: Container(
            width: 350 * s,
            height: 300 * s,
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceCard : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(36 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
                  blurRadius: 20 * s,
                  offset: Offset(0, 10 * s),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36 * s),
              child: Stack(
                children: [
                  // Trainer Image Background
                  Positioned.fill(
                    child: WorkoutCoverImage(
                      imageUrl: workout.imageUrls.isNotEmpty
                          ? workout.imageUrls.first
                          : null,
                      workoutRouteId: workout.id,
                      muscleGroup: workout.primaryMuscles.isNotEmpty
                          ? workout.primaryMuscles.first
                          : 'Full Body',
                      overlayOpacity: 0.3,
                      borderRadius: BorderRadius.circular(36 * s),
                    ),
                  ),

                  if (hasRecoveryBadge)
                    Positioned(
                      top: 16 * s,
                      right: 16 * s,
                      child: Container(
                        width: 14 * s,
                        height: 14 * s,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withValues(alpha: 0.5),
                              blurRadius: 8 * s,
                              spreadRadius: 2 * s,
                            )
                          ],
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(24 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Glassy Label
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8 * s),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * s,
                                vertical: 4 * s,
                              ),
                              color: Colors.white.withValues(alpha: 0.1),
                              child: Text(
                                'PREMIUM WORKOUT',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10 * fs,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(
                                    0xFFC0FF00,
                                  ).withValues(alpha: 0.9),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12 * s),
                        SizedBox(
                          width: 250 * s,
                          child: Text(
                            workout.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 28 * fs,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 16 * s),

                        // Metadata Row
                        Row(
                          children: [
                            _MetaItem(
                              icon: Iconsax.clock,
                              label: '$duration min',
                              iconColor: const Color(0xFFC0FF00),
                              s: s,
                              fs: fs,
                            ),
                            _MetaDivider(s: s),
                            _MetaItem(
                              icon: Iconsax.flash_1,
                              label: difficulty,
                              iconColor: Colors.white,
                              s: s,
                              fs: fs,
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Start Workout Button Style (Static because it's a card)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20 * s),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 60 * s,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20 * s),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 20 * s),
                                  Text(
                                    'EXPLORE PLAN',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14 * fs,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 44 * s,
                                    height: 44 * s,
                                    margin: EdgeInsets.only(right: 8 * s),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC0FF00),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.black,
                                      size: 24 * s,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final double s;
  final double fs;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14 * s, color: iconColor),
        SizedBox(width: 6 * s),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12 * fs,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  final double s;

  const _MetaDivider({required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10 * s),
      child: Transform.rotate(
        angle: 0.785, // 45 degrees for diamond
        child: Container(
          width: 3 * s,
          height: 3 * s,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
