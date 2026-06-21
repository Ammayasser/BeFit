import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/full_body_recovery_model.dart';
import '../../core/workout_colors.dart';

class MuscleRecoveryMap extends StatelessWidget {
  final FullBodyRecoveryState recoveryState;
  final bool showLabels;
  final Function(String)? onMuscleTap;

  const MuscleRecoveryMap({
    super.key,
    required this.recoveryState,
    this.showLabels = false,
    this.onMuscleTap,
  });

  List<int> _getMuscleIds(String name) {
    final clean = name.trim().toLowerCase();
    final ids = <int>[];
    
    if (clean.contains('chest')) ids.add(4);
    if (clean.contains('abs') || clean.contains('abdominals')) ids.addAll([6, 14]); 
    if (clean.contains('biceps')) ids.addAll([1, 13]); 
    if (clean.contains('triceps')) ids.add(5);
    if (clean.contains('shoulders')) ids.add(2);
    if (clean.contains('quadriceps')) ids.add(10);
    if (clean.contains('hamstrings')) ids.add(11);
    if (clean.contains('glutes')) ids.add(8);
    if (clean.contains('calves')) ids.addAll([7, 15]); 
    if (clean.contains('trapezius')) ids.add(9);
    if (clean.contains('back')) ids.add(12);
    
    // Add logic for forearms, abductors if IDs exist, else ignore.
    // Assuming wger ID 3 is maybe forearms? We'll leave out if not known exactly, but usually 3=serratus anterior, etc.
    // 16=lower back? We'll map lower-back to 16 if it's back muscle.
    if (clean.contains('lower-back')) ids.add(16);
    
    return ids;
  }

  bool _isBackMuscle(int id) {
    return const [5, 7, 8, 9, 11, 12, 15, 16].contains(id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final row = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Front View
            _buildWgerSilhouette(context, isBack: false),
            const SizedBox(width: 24),
            // Back View
            _buildWgerSilhouette(context, isBack: true),
          ],
        );

        if (constraints.maxWidth < 304) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: row,
          );
        }
        return row;
      },
    );
  }

  Widget _buildWgerSilhouette(BuildContext context, {required bool isBack}) {
    final viewName = isBack ? 'back' : 'front';
    final baseSilhouettePath = 'assets/muscle_svgs/wger/muscular_system_$viewName.svg';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final layers = <Widget>[];

    // 1. Base Silhouette
    layers.add(
      Opacity(
        opacity: isDark ? 0.35 : 0.3,
        child: SvgPicture.asset(
          baseSilhouettePath,
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
      ),
    );

    // 2. Muscle Overlays
    for (final entry in recoveryState.muscles.entries) {
      final state = entry.value;
      final ids = _getMuscleIds(state.muscleName);
      final viewIds = ids.where((id) => _isBackMuscle(id) == isBack).toList();

      for (final id in viewIds) {
        layers.add(
          GestureDetector(
            onTap: onMuscleTap != null ? () => onMuscleTap!(state.muscleName) : null,
            child: Semantics(
              label: '${state.muscleName}: ${state.recoveryTier.name}, ${(100 - state.fatiguePercent * 100).toInt()}% recovered.',
              child: Opacity(
                opacity: state.opacity,
                child: SvgPicture.asset(
                  'assets/muscle_svgs/wger/muscle-$id.svg',
                  width: 120,
                  height: 260,
                  colorFilter: ColorFilter.mode(
                    state.color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      width: 140,
      height: 280,
      decoration: WorkoutColors.cardDecoration(context, radius: 24),
      child: Stack(
        alignment: Alignment.center,
        children: layers,
      ),
    );
  }
}
