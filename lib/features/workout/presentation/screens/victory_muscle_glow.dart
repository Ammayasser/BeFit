import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VictoryMuscleGlow extends StatelessWidget {
  final int muscleId;
  final Color color;
  final double opacity;
  final bool isSecondary;
  final Duration delay;

  const VictoryMuscleGlow({
    super.key,
    required this.muscleId,
    required this.color,
    this.opacity = 1.0,
    this.isSecondary = false,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/muscle_svgs/wger/muscle-$muscleId.svg';
    final effectiveOpacity = isSecondary ? opacity * 0.5 : opacity;

    return Stack(
      children: [
        // Glow Halo
        SvgPicture.asset(
          assetPath,
          width: 120,
          height: 260,
          colorFilter: ColorFilter.mode(
            color.withValues(alpha: effectiveOpacity * 0.3),
            BlendMode.srcIn,
          ),
        )
            .animate(delay: delay)
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.2, 1.2),
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(duration: 300.ms),

        // Main Muscle Overlay
        SvgPicture.asset(
          assetPath,
          width: 120,
          height: 260,
          colorFilter: ColorFilter.mode(
            color.withValues(alpha: effectiveOpacity),
            BlendMode.srcIn,
          ),
        )
            .animate(delay: delay)
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.03, 1.03),
              duration: 200.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.03, 1.03),
              end: const Offset(1.0, 1.0),
              duration: 200.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
