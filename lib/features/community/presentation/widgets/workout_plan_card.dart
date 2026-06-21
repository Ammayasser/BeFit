import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../../workout/domain/entities/workout_session.dart';
import '../../../workout/presentation/providers/workout_session_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout/data/repositories/exercise_repository.dart';
import '../../../workout/presentation/widgets/exercise_gif_image.dart';

class WorkoutPlanCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final double s;

  const WorkoutPlanCard({
    super.key,
    required this.data,
    required this.s,
  });

  @override
  State<WorkoutPlanCard> createState() => _WorkoutPlanCardState();
}

class _WorkoutPlanCardState extends State<WorkoutPlanCard> {
  final List<Map<String, dynamic>> _resolvedExercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveExercises();
  }

  Future<void> _resolveExercises() async {
    final repo = ExerciseRepository();
    final rawExercises = widget.data['exercises'] as List? ?? [];
    
    for (final ex in rawExercises) {
      if (ex is Map<String, dynamic>) {
        final name = ex['name'] ?? '';
        final item = await repo.getExerciseByName(name) ??
                     await repo.findExerciseByFuzzyName(name);
        _resolvedExercises.add({
          ...ex,
          'gifUrl': item?.gifUrl,
        });
      }
    }
    
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _startWorkout(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    final uuid = const Uuid();
    final sessionExercises = _resolvedExercises.map((ex) {
      final parsedReps = RegExp(r'\d+').firstMatch(ex['reps']?.toString() ?? '10')?.group(0) ?? '10';
      final targetSetsCount = int.tryParse(ex['sets']?.toString() ?? '3') ?? 3;
      final initialSets = List<WorkoutSet>.generate(
        targetSetsCount,
        (i) => WorkoutSet(
          setNumber: i + 1,
          weightKg: 0.0,
          reps: int.tryParse(parsedReps) ?? 10,
          loggedAt: DateTime.now(),
          isCompleted: false,
        ),
      );

      return WorkoutExercise(
        id: uuid.v4(),
        name: ex['name'] ?? '',
        muscleGroup: ex['muscleGroup'],
        gifUrl: ex['gifUrl'],
        targetSets: targetSetsCount,
        targetReps: ex['reps']?.toString() ?? '10',
        loggedSets: initialSets,
      );
    }).toList();

    final sessionProvider = context.read<WorkoutSessionProvider>();
    final authProvider = context.read<AuthProvider>();

    sessionProvider.startSession(
      widget.data['title'] ?? 'AI Workout',
      authProvider.userId ?? '',
      sessionExercises,
    );
    context.push(AppRoutes.workoutSession);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final exercises = _resolvedExercises;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final custom = context.customColors;

    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: custom.surfaceCard,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: custom.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16 * s),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                  custom.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * s),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10 * s),
                  ),
                  child: Icon(Iconsax.flash_1, color: primaryAccent, size: 20 * s),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data['title'] ?? 'Workout Plan',
                        style: GoogleFonts.montserrat(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (widget.data['subtitle'] != null)
                        Text(
                          widget.data['subtitle'],
                          style: GoogleFonts.inter(
                            fontSize: 11 * s,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100 * s),
                    border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${exercises.length} exercises',
                    style: GoogleFonts.montserrat(
                      fontSize: 10 * s,
                      fontWeight: FontWeight.w800,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exercise List
          if (_loading)
            Padding(
              padding: EdgeInsets.all(24 * s),
              child: Center(
                child: CircularProgressIndicator(color: primaryAccent),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 8 * s),
              itemCount: exercises.length,
              separatorBuilder: (_, index) => Divider(color: custom.border, height: 1),
              itemBuilder: (_, i) => _ExerciseRow(exercise: exercises[i], index: i, s: s),
            ),

          // Coach Note
          if (!_loading && widget.data['coachNote'] != null)
            Container(
              margin: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
              padding: EdgeInsets.all(14 * s),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.message_favorite,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16 * s,
                  ),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      widget.data['coachNote'],
                      style: GoogleFonts.inter(
                        fontSize: 12 * s,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Start Workout Button
          if (!_loading)
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
              child: GestureDetector(
                onTap: () => _startWorkout(context),
                child: Container(
                  width: double.infinity,
                  height: 48 * s,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14 * s),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAccent.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.flash_1,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18 * s,
                      ),
                      SizedBox(width: 8 * s),
                      Text(
                        'Start This Workout',
                        style: GoogleFonts.montserrat(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final double s;

  const _ExerciseRow({
    required this.exercise,
    required this.index,
    required this.s,
  });

  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final exercise = widget.exercise;
    final index = widget.index;
    final custom = context.customColors;

    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
            child: Row(
              children: [
                // Exercise number circle
                Container(
                  width: 28 * s,
                  height: 28 * s,
                  decoration: BoxDecoration(
                    color: custom.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w800,
                        color: primaryAccent,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),

                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] ?? '',
                        style: GoogleFonts.montserrat(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        exercise['muscleGroup'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 11 * s,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sets x Reps badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: custom.surfaceElevated,
                    borderRadius: BorderRadius.circular(8 * s),
                    border: Border.all(color: custom.border),
                  ),
                  child: Text(
                    '${exercise['sets']} × ${exercise['reps']}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12 * s,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 8 * s),

                // Rest badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: custom.surfaceElevated,
                    borderRadius: BorderRadius.circular(8 * s),
                  ),
                  child: Text(
                    exercise['rest'] ?? '90s',
                    style: GoogleFonts.inter(
                      fontSize: 10 * s,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(width: 6 * s),
                Icon(
                  _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 14 * s,
                ),
              ],
            ),
          ),
        ),

        // Expanded view details
        if (_isExpanded) ...[
          if (exercise['notes'] != null)
            Padding(
              padding: EdgeInsets.fromLTRB(56 * s, 0, 16 * s, 8 * s),
              child: Text(
                '💡 ${exercise['notes']}',
                style: GoogleFonts.inter(
                  fontSize: 12 * s,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          if (exercise['gifUrl'] != null)
            Padding(
              padding: EdgeInsets.fromLTRB(56 * s, 0, 16 * s, 12 * s),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12 * s),
                child: SizedBox(
                  height: 120 * s,
                  width: double.infinity,
                  child: ExerciseGifImage(
                    imageUrl: exercise['gifUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
