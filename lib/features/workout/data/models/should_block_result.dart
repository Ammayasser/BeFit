import 'muscle_recovery_model.dart';

class ShouldBlockResult {
  final bool shouldBlock;
  final List<MuscleRecoveryState> fatiguedMuscles;

  const ShouldBlockResult({
    required this.shouldBlock,
    this.fatiguedMuscles = const [],
  });
}
