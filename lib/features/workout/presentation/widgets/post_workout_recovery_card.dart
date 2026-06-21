import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';

class PostWorkoutRecoveryCard extends StatefulWidget {
  final VoidCallback onDismiss;
  final List<String> justTrainedMuscles;

  const PostWorkoutRecoveryCard({
    super.key,
    required this.onDismiss,
    required this.justTrainedMuscles,
  });

  @override
  State<PostWorkoutRecoveryCard> createState() =>
      _PostWorkoutRecoveryCardState();
}

class _PostWorkoutRecoveryCardState extends State<PostWorkoutRecoveryCard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WorkoutColors.card(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: WorkoutColors.border(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Muscles Fatigued',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: WorkoutColors.onSurface(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You hit your ${widget.justTrainedMuscles.take(3).join(', ')} hard. They will need about 48 hours to fully recover and grow.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WorkoutColors.onSurfaceMuted(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WorkoutColors.lime(context),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got It',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
