import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/muscle_recovery_model.dart';
import '../../core/workout_colors.dart';

class MuscleDetailSheet extends StatelessWidget {
  final MuscleRecoveryState state;

  const MuscleDetailSheet({super.key, required this.state});

  static void show(BuildContext context, MuscleRecoveryState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MuscleDetailSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recoveredPercent = (1.0 - state.fatiguePercent) * 100;
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.muscleName.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: WorkoutColors.onSurface(context),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.recoveryTier.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: state.color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text(
            'Recovery Progress: ${recoveredPercent.toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WorkoutColors.onSurfaceMuted(context),
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1.0 - state.fatiguePercent,
            backgroundColor: WorkoutColors.border(context),
            valueColor: AlwaysStoppedAnimation<Color>(state.color),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 24),

          if (state.estimatedReadyAt != null)
            _buildInfoRow(
              context, 
              'Estimated Fully Ready', 
              DateFormat('EEE, MMM d, h:mm a').format(state.estimatedReadyAt!)
            ),
          
          if (state.lastTrainedAt != null)
            _buildInfoRow(
              context, 
              'Last Trained', 
              DateFormat('EEE, MMM d, h:mm a').format(state.lastTrainedAt!)
            ),

          const SizedBox(height: 24),
          Text(
            'Recent Engagements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WorkoutColors.onSurface(context),
                ),
          ),
          const SizedBox(height: 8),
          
          if (state.recentEngagements.isEmpty)
            Text(
              'No recent training data.',
              style: TextStyle(color: WorkoutColors.onSurfaceMuted(context)),
            )
          else
            ...state.recentEngagements.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d').format(e.trainedAt),
                    style: TextStyle(color: WorkoutColors.onSurface(context)),
                  ),
                  Text(
                    '${e.setCount} sets',
                    style: TextStyle(color: WorkoutColors.onSurfaceMuted(context)),
                  ),
                ],
              ),
            )),
            
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WorkoutColors.onSurfaceMuted(context),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: WorkoutColors.onSurface(context),
                ),
          ),
        ],
      ),
    );
  }
}
