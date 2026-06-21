// lib/features/workout/presentation/screens/routine_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/workout_colors.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/workout_models.dart';
import '../../data/models/workout_routine.dart';
import '../providers/routine_provider.dart';
import 'exercise_library_screen.dart';
import '../widgets/exercise_gif_image.dart';

/// Full-screen create / edit screen for a [WorkoutRoutine].
/// Pass [routine] = null to create a new one.
class RoutineEditScreen extends StatefulWidget {
  final WorkoutRoutine? routine;

  const RoutineEditScreen({super.key, this.routine});

  @override
  State<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends State<RoutineEditScreen> {
  final _uuid = const Uuid();
  late final TextEditingController _nameController;
  late List<RoutineExercise> _exercises;
  bool _isSaving = false;
  bool get _isNew => widget.routine == null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.routine?.name ?? '');
    _exercises = List.from(widget.routine?.exercises ?? []);
    if (_isNew) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => FocusScope.of(context).requestFocus(_nameFocus));
    }
  }

  final FocusNode _nameFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _addExercises() async {
    final selected = await Navigator.of(context).push<List<ExerciseLibraryItem>>(
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          selectionMode: true,
          onSelectionConfirmed: (items) => Navigator.of(context).pop(items),
        ),
      ),
    );

    if (selected == null || selected.isEmpty) return;

    final routineId = widget.routine?.id ?? _uuid.v4();
    final newExercises = selected.map((item) {
      return RoutineExercise(
        id: _uuid.v4(),
        routineId: routineId,
        exerciseId: item.id,
        exerciseName: item.name,
        muscleGroup: item.bodyPart,
        gifUrl: item.gifUrl,
        defaultSets: 3,
        defaultReps: '8-12',
        defaultWeight: null,
        sortOrder: _exercises.length,
      );
    }).toList();

    setState(() => _exercises.addAll(newExercises));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameController.text = 'New Routine';
    }
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<RoutineProvider>();
      final now = DateTime.now();
      final routineId = widget.routine?.id ?? _uuid.v4();

      final updatedExercises = _exercises.asMap().entries.map((entry) {
        final ex = entry.value;
        return RoutineExercise(
          id: ex.id.isEmpty ? _uuid.v4() : ex.id,
          routineId: routineId,
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          muscleGroup: ex.muscleGroup,
          gifUrl: ex.gifUrl,
          defaultSets: ex.defaultSets,
          defaultReps: ex.defaultReps,
          defaultWeight: ex.defaultWeight,
          sortOrder: entry.key,
        );
      }).toList();

      final routine = WorkoutRoutine(
        id: routineId,
        name: _nameController.text.trim().isEmpty
            ? 'New Routine'
            : _nameController.text.trim(),
        exercises: updatedExercises,
        createdAt: widget.routine?.createdAt ?? now,
        updatedAt: now,
      );

      await provider.saveRoutine(routine);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'),
              backgroundColor: AppColors.errorBright),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removeExercise(int index) {
    HapticFeedback.lightImpact();
    setState(() => _exercises.removeAt(index));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: WorkoutColors.scaffold(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: WorkoutColors.onSurface(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isNew ? 'New Routine' : 'Edit Routine',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WorkoutColors.primary(context),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: WorkoutColors.primaryDark(context),
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: WorkoutColors.cardDecoration(context, radius: 16),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Routine name',
                  hintStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: WorkoutColors.onSurfaceSubtle(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: WorkoutColors.primaryMuted(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_exercises.length}',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: WorkoutColors.primaryDark(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reorderable exercise list
          Expanded(
            child: _exercises.isEmpty
                ? _EmptyExerciseState(onAdd: _addExercises)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: _exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _exercises.removeAt(oldIndex);
                        _exercises.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final ex = _exercises[index];
                      return _ExerciseRow(
                        key: ValueKey(ex.id.isEmpty ? index : ex.id),
                        exercise: ex,
                        onRemove: () => _removeExercise(index),
                        onSetsChanged: (sets) {
                          setState(() {
                            _exercises[index] = RoutineExercise(
                              id: ex.id,
                              routineId: ex.routineId,
                              exerciseId: ex.exerciseId,
                              exerciseName: ex.exerciseName,
                              muscleGroup: ex.muscleGroup,
                              gifUrl: ex.gifUrl,
                              defaultSets: sets,
                              defaultReps: ex.defaultReps,
                              defaultWeight: ex.defaultWeight,
                              sortOrder: index,
                            );
                          });
                        },
                      );
                    },
                  ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: FilledButton.icon(
              onPressed: _addExercises,
              icon: Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Add exercises',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: WorkoutColors.primary(context),
                foregroundColor: WorkoutColors.onSurface(context),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  final RoutineExercise exercise;
  final VoidCallback onRemove;
  final void Function(int sets) onSetsChanged;

  const _ExerciseRow({
    super.key,
    required this.exercise,
    required this.onRemove,
    required this.onSetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: WorkoutColors.cardDecoration(context, radius: 16),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
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
                : Container(
                    color: WorkoutColors.surfaceMuted(context),
                    child: Icon(Icons.fitness_center,
                        color: WorkoutColors.onSurfaceMuted(context), size: 22),
                  ),
          ),
        ),
        title: Text(
          exercise.exerciseName,
          style: GoogleFonts.montserrat(
            color: WorkoutColors.onSurface(context),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: exercise.muscleGroup != null
            ? Text(
                exercise.muscleGroup!,
                style: GoogleFonts.montserrat(
                  color: WorkoutColors.onSurfaceMuted(context),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sets stepper
            _SetsStepper(
              sets: exercise.defaultSets,
              onChanged: onSetsChanged,
            ),
            const SizedBox(width: 8),
            // Delete
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: WorkoutColors.error(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline,
                    color: WorkoutColors.error(context), size: 18),
              ),
            ),
            const SizedBox(width: 8),
            // Drag handle
            Icon(Icons.drag_handle,
                color: WorkoutColors.onSurfaceMuted(context), size: 22),
          ],
        ),
      ),
    );
  }
}

class _SetsStepper extends StatelessWidget {
  final int sets;
  final void Function(int) onChanged;

  const _SetsStepper({required this.sets, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: sets > 1 ? () => onChanged(sets - 1) : null,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: WorkoutColors.surfaceMuted(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.remove,
              size: 14,
              color: sets > 1
                  ? WorkoutColors.onSurface(context)
                  : WorkoutColors.onSurfaceMuted(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$sets',
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurface(context),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(sets + 1),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: WorkoutColors.primary(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.add, size: 14, color: WorkoutColors.onSurface(context)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'sets',
          style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurfaceMuted(context), fontSize: 11),
        ),
      ],
    );
  }
}

class _EmptyExerciseState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExerciseState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: WorkoutColors.primaryMuted(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: WorkoutColors.primaryDark(context),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No exercises yet',
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurface(context),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add exercises from the library to build this routine.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurfaceMuted(context),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
