import 'package:flutter/material.dart';
import 'muscle_engagement_model.dart';

enum RecoveryTier {
  fatigued,
  recovering,
  ready,
}

class MuscleRecoveryState {
  final String muscleName;
  final double fatiguePercent;
  final RecoveryTier recoveryTier;
  final DateTime? lastTrainedAt;
  final double lastVolume;
  final DateTime? estimatedReadyAt;
  final DateTime? estimatedRecoveringAt;
  final double? hoursUntilReady;
  final List<MuscleEngagementEntry> recentEngagements;

  const MuscleRecoveryState({
    required this.muscleName,
    required this.fatiguePercent,
    required this.recoveryTier,
    this.lastTrainedAt,
    this.lastVolume = 0.0,
    this.estimatedReadyAt,
    this.estimatedRecoveringAt,
    this.hoursUntilReady,
    this.recentEngagements = const [],
  });

  Color get color {
    switch (recoveryTier) {
      case RecoveryTier.fatigued:
        return const Color(0xFFE53E3E); // Red
      case RecoveryTier.recovering:
        return const Color(0xFFECC94B); // Yellow
      case RecoveryTier.ready:
        return const Color(0xFF48BB78); // Green
    }
  }

  double get opacity {
    // If no recent data, use a subtle but visible version of the color (light green/yellow/red)
    // This ensures that "Ready" muscles (even if never trained) show up as light green.
    if (recentEngagements.isEmpty && fatiguePercent == 0.0) {
      return 0.4; 
    }
    
    switch (recoveryTier) {
      case RecoveryTier.fatigued:
        // fatigue ranges from 0.6 to 1.0. More fatigue = more solid red.
        final normalized = (fatiguePercent - 0.6) / 0.4;
        return 0.8 + (0.2 * normalized.clamp(0.0, 1.0)); 
      case RecoveryTier.recovering:
        // fatigue ranges from 0.2 to 0.6. More fatigue = more solid yellow.
        final normalized = (fatiguePercent - 0.2) / 0.4;
        return 0.7 + (0.3 * normalized.clamp(0.0, 1.0));
      case RecoveryTier.ready:
        // fatigue ranges from 0.0 to 0.2. Less fatigue (more ready) = more solid green.
        final normalized = 1.0 - (fatiguePercent / 0.2);
        return 0.7 + (0.3 * normalized.clamp(0.0, 1.0));
    }
  }
}
