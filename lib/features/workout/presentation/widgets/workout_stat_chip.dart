import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';

class WorkoutStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const WorkoutStatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? WorkoutColors.onSurfaceMuted(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: WorkoutColors.fillDecoration(context, radius: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: activeColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WorkoutColors.onSurface(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
