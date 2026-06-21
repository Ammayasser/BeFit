// lib/features/workout/presentation/widgets/routine_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../data/models/workout_routine.dart';

/// Modern, redesigned routine card for the Workout hub list.
class RoutineCard extends StatelessWidget {
  final WorkoutRoutine routine;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  Color _resolveAccentColor(WorkoutRoutine routine) {
    if (routine.exercises.isEmpty) return AppColors.primary;

    final counts = <String, int>{};
    for (final ex in routine.exercises) {
      final mg = ex.muscleGroup ?? 'Other';
      counts[mg] = (counts[mg] ?? 0) + 1;
    }

    String dominant = 'Other';
    int maxCount = -1;
    counts.forEach((mg, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = mg;
      }
    });

    switch (dominant) {
      case 'Chest':
        return const Color(0xFFEF4444);
      case 'Back':
        return const Color(0xFF3B82F6);
      case 'Legs':
        return const Color(0xFFF97316);
      case 'Shoulders':
        return const Color(0xFF8B5CF6);
      case 'Arms':
        return const Color(0xFFEC4899);
      case 'Core':
        return const Color(0xFF06B6D4);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _resolveAccentColor(routine);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 60)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(routine.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Delete Routine?',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: Text(
                'Are you sure you want to remove "${routine.name}"?',
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                  child: Text('Delete', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                "Delete",
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.customColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 
                    Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.04,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 22,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routine.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${routine.exercises.length} exercises",
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _OverflowMenu(
                      onEdit: onEdit,
                      onDuplicate: onDuplicate,
                      onDelete: onDelete,
                    ),
                  ],
                ),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: context.customColors.border, height: 1, thickness: 1),
                ),
                // Exercise Preview List
                if (routine.exercises.isNotEmpty) ...[
                  ...routine.exercises.take(3).map((ex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ex.exerciseName,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? context.customColors.surfaceElevated
                                  : const Color(0xFFF8FAFC),
                            ),
                            child: Text(
                              "${ex.defaultSets} sets",
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (routine.exercises.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 2),
                      child: Text(
                        "+${routine.exercises.length - 3} more",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
                // Bottom Row
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _getUniqueMuscleGroups(routine).take(3).map((mg) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? context.customColors.surfaceMuted
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Text(
                                mg,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onTap();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: accentColor,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "Start",
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getUniqueMuscleGroups(WorkoutRoutine routine) {
    final groups = <String>{};
    for (final ex in routine.exercises) {
      if (ex.muscleGroup != null) {
        groups.add(ex.muscleGroup!);
      }
    }
    return groups.toList();
  }
}

class _OverflowMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _OverflowMenu({
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RoutineAction>(
      padding: EdgeInsets.zero,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? context.customColors.surfaceElevated
              : const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.more_horiz_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
      onSelected: (action) {
        switch (action) {
          case _RoutineAction.edit:
            onEdit();
          case _RoutineAction.duplicate:
            onDuplicate();
          case _RoutineAction.delete:
            onDelete();
        }
      },
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _RoutineAction.edit,
          child: _MenuRow(
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
        ),
        PopupMenuItem(
          value: _RoutineAction.duplicate,
          child: _MenuRow(
            icon: Icons.copy_rounded,
            label: 'Duplicate',
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: _RoutineAction.delete,
          child: _MenuRow(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: c,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

enum _RoutineAction { edit, duplicate, delete }
