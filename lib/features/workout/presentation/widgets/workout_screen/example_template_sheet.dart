import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:befit/core/constants/app_colors.dart';
import 'package:befit/core/router/app_routes.dart';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/features/workout/domain/entities/workout_session.dart';
import 'package:befit/features/workout/presentation/providers/workout_session_provider.dart';
import 'package:befit/features/auth/presentation/providers/auth_provider.dart';
import 'example_template_models.dart';

class ExampleTemplateSheet extends StatelessWidget {
  final ExampleTemplate template;

  const ExampleTemplateSheet({super.key, required this.template});

  static Future<void> show({
    required BuildContext context,
    required ExampleTemplate template,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExampleTemplateSheet(template: template),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.customColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? context.customColors.surfaceElevated
                        : const Color(0xFFF8FAFB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${template.exercises.length} exercises',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Preview this template, then start your workout',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: template.exercises.length,
              separatorBuilder: (_, _) => Divider(color: context.customColors.border, height: 1),
              itemBuilder: (context, index) {
                final ex = template.exercises[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? context.customColors.surfaceElevated
                              : const Color(0xFFF8FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.customColors.border),
                        ),
                        child: Center(
                          child: Icon(Icons.fitness_center_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ex.sets} × ${ex.name}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ex.muscleGroup,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 16),
            child: FilledButton(
              onPressed: () => _startExampleSession(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Start Workout',
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startExampleSession(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final sessionProvider = context.read<WorkoutSessionProvider>();
    final authProvider = context.read<AuthProvider>();
    final uuid = const Uuid();

    final exercises = template.exercises.map((ex) {
      return WorkoutExercise(
        id: '${uuid.v4()}_${ex.name}',
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        targetSets: ex.sets,
        targetReps: '10',
        loggedSets: [],
      );
    }).toList();

    await sessionProvider.startSession(
      template.name,
      authProvider.userId ?? '',
      exercises,
    );

    if (context.mounted) {
      Navigator.of(context).pop();
      context.push(AppRoutes.workoutSession);
    }
  }
}
