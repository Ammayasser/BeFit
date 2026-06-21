import 'package:flutter/material.dart';

import '../../core/workout_colors.dart';
import '../../data/models/should_block_result.dart';

class RecoveryBlockDialog extends StatelessWidget {
  final ShouldBlockResult blockResult;
  final VoidCallback onOverride;

  const RecoveryBlockDialog({
    super.key,
    required this.blockResult,
    required this.onOverride,
  });

  static Future<bool?> show(BuildContext context, ShouldBlockResult result) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => RecoveryBlockDialog(
        blockResult: result,
        onOverride: () {
          if (sheetCtx.mounted) {
            Navigator.of(sheetCtx).pop(true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE53E3E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recovering Muscles Targeted',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WorkoutColors.onSurface(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This workout targets muscle groups that are still heavily fatigued from recent training. We recommend resting these muscles to avoid overtraining.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WorkoutColors.onSurfaceMuted(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          if (blockResult.fatiguedMuscles.isNotEmpty)
            ...blockResult.fatiguedMuscles.map((m) {
              final name = m.muscleName
                  .split('-')
                  .map(
                    (e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1),
                  )
                  .join(' ');
              final hoursStr = m.hoursUntilReady != null
                  ? '${m.hoursUntilReady?.toStringAsFixed(1)}h'
                  : '48h';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: m.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: WorkoutColors.onSurface(context),
                        ),
                      ),
                    ),
                    Text(
                      'Needs $hoursStr',
                      style: TextStyle(
                        color: WorkoutColors.onSurfaceMuted(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (context.mounted) {
                  Navigator.of(context).pop(false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WorkoutColors.lime(context),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Find Alternative Workout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _showOverrideConfirmation(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: const Color(0xFFE53E3E),
              ),
              child: const Text('Start anyway (Not recommended)'),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverrideConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: WorkoutColors.card(context),
        title: Text(
          'Override Recovery Block?',
          style: TextStyle(color: WorkoutColors.onSurface(context)),
        ),
        content: Text(
          'Training heavily fatigued muscles increases your risk of injury and reduces overall performance. Are you sure you want to proceed?',
          style: TextStyle(color: WorkoutColors.onSurfaceMuted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onOverride();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53E3E),
            ),
            child: const Text('Yes, Start Workout'),
          ),
        ],
      ),
    );
  }
}
