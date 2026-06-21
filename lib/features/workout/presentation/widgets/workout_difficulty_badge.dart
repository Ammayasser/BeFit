import 'package:flutter/material.dart';

class WorkoutDifficultyBadge extends StatelessWidget {
  final String? difficulty;

  const WorkoutDifficultyBadge({
    super.key,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    if (difficulty == null || difficulty!.isEmpty) return const SizedBox.shrink();

    final clean = difficulty!.trim().toLowerCase();
    Color bg;
    Color text;

    if (clean.contains('begin') || clean == 'novice') {
      bg = Colors.green.withValues(alpha: 0.12);
      text = Colors.green[700]!;
    } else if (clean.contains('intermed')) {
      bg = Colors.orange.withValues(alpha: 0.12);
      text = Colors.orange[800]!;
    } else {
      bg = Colors.red.withValues(alpha: 0.12);
      text = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty!.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
