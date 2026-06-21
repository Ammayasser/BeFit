import 'package:flutter/material.dart';
import 'fitbod_muscle_diagram.dart';

class MuscleMapWidget extends StatelessWidget {
  final String primaryMuscle;
  final List<String> secondaryMuscles;

  const MuscleMapWidget({
    super.key,
    required this.primaryMuscle,
    required this.secondaryMuscles,
  });

  @override
  Widget build(BuildContext context) {
    return FitbodMuscleDiagram(
      primaryMuscle: primaryMuscle,
      secondaryMuscles: secondaryMuscles,
    );
  }
}
