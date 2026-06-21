import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/curated_workouts.dart';
import '../../data/models/workout_hub_stats.dart';
import '../providers/workout_hub_provider.dart';
import '../widgets/workout_cover_image.dart';
import '../widgets/workout_ui.dart';

class ProgramDetailScreen extends StatelessWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<WorkoutHubProvider>();
    DynamicProgram? program;
    for (final p in hub.programs) {
      if (p.id == programId) {
        program = p;
        break;
      }
    }

    if (program == null) {
      final curated = curatedWorkoutByRouteId(programId);
      if (curated != null) {
        return _CuratedFallback(curated: curated);
      }
      return WorkoutLightScaffold(
        appBar: const WorkoutBackAppBar(title: 'Program'),
        body: const Center(child: Text('Program not found')),
      );
    }

    final title = program.title;
    final progress = program.progress;
    final totalWeeks = program.totalWeeks;
    final gradient = program.gradientArgb.length >= 2
        ? [Color(program.gradientArgb[0]), Color(program.gradientArgb[1])]
        : [const Color(0xFF1E3A5F), const Color(0xFF0F172A)];

    final weeks = List.generate(totalWeeks, (i) => _WeekItem(i + 1));

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    WorkoutCoverImage(
                      workoutRouteId: programId,
                      height: 240,
                      muscleGroup: program.goal,
                      gradientColors: [
                        gradient[0].withValues(alpha: 0.2),
                        gradient[1].withValues(alpha: 0.75),
                      ],
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: workoutTextStyle(
                          context,
                          size: 26,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${program.durationLabel} · ${program.difficulty}',
                        style: workoutTextStyle(
                          context,
                          size: 14,
                          color: WorkoutColors.onSurfaceMuted(context),
                        ),
                      ),
                      Text(
                        program.goal,
                        style: workoutTextStyle(
                          context,
                          size: 14,
                          color: WorkoutColors.onSurfaceMuted(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (progress > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: workoutTextStyle(
                                context,
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: workoutTextStyle(
                                context,
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: WorkoutColors.card(context),
                            color: WorkoutColors.lime(context),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Program Overview',
                        style: workoutTextStyle(
                          context,
                          size: 18,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...weeks.map((w) {
                        final done =
                            progress > 0 &&
                            w.index <= (progress * weeks.length).ceil();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: WorkoutColors.border(context),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: done
                                    ? WorkoutColors.limeDark(context)
                                    : WorkoutColors.onSurfaceSubtle(context),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Week ${w.index}',
                                      style: workoutTextStyle(
                                        context,
                                        size: 15,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: WorkoutColors.scaffold(context),
              child: SafeArea(
                child: WorkoutPrimaryButton(
                  label: progress > 0 ? 'Continue Program' : 'Start Program',
                  onPressed: () {
                    // Start logic for curated programs
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekItem {
  final int index;
  _WeekItem(this.index);
}

class _CuratedFallback extends StatelessWidget {
  final CuratedWorkout curated;
  const _CuratedFallback({required this.curated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(curated.name),
      ),
      body: Center(
        child: WorkoutPrimaryButton(
          label: 'Open Workout',
          onPressed: () => context.push(
            AppRoutes.workoutDetail.replaceFirst(':id', curated.routeId),
          ),
        ),
      ),
    );
  }
}
