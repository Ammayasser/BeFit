// lib/features/workout/presentation/widgets/routine_preview_sheet.dart

import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/features/workout/data/mappers/workout_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/router/app_routes.dart';
import '../../data/models/workout_models.dart';
import '../../data/models/workout_routine.dart';
import '../../domain/entities/workout_session.dart';
import '../providers/workout_session_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'exercise_gif_image.dart';

/// Bottom sheet shown when a user taps a routine card.
class RoutinePreviewSheet extends StatelessWidget {
  final WorkoutRoutine routine;

  const RoutinePreviewSheet({super.key, required this.routine});

  static Future<void> show(BuildContext context, WorkoutRoutine routine) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutinePreviewSheet(routine: routine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    routine.name,
                    style: GoogleFonts.montserrat(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${routine.exercises.length} exercises',
                    style: GoogleFonts.montserrat(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Review exercises, then start your session',
                style: GoogleFonts.montserrat(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (routine.exercises.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: routine.exercises.length,
                separatorBuilder: (_, _) =>
                    Divider(color: colors.border, height: 1),
                itemBuilder: (context, index) {
                  final ex = routine.exercises[index];
                  return _ExercisePreviewRow(exercise: ex);
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No exercises in this routine yet.',
                style: GoogleFonts.montserrat(color: colorScheme.onSurfaceVariant),
              ),
            ),

          const SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 16),
            child: FilledButton(
              onPressed: routine.exercises.isEmpty
                  ? null
                  : () => _startSession(context),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: isDark ? colors.bgPrimary : Colors.white,
                disabledBackgroundColor: colors.surfaceCard,
                disabledForegroundColor: colorScheme.onSurfaceVariant,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Start Workout',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final sessionProvider = context.read<WorkoutSessionProvider>();
    final authProvider = context.read<AuthProvider>();

    final uuid = const Uuid();

    final sessionExercises = routine.exercises.map((ex) {
      return SessionExercise(
        id: '${uuid.v4()}_${ex.exerciseName}',
        name: ex.exerciseName,
        muscleGroup: ex.muscleGroup,
        gifUrl: ex.gifUrl,
        targetSets: ex.defaultSets,
        targetReps: ex.defaultReps,
        targetWeight: ex.defaultWeight,
        loggedSets: [],
      );
    }).toList();

    final workoutExercises = sessionExercises
        .map(WorkoutMapper.toEntityExercise)
        .toList()
        .cast<WorkoutExercise>();

    await sessionProvider.startSession(
      routine.name,
      authProvider.userId ?? '',
      workoutExercises,
    );

    if (context.mounted) {
      Navigator.of(context).pop();
      context.push(AppRoutes.workoutSession);
    }
  }
}

class _ExercisePreviewRow extends StatelessWidget {
  final RoutineExercise exercise;

  const _ExercisePreviewRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                  ? ExerciseGifImage(
                      imageUrl: exercise.gifUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(
                      color: colors.surfaceCard,
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: GoogleFonts.montserrat(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exercise.muscleGroup != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    exercise.muscleGroup!,
                    style: GoogleFonts.montserrat(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${exercise.defaultSets} sets',
              style: GoogleFonts.montserrat(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
