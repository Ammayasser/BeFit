// lib/features/workout/presentation/widgets/workout_screen/challenge_hub_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:befit/core/utils/responsive.dart';
import '../../../data/models/workout_hub_stats.dart';
import 'workout_hub_shared.dart';

class ChallengeHubCard extends StatelessWidget {
  final List<DynamicChallenge> challenges;

  const ChallengeHubCard({super.key, required this.challenges});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) return const SizedBox.shrink();

    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final challenge = challenges.first;
    final pct = (challenge.percent * 100).toInt();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rXL * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rXL * s),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [WorkoutHubTokens.slate800, WorkoutHubTokens.slate900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -30 * s,
              right: -30 * s,
              child: Container(
                width: 140 * s,
                height: 140 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [WorkoutHubTokens.gold.withValues(alpha: 0.14), WorkoutHubTokens.gold.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40 * s,
              left: -40 * s,
              child: Container(
                width: 120 * s,
                height: 120 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [WorkoutHubTokens.violet.withValues(alpha: 0.06), WorkoutHubTokens.violet.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(WorkoutHubTokens.rXL * s),
                  border: Border.all(color: WorkoutHubTokens.gold.withValues(alpha: 0.08), width: 1),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(22 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * s),
                        decoration: BoxDecoration(
                          color: WorkoutHubTokens.gold.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: WorkoutHubTokens.gold.withValues(alpha: 0.18), blurRadius: 12)],
                        ),
                        child: Icon(Iconsax.award, color: WorkoutHubTokens.gold, size: 20 * s),
                      ),
                      SizedBox(width: 12 * s),
                      Text(
                        'Monthly Challenge',
                        style: GoogleFonts.montserrat(fontSize: 13 * fs, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.3),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                        decoration: BoxDecoration(
                          color: WorkoutHubTokens.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(WorkoutHubTokens.rPill),
                          border: Border.all(color: WorkoutHubTokens.gold.withValues(alpha: 0.22), width: 0.5),
                        ),
                        child: Text(
                          '$pct%',
                          style: GoogleFonts.montserrat(fontSize: 11 * fs, fontWeight: FontWeight.w800, color: WorkoutHubTokens.gold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18 * s),
                  Text(
                    challenge.title,
                    style: GoogleFonts.montserrat(fontSize: 22 * s, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 6 * s),
                  Text(
                    challenge.subtitle,
                    style: GoogleFonts.montserrat(fontSize: 13 * fs, fontWeight: FontWeight.w600, color: Colors.white38, height: 1.4),
                  ),
                  SizedBox(height: 22 * s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${challenge.progress.toInt()} / ${challenge.target.toInt()} Workouts',
                        style: GoogleFonts.montserrat(fontSize: 11 * fs, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.2),
                      ),
                      Text(
                        '$pct% Complete',
                        style: GoogleFonts.montserrat(fontSize: 11 * fs, fontWeight: FontWeight.w800, color: WorkoutHubTokens.gold, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * s),
                  WorkoutHubMicroProgressBar(progress: challenge.percent.clamp(0.0, 1.0), color: WorkoutHubTokens.gold, s: s, height: 6, glow: true),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
    .slideY(begin: 0.04, end: 0.0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
