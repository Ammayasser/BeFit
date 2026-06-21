import 'muscle_recovery_model.dart';

class FullBodyRecoveryState {
  final Map<String, MuscleRecoveryState> muscles;

  const FullBodyRecoveryState({required this.muscles});

  double get overallReadinessScore {
    if (muscles.isEmpty) return 1.0;
    
    // Calculate a weighted average of readiness (1 - fatiguePercent)
    // Compound muscles (chest, back, quads, glutes, hamstrings) carry more weight.
    const compoundWeights = {
      'chest': 1.5,
      'back': 1.5,
      'quadriceps': 1.5,
      'glutes': 1.5,
      'hamstrings': 1.5,
    };
    
    double totalWeight = 0;
    double weightedReadiness = 0;
    
    for (final state in muscles.values) {
      if (state.recentEngagements.isEmpty) continue; // Skip muscles never trained

      final weight = compoundWeights[state.muscleName] ?? 1.0;
      totalWeight += weight;
      weightedReadiness += (1.0 - state.fatiguePercent) * weight;
    }
    
    if (totalWeight == 0) return 1.0;
    return (weightedReadiness / totalWeight).clamp(0.0, 1.0);
  }

  List<MuscleRecoveryState> get fatiguedMuscles {
    return muscles.values.where((m) => m.recoveryTier == RecoveryTier.fatigued).toList();
  }

  List<MuscleRecoveryState> get recoveringMuscles {
    return muscles.values.where((m) => m.recoveryTier == RecoveryTier.recovering).toList();
  }

  List<MuscleRecoveryState> get readyMuscles {
    return muscles.values.where((m) => m.recoveryTier == RecoveryTier.ready).toList();
  }

  MuscleRecoveryState? get mostRecoveredMuscle {
    if (muscles.isEmpty) return null;
    return muscles.values.reduce((a, b) => a.fatiguePercent < b.fatiguePercent ? a : b);
  }

  MuscleRecoveryState? get leastRecoveredMuscle {
    if (muscles.isEmpty) return null;
    return muscles.values.reduce((a, b) => a.fatiguePercent > b.fatiguePercent ? a : b);
  }
}
