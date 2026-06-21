// lib/features/workout/presentation/screens/smart_plan_preview_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/workout_routine.dart';
import '../providers/routine_provider.dart';
import '../../../smart_plan/presentation/providers/smart_plan_provider.dart';
import '../../../smart_plan/data/models/smart_workout_plan.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../core/workout_colors.dart';
import '../../data/repositories/exercise_repository.dart';
import 'exercise_detail_screen.dart';

class SmartPlanPreviewScreen extends StatefulWidget {
  final List<WorkoutRoutine> routines;
  final String planName;
  final String description;
  final bool isReplacingSmartPlan;

  const SmartPlanPreviewScreen({
    super.key,
    required this.routines,
    required this.planName,
    required this.description,
    this.isReplacingSmartPlan = false,
  });

  @override
  State<SmartPlanPreviewScreen> createState() => _SmartPlanPreviewScreenState();
}

class _SmartPlanPreviewScreenState extends State<SmartPlanPreviewScreen> {
  int _selectedDayIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Start at the first non-rest day if possible
    final firstActiveIdx = widget.routines.indexWhere((r) => r.exercises.isNotEmpty);
    if (firstActiveIdx != -1) {
      _selectedDayIndex = firstActiveIdx;
    }
  }

  Future<void> _savePlan() async {
    setState(() => _isSaving = true);
    try {
      final activeRoutines = widget.routines.where((r) => r.exercises.isNotEmpty).toList();
      
      if (widget.isReplacingSmartPlan) {
        // Convert routines to SmartWorkoutDays
        final List<SmartWorkoutDay> newDays = [];
        for (int i = 0; i < widget.routines.length; i++) {
          final r = widget.routines[i];
          newDays.add(SmartWorkoutDay(
            dayIndex: i + 1,
            name: r.name,
            isRestDay: r.exercises.isEmpty,
            exercises: r.exercises
                .map((e) => SmartWorkoutExercise(
                      name: e.exerciseName,
                      sets: e.defaultSets,
                      reps: e.defaultReps,
                      muscleGroup: e.muscleGroup,
                      gifUrl: e.gifUrl,
                      exerciseId: e.exerciseId,
                    ))
                .toList(),
          ));
        }
        final auth = context.read<AuthProvider>();
        await context.read<SmartPlanProvider>().updateWorkoutPlan(auth.userId ?? '', newDays);
      } else {
        await context.read<RoutineProvider>().saveRoutines(activeRoutines);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isReplacingSmartPlan 
            ? 'Successfully updated your weekly workout plan!' 
            : 'Successfully added ${activeRoutines.length} routines to your templates!'),
          backgroundColor: WorkoutColors.lime(context),
        ),
      );
      // Pop back to workout screen
      Navigator.of(context).pop(); // Pop preview
      Navigator.of(context).pop(); // Pop generator
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoutine = widget.routines[_selectedDayIndex];

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      body: CustomScrollView(
        slivers: [
          // ─── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: WorkoutColors.scaffold(context),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WorkoutColors.lime(context).withValues(alpha: 0.2),
                      WorkoutColors.scaffold(context),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: WorkoutColors.lime(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AI GENERATED',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.planName,
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: WorkoutColors.onSurface(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: WorkoutColors.onSurfaceMuted(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Day Selector ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: widget.routines.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final routine = widget.routines[index];
                  final isSelected = _selectedDayIndex == index;
                  final isRestDay = routine.exercises.isEmpty;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70,
                      decoration: BoxDecoration(
                        color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.border(context),
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: WorkoutColors.lime(context).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DAY',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.black : WorkoutColors.onSurfaceMuted(context),
                            ),
                          ),
                          Text(
                            '${index + 1}',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.black : WorkoutColors.onSurface(context),
                            ),
                          ),
                          if (isRestDay)
                            Icon(Icons.nightlight_round, size: 12, color: isSelected ? Colors.black : Colors.blueGrey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Exercise List ─────────────────────────────────────────────────
          if (selectedRoutine.exercises.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hotel_rounded, size: 64, color: WorkoutColors.border(context)),
                    const SizedBox(height: 16),
                    Text(
                      'Rest Day',
                      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: WorkoutColors.onSurfaceMuted(context)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ex = selectedRoutine.exercises[index];
                    return _ExercisePreviewCard(exercise: ex, index: index);
                  },
                  childCount: selectedRoutine.exercises.length,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          color: WorkoutColors.scaffold(context),
          border: Border(top: BorderSide(color: WorkoutColors.border(context))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: WorkoutColors.border(context)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Discard',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.redAccent),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WorkoutColors.lime(context),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(
                        'Accept & Save Plan',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePreviewCard extends StatelessWidget {
  final RoutineExercise exercise;
  final int index;

  const _ExercisePreviewCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Only navigate if it's a matched exercise (ID doesn't start with ai_)
        if (!exercise.exerciseId.startsWith('ai_')) {
          final repo = ExerciseRepository();
          final fullExercise = await repo.getExerciseById(exercise.exerciseId);
          if (fullExercise != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseDetailScreen(exercise: fullExercise),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details not available for this custom AI exercise.')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WorkoutColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WorkoutColors.border(context)),
        ),
        child: Row(
          children: [
            // ─── Exercise Image/Icon ──────────────────────────────────────────
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: WorkoutColors.scaffold(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WorkoutColors.border(context)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildExerciseImage(context),
              ),
            ),
            const SizedBox(width: 16),
            // ─── Details ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseName,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: WorkoutColors.onSurface(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.muscleGroup != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      exercise.muscleGroup!.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: WorkoutColors.lime(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Tag(label: '${exercise.defaultSets} Sets'),
                      const SizedBox(width: 8),
                      _Tag(label: '${exercise.defaultReps} Reps'),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: WorkoutColors.border(context)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
  }

  Widget _buildExerciseImage(BuildContext context) {
    if (exercise.gifUrl == null || exercise.gifUrl!.isEmpty) {
      return Center(child: Icon(Iconsax.weight, color: WorkoutColors.lime(context), size: 28));
    }

    if (exercise.gifUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: exercise.gifUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: WorkoutColors.border(context).withValues(alpha: 0.1)),
        errorWidget: (context, url, error) => Icon(Iconsax.weight, color: WorkoutColors.lime(context)),
      );
    }

    return Image.file(
      File(exercise.gifUrl!),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(Iconsax.weight, color: WorkoutColors.lime(context)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: WorkoutColors.scaffold(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: WorkoutColors.onSurfaceMuted(context),
        ),
      ),
    );
  }
}
