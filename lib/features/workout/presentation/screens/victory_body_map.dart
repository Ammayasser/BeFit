import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'victory_muscle_glow.dart';
import 'muscle_name_resolver.dart';
import 'victory_colors.dart';

class TrainedMuscle {
  final List<int> ids;
  final String name;
  final double volume;
  final bool isSecondary;

  TrainedMuscle({
    required this.ids,
    required this.name,
    required this.volume,
    this.isSecondary = false,
  });
}

class VictoryBodyMap extends StatelessWidget {
  final List<TrainedMuscle> trainedMuscles;
  final bool showFront;
  final bool showBack;

  const VictoryBodyMap({
    super.key,
    required this.trainedMuscles,
    this.showFront = true,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    // Sort muscles by volume descending for cascade order
    final sortedMuscles = List<TrainedMuscle>.from(trainedMuscles)
      ..sort((a, b) => b.volume.compareTo(a.volume));

    final maxVolume = sortedMuscles.isNotEmpty ? sortedMuscles.first.volume : 1.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showFront)
          _buildSilhouette(
            context,
            isBack: false,
            sortedMuscles: sortedMuscles,
            maxVolume: maxVolume,
          ),
        if (showFront && showBack) const SizedBox(width: 40),
        if (showBack)
          _buildSilhouette(
            context,
            isBack: true,
            sortedMuscles: sortedMuscles,
            maxVolume: maxVolume,
          ),
      ],
    );
  }

  Widget _buildSilhouette(
    BuildContext context, {
    required bool isBack,
    required List<TrainedMuscle> sortedMuscles,
    required double maxVolume,
  }) {
    final viewName = isBack ? 'back' : 'front';
    final baseAsset = 'assets/muscle_svgs/wger/muscular_system_$viewName.svg';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 120,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Silhouette
          Opacity(
            opacity: 0.35,
            child: SvgPicture.asset(
              baseAsset,
              width: 120,
              height: 260,
              colorFilter: isDark
                  ? const ColorFilter.matrix(<double>[
                      -1,  0,  0, 0, 255,
                       0, -1,  0, 0, 255,
                       0,  0, -1, 0, 255,
                       0,  0,  0, 1,   0,
                    ])
                  : null,
            ),
          ).animate().fadeIn(duration: 500.ms),

          // Muscle Overlays
          for (final m in sortedMuscles)
            ...m.ids.where((id) => MuscleNameResolver.isBackMuscle(id) == isBack).map((id) {
              final index = sortedMuscles.indexOf(m);
              final intensity = (m.volume / maxVolume).clamp(0.4, 1.0);
              
              return VictoryMuscleGlow(
                muscleId: id,
                color: VictoryColors.accent,
                opacity: intensity,
                isSecondary: m.isSecondary,
                delay: (index * 250).ms,
              );
            }),
        ],
      ),
    );
  }
}
