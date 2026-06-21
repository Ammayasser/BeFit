import 'dart:math' as math;
import '../models/muscle_engagement_model.dart';
import '../models/muscle_recovery_model.dart';
import '../models/full_body_recovery_model.dart';

class RecoveryEngine {
  static const double _baseFatigueRate = 0.15;
  static const double _baseDecayRate = 0.0578; // 48h to ~6%
  
  static const List<String> _trackedMuscles = [
    'chest', 'back', 'biceps', 'triceps', 'shoulders', 
    'quadriceps', 'hamstrings', 'calves', 'glutes', 'abs',
    'lower-back', 'trapezius', 'forearms', 'abductors', 'adductors'
  ];

  static FullBodyRecoveryState computeRecovery(List<MuscleEngagementEntry> engagements) {
    final Map<String, MuscleRecoveryState> states = {};
    final now = DateTime.now();

    for (final muscle in _trackedMuscles) {
      final muscleEngagements = engagements.where((e) => e.muscleName == muscle).toList();
      muscleEngagements.sort((a, b) => b.trainedAt.compareTo(a.trainedAt)); // Newest first

      double cumulativeFatigue = 0.0;
      double lastVol = 0.0;
      DateTime? lastTrained;

      for (final entry in muscleEngagements) {
        // Assume intensityScore is roughly the stimulus or we compute it:
        // entry.intensityScore was supposed to be: Volume * MET * compound_multiplier / 1000. 
        // If not computed, we approximate it here.
        double stimulus = entry.intensityScore > 0 ? entry.intensityScore : (entry.totalVolume / 1000.0);
        if (stimulus <= 0) stimulus = 1.0; // Minimal baseline if no volume but logged

        double initialFatigue = math.min(1.0, stimulus * _baseFatigueRate);
        double decayRate = _baseDecayRate;
        
        if (stimulus > 6.0) {
          decayRate *= 0.8; // Reduce decay rate by 20% for high volume
        }

        final hoursSince = now.difference(entry.trainedAt).inMinutes / 60.0;
        if (hoursSince < 0) continue; // Future data shouldn't happen, ignore

        final fatigue = initialFatigue * math.exp(-decayRate * hoursSince);
        cumulativeFatigue += fatigue;

        if (lastTrained == null) {
          lastTrained = entry.trainedAt;
          lastVol = entry.totalVolume;
        }
      }

      cumulativeFatigue = math.min(1.0, cumulativeFatigue);
      
      RecoveryTier tier = RecoveryTier.ready;
      if (cumulativeFatigue > 0.6) {
        tier = RecoveryTier.fatigued;
      } else if (cumulativeFatigue > 0.2) {
        tier = RecoveryTier.recovering;
      }

      DateTime? estimatedReadyAt;
      DateTime? estimatedRecoveringAt;
      double? hoursUntilReady;

      if (cumulativeFatigue > 0.2 && lastTrained != null) {
        // Approximate time until fatigue hits 0.2
        // currentFatigue = initialFatigue * exp(-decay * hours) -> hours = -ln(target / initialFatigue) / decay
        // Since it's cumulative, we just use the base decay from current fatigue as a simplification
        double hReady = -math.log(0.2 / math.max(0.2001, cumulativeFatigue)) / _baseDecayRate;
        if (hReady > 0) {
          hoursUntilReady = hReady;
          estimatedReadyAt = now.add(Duration(minutes: (hReady * 60).toInt()));
        }
        
        if (cumulativeFatigue > 0.6) {
          double hRecovering = -math.log(0.6 / cumulativeFatigue) / _baseDecayRate;
          estimatedRecoveringAt = now.add(Duration(minutes: (hRecovering * 60).toInt()));
        }
      }

      states[muscle] = MuscleRecoveryState(
        muscleName: muscle,
        fatiguePercent: cumulativeFatigue,
        recoveryTier: tier,
        lastTrainedAt: lastTrained,
        lastVolume: lastVol,
        recentEngagements: muscleEngagements.take(5).toList(),
        estimatedReadyAt: estimatedReadyAt,
        estimatedRecoveringAt: estimatedRecoveringAt,
        hoursUntilReady: hoursUntilReady,
      );
    }

    return FullBodyRecoveryState(muscles: states);
  }
}
