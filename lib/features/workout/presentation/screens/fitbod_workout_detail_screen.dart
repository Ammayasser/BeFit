import 'package:befit/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../core/workout_colors.dart';
import '../../core/workout_user_resolver.dart';
import '../../data/models/fitbod_workout_model.dart';
import '../../data/models/workout_models.dart';
import '../../presentation/providers/fitbod_workout_provider.dart';
import '../../presentation/providers/workout_session_provider.dart';
import '../../presentation/providers/workout_hub_provider.dart';
import '../../presentation/widgets/workout_difficulty_badge.dart';
import '../../presentation/widgets/fitbod_muscle_diagram.dart';
import '../../presentation/widgets/recovery_block_dialog.dart';
import '../../presentation/widgets/exercise_list_tile.dart';
import '../widgets/exercise_detail_sheet.dart';

class FitbodWorkoutDetailScreen extends StatefulWidget {
  final FitbodWorkout workout;

  const FitbodWorkoutDetailScreen({super.key, required this.workout});

  @override
  State<FitbodWorkoutDetailScreen> createState() =>
      _FitbodWorkoutDetailScreenState();
}

class _FitbodWorkoutDetailScreenState extends State<FitbodWorkoutDetailScreen> {
  List<ExerciseLibraryItem> _exerciseDetails = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final provider = context.read<FitbodWorkoutProvider>();
    final details = await provider.getExercisesForWorkout(widget.workout);
    if (mounted) {
      setState(() {
        _exerciseDetails = details;
        _loading = false;
      });
    }
  }

  void _startWorkout() {
    final sessionProvider = context.read<WorkoutSessionProvider>();
    final userId = WorkoutUserResolver.resolve(context);

    if (sessionProvider.session != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: WorkoutColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Active Workout Session',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'You already have an active session running. Resume it or start this new Fitbod workout?',
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurfaceMuted(context),
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
                _triggerStart(sessionProvider, userId);
              },
              child: const Text('Start New'),
            ),
          ],
        ),
      );
    } else {
      _triggerStart(sessionProvider, userId);
    }
  }

  void _triggerStart(
    WorkoutSessionProvider sessionProvider,
    String userId,
  ) async {
    final hubProvider = context.read<WorkoutHubProvider>();
    final blockResult = hubProvider.shouldBlockWorkout(widget.workout);

    if (blockResult.shouldBlock) {
      final override = await RecoveryBlockDialog.show(context, blockResult);
      if (override != true) {
        return;
      }
    }

    await sessionProvider.startFitbodWorkout(widget.workout, userId);
    if (mounted) {
      context.push(AppRoutes.workoutSession);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHero(context),
              SliverPadding(
                padding: EdgeInsets.all(20 * s),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMetaBlock(context),
                    SizedBox(height: 24 * s),
                    _buildAnatomySection(context),
                    SizedBox(height: 24 * s),
                    _buildExercisesSection(context),
                    SizedBox(height: 120 * s), // Buffer for bottom button
                  ]),
                ),
              ),
            ],
          ),
          // Action Button pinned at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(20 * s),
              decoration: BoxDecoration(
                color: WorkoutColors.scaffold(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12 * s,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 400 : double.infinity,
                    ),
                    child: ElevatedButton(
                      onPressed: _startWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 54 * s),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27 * s),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Start Workout Session',
                        style: GoogleFonts.montserrat(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final size = MediaQuery.of(context).size;
    final hasImage = widget.workout.imageUrls.isNotEmpty;
    final coverUrl = hasImage ? widget.workout.imageUrls.first : null;

    return SliverAppBar(
      expandedHeight: size.height < 700 ? 240 * s : 280 * s,
      pinned: true,
      backgroundColor: WorkoutColors.scaffold(context),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.black38,
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null)
              Image.network(coverUrl, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.fitness_center,
                  size: 64 * s,
                  color: Colors.white24,
                ),
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 20 * s,
              right: 20 * s,
              bottom: 20 * s,
              child: Text(
                widget.workout.name,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 24 * s,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBlock(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            WorkoutDifficultyBadge(difficulty: widget.workout.difficulty),
            SizedBox(width: 8 * s),
            Flexible(
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8 * s),
                ),
                child: Text(
                  widget.workout.category.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: AppColors.primary,
                    fontSize: 10 * fs,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: 12 * s),
            Text(
              '${widget.workout.exercises.length} Exercises',
              style: GoogleFonts.montserrat(
                color: WorkoutColors.onSurfaceMuted(context),
                fontSize: 13 * fs,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * s),
        Text(
          'Targeting: ${widget.workout.goal}',
          style: GoogleFonts.montserrat(
            color: WorkoutColors.onSurfaceMuted(context),
            fontSize: 14 * fs,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAnatomySection(BuildContext context) {
    final s = Responsive.scale(context, 1);
    if (widget.workout.primaryMuscles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Muscles',
          style: GoogleFonts.montserrat(
            fontSize: 18 * s,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12 * s),
        Container(
          padding: EdgeInsets.all(24 * s),
          decoration: BoxDecoration(
            color: WorkoutColors.card(context),
            borderRadius: BorderRadius.circular(28 * s),
            border: Border.all(color: WorkoutColors.border(context)),
          ),
          child: FitbodMuscleDiagram(
            primaryMuscle: widget.workout.primaryMuscles.first,
            secondaryMuscles: widget.workout.primaryMuscles.skip(1).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesSection(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    if (_loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40 * s),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises & Routines',
          style: GoogleFonts.montserrat(
            fontSize: 18 * s,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12 * s),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.workout.exercises.length,
          itemBuilder: (context, index) {
            final workoutEx = widget.workout.exercises[index];
            final details = _exerciseDetails.firstWhere(
              (e) => e.id == workoutEx.exerciseId,
              orElse: () => ExerciseLibraryItem(
                id: workoutEx.exerciseId,
                name: 'Unknown Exercise',
                primaryMuscles: [],
                secondaryMuscles: [],
                instructions: [],
                images: [],
                proTips: [],
              ),
            );

            return Padding(
              padding: EdgeInsets.only(bottom: 12 * s),
              child: Container(
                decoration: BoxDecoration(
                  color: WorkoutColors.card(context),
                  borderRadius: BorderRadius.circular(20 * s),
                  border: Border.all(color: WorkoutColors.border(context)),
                ),
                child: ExerciseListTile(
                  exercise: details,
                  trailing: Text(
                    '${workoutEx.sets}x${workoutEx.reps}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 13 * fs,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () {
                    if (details.name != 'Unknown Exercise') {
                      ExerciseDetailSheet.show(context, details);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
