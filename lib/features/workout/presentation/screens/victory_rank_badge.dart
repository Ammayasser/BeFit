import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'victory_colors.dart';

enum WorkoutRank { S, A, B }

class VictoryRankBadge extends StatelessWidget {
  final WorkoutRank rank;
  final String label;

  const VictoryRankBadge({
    super.key,
    required this.rank,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    switch (rank) {
      case WorkoutRank.S: rankColor = VictoryColors.rankS; break;
      case WorkoutRank.A: rankColor = VictoryColors.rankA; break;
      case WorkoutRank.B: rankColor = VictoryColors.rankB; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: rankColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rank.name,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: rankColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: rankColor.withValues(alpha: 0.3)),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: rankColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
