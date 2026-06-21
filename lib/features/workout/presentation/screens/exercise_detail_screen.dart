import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import '../../data/models/workout_models.dart';
import '../widgets/exercise_gif_image.dart';
import '../widgets/muscle_map_widget.dart';
import '../widgets/workout_ui.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseLibraryItem exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: WorkoutLightScaffold(
        appBar: WorkoutBackAppBar(title: exercise.name),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: ExerciseGifImage(
                imageUrl: exercise.gifUrl,
                height: 180,
                width: double.infinity,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            TabBar(
              labelColor: WorkoutColors.onSurface(context),
              unselectedLabelColor: WorkoutColors.onSurfaceMuted(context),
              indicatorColor: WorkoutColors.lime(context),
              indicatorWeight: 3,
              labelStyle: workoutTextStyle(
                context,
                size: 13,
                weight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Muscles'),
                Tab(text: 'How To'),
                Tab(text: 'Mistakes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(exercise: exercise),
                  _MusclesTab(exercise: exercise),
                  _HowToTab(exercise: exercise),
                  _MistakesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _OverviewTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _listSection(context, 'Primary Muscles', [exercise.bodyPart ?? '—']),
        _listSection(context, 'Secondary Muscles', exercise.secondaryMuscles),
        _listSection(
          context,
          'Equipment',
          exercise.equipment != null ? [exercise.equipment!] : ['Bodyweight'],
        ),
      ],
    );
  }
}

class _MusclesTab extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _MusclesTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: MuscleMapWidget(
            primaryMuscle: exercise.bodyPart ?? 'Chest',
            secondaryMuscles: exercise.secondaryMuscles,
          ),
        ),
      ],
    );
  }
}

class _HowToTab extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _HowToTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final steps = exercise.instructions.isNotEmpty
        ? exercise.instructions
        : [
            'Set up with proper form.',
            'Control the movement.',
            'Breathe steadily.',
          ];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: steps.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WorkoutColors.lime(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${i + 1}',
                style: workoutTextStyle(ctx, size: 13, weight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                steps[i],
                style: workoutTextStyle(
                  ctx,
                  size: 14,
                  color: WorkoutColors.onSurfaceMuted(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const mistakes = [
      'Using too much weight and sacrificing form',
      'Bouncing the weight instead of controlled reps',
      'Not engaging core for stability',
      'Incomplete range of motion',
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: mistakes.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mistakes[i],
                style: workoutTextStyle(
                  ctx,
                  size: 14,
                  color: WorkoutColors.onSurfaceMuted(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _listSection(BuildContext context, String title, List<String> items) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: workoutTextStyle(context, size: 16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $t',
              style: workoutTextStyle(
                context,
                size: 14,
                color: WorkoutColors.onSurfaceMuted(context),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
