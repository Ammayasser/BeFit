import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'victory_colors.dart';
import 'victory_particle_burst.dart';

class VictoryPrCard extends StatelessWidget {
  final String exerciseName;
  final String prDetail;
  final Duration delay;

  const VictoryPrCard({
    super.key,
    required this.exerciseName,
    required this.prDetail,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Particle Burst Trigger
        Positioned(
          left: -50, // Center relative to the card's left edge
          top: -150,
          width: 400,
          height: 400,
          child: IgnorePointer(
            child: const ParticleBurstWidget(center: Offset(200, 200))
                .animate(delay: delay + 400.ms)
                .fadeIn(),
          ),
        ),

        // The Card
        Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VictoryColors.backgroundCard.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VictoryColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: VictoryColors.gold.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: VictoryColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'PERSONAL RECORD',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: VictoryColors.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exerciseName,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prDetail,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: VictoryColors.textSecondary,
                ),
              ),
            ],
          ),
        )
            .animate(delay: delay)
            .slideX(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
            .fadeIn(duration: 400.ms),
      ],
    );
  }
}
