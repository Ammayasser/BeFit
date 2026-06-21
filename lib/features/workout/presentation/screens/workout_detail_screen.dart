import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../core/workout_user_resolver.dart';
import '../../data/repositories/workout_stats_repository.dart';
import '../../data/curated_workouts.dart';
import '../../data/models/workout_models.dart';
import '../../data/models/workout_history_entry.dart';
import '../../data/repositories/exercise_repository.dart';
import '../providers/saved_workouts_provider.dart';
import '../providers/workout_session_provider.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../../core/exercise_media.dart';
import '../widgets/muscle_map_widget.dart';
import '../widgets/workout_cover_image.dart';
import '../widgets/workout_ui.dart';

import '../../data/mappers/workout_mapper.dart';
import '../../domain/entities/workout_session.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late List<SessionExercise> _exercises;
  late String _workoutName;
  late String _difficulty;
  late String _duration;
  late int _kcal;
  late String _muscleFocus;
  String? _heroImageUrl;
  bool _loading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutDetails();
  }

  int _estimateKcal(List<SessionExercise> exercises, int durationMin) {
    if (!mounted) return 0;
    final weight = context.read<UserProvider>().weight;
    final w = weight > 0 ? weight : 70.0;
    if (exercises.isEmpty) return (durationMin * 8).round();
    final sets = exercises.fold<int>(0, (s, e) => s + e.targetSets);
    return WorkoutStatsRepository.estimateCaloriesFromLog(
      WorkoutHistoryEntry(
        userId: '',
        date: DateTime.now().toIso8601String().substring(0, 10),
        durationSeconds: durationMin * 60,
        totalSets: sets,
        totalReps: exercises.length * 10,
        totalVolume: sets * 250.0,
      ),
      w,
    );
  }

  Future<void> _loadWorkoutDetails() async {
    final user = mounted ? context.read<UserProvider>() : null;

    final curated = curatedWorkoutByRouteId(widget.workoutId);
    if (curated != null) {
      _workoutName = curated.name;
      _difficulty = curated.difficulty;
      _duration = '${curated.durationMin} min';
      _muscleFocus = curated.muscleGroup;
      final mockData = curatedWorkoutExerciseSets[curated.name] ?? [];
      final repo = ExerciseRepository();
      final loaded = <SessionExercise>[];
      for (final e in mockData) {
        final details = await repo.getExerciseByName(e['name'] as String);
        loaded.add(
          SessionExercise(
            id: details?.id ?? (e['name'] as String).hashCode.toString(),
            name: e['name'] as String,
            muscleGroup: details?.bodyPart ?? e['muscle'] as String,
            gifUrl: normalizeExerciseMediaUrl(details?.gifUrl),
            targetSets: e['sets'] as int,
            targetReps: e['reps'] as String,
            targetWeight: 0.0,
            met: details?.met ?? 3.0,
            loggedSets: [],
          ),
        );
      }
      _exercises = loaded;
      _kcal = _estimateKcal(loaded, curated.durationMin);
      _finishLoad();
      return;
    }

    _workoutName = 'Workout';
    _difficulty = user?.experienceLevel.isNotEmpty == true
        ? user!.experienceLevel
        : 'Intermediate';
    _duration = '45 min';
    _kcal = 0;
    _muscleFocus = 'Chest';
    _exercises = [];
    _finishLoad();
  }

  void _finishLoad() {
    if (!mounted) return;
    final saved = context.read<SavedWorkoutsProvider>();
    _isFavorite = saved.isSaved(widget.workoutId);
    for (final ex in _exercises) {
      if (ex.gifUrl != null && ex.gifUrl!.trim().isNotEmpty) {
        _heroImageUrl = normalizeExerciseMediaUrl(ex.gifUrl);
        break;
      }
    }
    setState(() => _loading = false);
  }

  void _startWorkoutSession() {
    final sessionProvider = context.read<WorkoutSessionProvider>();
    final userId = WorkoutUserResolver.resolve(context);

    void go() async {
      final workoutExercises = _exercises
          .map(WorkoutMapper.toEntityExercise)
          .toList()
          .cast<WorkoutExercise>();
      await sessionProvider.startSession(
        _workoutName,
        userId,
        workoutExercises,
      );
      if (mounted) {
        context.push(AppRoutes.workoutSession);
      }
    }

    if (sessionProvider.session != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Active Session',
            style: workoutTextStyle(ctx, weight: FontWeight.w700),
          ),
          content: Text(
            'Resume your current workout or start this one?',
            style: workoutTextStyle(
              ctx,
              color: WorkoutColors.onSurfaceMuted(ctx),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.workoutSession);
              },
              child: const Text('Resume'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                sessionProvider.cancelWorkout();
                go();
              },
              child: const Text('Start New'),
            ),
          ],
        ),
      );
    } else {
      go();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: WorkoutColors.scaffold(context),
        body: Center(
          child: CircularProgressIndicator(color: WorkoutColors.lime(context)),
        ),
      );
    }

    final curated = curatedWorkoutByRouteId(widget.workoutId);

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero(curated)),
              SliverToBoxAdapter(child: _buildInfo()),
              SliverToBoxAdapter(child: _buildAbout()),
              SliverToBoxAdapter(child: _buildMuscleFocus()),
              SliverToBoxAdapter(child: _buildEquipment()),
              SliverToBoxAdapter(child: _buildExerciseList()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WorkoutColors.scaffold(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: WorkoutPrimaryButton(
                  label: 'Start Workout',
                  onPressed: _startWorkoutSession,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(CuratedWorkout? curated) {
    return Stack(
      children: [
        WorkoutCoverImage(
          workoutRouteId: widget.workoutId,
          imageUrl: _heroImageUrl,
          muscleGroup: _muscleFocus,
          category: curated?.category,
          height: 280,
          gradientColors: curated != null
              ? [
                  curated.gradient.first.withValues(alpha: 0.2),
                  curated.gradient.last.withValues(alpha: 0.75),
                ]
              : null,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: WorkoutColors.lime(context),
                  ),
                  onPressed: () async {
                    await context.read<SavedWorkoutsProvider>().toggle(
                      widget.workoutId,
                    );
                    setState(() => _isFavorite = !_isFavorite);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final user = context.watch<UserProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _workoutName,
            style: workoutTextStyle(context, size: 26, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.access_time, _duration),
              _infoChip(Icons.local_fire_department, '$_kcal kcal'),
              _infoChip(Icons.trending_up, _difficulty),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: WorkoutColors.limeMuted(context),
                child: Text(
                  'SC',
                  style: workoutTextStyle(
                    context,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                user.hasProfile
                    ? 'Your ${user.experienceLevel} plan'
                    : 'BeFit Coach',
                style: workoutTextStyle(
                  context,
                  size: 14,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: WorkoutColors.onSurfaceMuted(context)),
          const SizedBox(width: 4),
          Text(
            text,
            style: workoutTextStyle(
              context,
              size: 13,
              color: WorkoutColors.onSurfaceMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Build strength and muscle with this focused session targeting $_muscleFocus. '
            'Perfect for intermediate lifters looking to progress with controlled volume.',
            style: workoutTextStyle(
              context,
              size: 14,
              color: WorkoutColors.onSurfaceMuted(context),
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleFocus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Focus',
            style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Theme(
            data: ThemeData(brightness: Brightness.light),
            child: MuscleMapWidget(
              primaryMuscle: _muscleFocus,
              secondaryMuscles: const ['Shoulders', 'Triceps'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipment() {
    const items = [
      (Icons.fitness_center, 'Dumbbell'),
      (Icons.chair_alt, 'Bench'),
      (Icons.sports_gymnastics, 'Barbell'),
      (Icons.grid_view, 'Mat'),
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipment',
            style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: WorkoutColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WorkoutColors.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          e.$1,
                          size: 18,
                          color: WorkoutColors.onSurface(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.$2,
                          style: workoutTextStyle(
                            context,
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercises (${_exercises.length})',
            style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ..._exercises.map(
            (ex) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: WorkoutColors.border(context)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: workoutTextStyle(
                            context,
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${ex.targetSets} sets × ${ex.targetReps}',
                          style: workoutTextStyle(
                            context,
                            size: 12,
                            color: WorkoutColors.onSurfaceMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: WorkoutColors.limeDark(context),
                    ),
                    onPressed: () async {
                      final repo = ExerciseRepository();
                      final details = await repo.getExerciseById(ex.id);
                      if (!mounted) return;
                      if (details != null) {
                        context.push(
                          '${AppRoutes.workout}/exercise/${ex.id}',
                          extra: details,
                        );
                      } else {
                        ExerciseDetailSheet.show(
                          context,
                          ExerciseLibraryItem(
                            id: ex.id,
                            name: ex.name,
                            bodyPart: ex.muscleGroup,
                            primaryMuscles: ex.muscleGroup != null
                                ? [ex.muscleGroup!]
                                : [],
                            secondaryMuscles: [],
                            instructions: ['Perform with controlled form.'],
                            images: ex.gifUrl != null ? [ex.gifUrl!] : [],
                            gifUrl: ex.gifUrl,
                            proTips: [],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
