// lib/features/workout/presentation/widgets/workout_screen/netflix_workout_section.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:befit/core/utils/responsive.dart';
import '../../../data/models/fitbod_workout_model.dart';
import '../../screens/fitbod_workout_detail_screen.dart';
import '../workout_cover_image.dart';
import 'workout_hub_shared.dart';

class NetflixWorkoutSection extends StatelessWidget {
  final String title;
  final List<FitbodWorkout> workouts;
  final String userGender;
  final bool isLarge;
  final VoidCallback? onSeeAll;

  const NetflixWorkoutSection({
    super.key,
    required this.title,
    required this.workouts,
    required this.userGender,
    this.isLarge = false,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final isSmallScreen = size.height < 700;

    final cardHeight = isLarge
        ? (isSmallScreen ? 280.0 : 310.0) * s
        : (isSmallScreen ? 230.0 : 255.0) * s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkoutHubSectionHeader(title: title, onSeeAll: onSeeAll, s: s, fs: fs),
        SizedBox(height: 16 * s),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 22 * s),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: workouts.length,
            separatorBuilder: (_, _) => SizedBox(width: 14 * s),
            itemBuilder: (context, index) => _WorkoutPoster(
              workout: workouts[index],
              userGender: userGender,
              isLarge: isLarge,
              cardHeight: cardHeight,
              s: s,
              fs: fs,
              animDelay: (index * 70).ms,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutPoster extends StatelessWidget {
  final FitbodWorkout workout;
  final String userGender;
  final bool isLarge;
  final double cardHeight;
  final double s;
  final double fs;
  final Duration animDelay;

  const _WorkoutPoster({
    required this.workout,
    required this.userGender,
    required this.isLarge,
    required this.cardHeight,
    required this.s,
    required this.fs,
    required this.animDelay,
  });

  int get _minutes => (workout.exercises.length * 7).clamp(20, 90);
  int get _exCount => workout.exercises.length;

  Color _diffColor() {
    switch (workout.difficulty.toLowerCase()) {
      case 'beginner':
        return WorkoutHubTokens.emerald;
      case 'advanced':
      case 'expert':
        return WorkoutHubTokens.red;
      default:
        return WorkoutHubTokens.lime;
    }
  }

  String get _muscleTag {
    if (workout.primaryMuscles.isNotEmpty) {
      return workout.primaryMuscles
          .take(2)
          .map((m) => m.toUpperCase())
          .join(' · ');
    }
    return 'FULL BODY';
  }

  @override
  Widget build(BuildContext context) {
    final cardW = (isLarge ? 260.0 : 190.0) * s;
    final dc = _diffColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        width: cardW,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WorkoutHubTokens.rXL * s),
          boxShadow: WorkoutHubTokens.lift(
            color: isDark ? Colors.black : Colors.black87,
            s: s,
            cBlur: 12,
            fBlur: 32,
            cDy: 4,
            fDy: 14,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WorkoutHubTokens.rXL * s),
          child: Stack(
            fit: StackFit.expand,
            children: [
              WorkoutCoverImage(
                imageUrl: workout.imageUrls.isNotEmpty ? workout.imageUrls.first : null,
                workoutRouteId: workout.id,
                muscleGroup: workout.primaryMuscles.isNotEmpty ? workout.primaryMuscles.first : 'Full Body',
                gender: userGender,
                overlayOpacity: 0.12,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.22, 0.48, 0.72, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.48),
                        Colors.black.withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14 * s,
                left: 14 * s,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(WorkoutHubTokens.rSM * s),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                      decoration: BoxDecoration(
                        color: dc.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(WorkoutHubTokens.rSM * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5 * s,
                            height: 5 * s,
                            decoration: BoxDecoration(
                              color: dc,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: dc.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 5 * s),
                          Text(
                            workout.difficulty.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 8 * fs,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.88),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14 * s,
                right: 14 * s,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(WorkoutHubTokens.rSM * s),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(WorkoutHubTokens.rSM * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.hierarchy_3, color: Colors.white54, size: 9 * s),
                          SizedBox(width: 4 * s),
                          Text(
                            '$_exCount ex',
                            style: GoogleFonts.montserrat(
                              fontSize: 8 * fs,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.65),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10 * s,
                left: 10 * s,
                right: 10 * s,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(WorkoutHubTokens.rMD * s),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 10 * s, 12 * s),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.10),
                        borderRadius: BorderRadius.circular(WorkoutHubTokens.rMD * s),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _muscleTag,
                            style: GoogleFonts.montserrat(
                              fontSize: 8 * fs,
                              fontWeight: FontWeight.w700,
                              color: WorkoutHubTokens.lime,
                              letterSpacing: 1.0,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5 * s),
                          Text(
                            workout.name,
                            style: GoogleFonts.montserrat(
                              fontSize: (isLarge ? 16.0 : 13.5) * fs,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10 * s),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _StatChip(icon: Iconsax.clock, label: '$_minutes min', s: s, fs: fs),
                              SizedBox(width: 6 * s),
                              _StatChip(icon: Iconsax.hierarchy_3, label: '$_exCount', s: s, fs: fs),
                              const Spacer(),
                              Container(
                                width: 30 * s,
                                height: 30 * s,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: WorkoutHubTokens.lime,
                                  boxShadow: [
                                    BoxShadow(
                                      color: WorkoutHubTokens.lime.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 14 * s),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.5 * s,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [dc.withValues(alpha: 0.0), dc.withValues(alpha: 0.7), dc.withValues(alpha: 0.0)],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate(delay: animDelay)
    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
    .slideY(begin: 0.06, end: 0.0, duration: 400.ms, curve: Curves.easeOutCubic)
    .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.0, 1.0), duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double s;
  final double fs;

  const _StatChip({required this.icon, required this.label, required this.s, required this.fs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 10 * s),
          SizedBox(width: 4 * s),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9 * fs,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.82),
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}
