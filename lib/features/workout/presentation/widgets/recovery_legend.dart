import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';

class RecoveryLegend extends StatelessWidget {
  const RecoveryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(context, const Color(0xFFE53E3E), 'Needs 48h'),
          _buildLegendItem(context, const Color(0xFFECC94B), 'Recovering'),
          _buildLegendItem(context, const Color(0xFF48BB78), 'Ready'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WorkoutColors.onSurface(context),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
