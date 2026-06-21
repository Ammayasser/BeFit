import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/features/workout/data/repositories/custom_program_repository.dart';
import 'package:befit/features/workout/presentation/providers/exercise_library_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../core/workout_user_resolver.dart';
import '../../data/models/custom_program_models.dart';
import '../../data/models/workout_models.dart';
import '../providers/custom_program_provider.dart';
import '../providers/workout_session_provider.dart';
import '../widgets/exercise_gif_image.dart';
import '../widgets/exercise_detail_sheet.dart';
import 'exercise_library_screen.dart';

class CustomProgramDayScreen extends StatefulWidget {
  final String programId;
  final String dayId;

  const CustomProgramDayScreen({
    super.key,
    required this.programId,
    required this.dayId,
  });

  @override
  State<CustomProgramDayScreen> createState() => _CustomProgramDayScreenState();
}

class _CustomProgramDayScreenState extends State<CustomProgramDayScreen> {
  ProgramDay? _day;
  List<ProgramDayExercise> _exercises = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadDay();
  }

  Future<void> _loadDay() async {
    setState(() => _isLoading = true);
    final repo =
        CustomProgramRepository(); // Direct repo access for full load or use provider
    final day = await repo.getDayFull(widget.dayId);
    if (mounted) {
      setState(() {
        _day = day;
        _exercises = List.from(day?.exercises ?? []);
        _isLoading = false;
      });
    }
  }

  Future<void> _autosave() async {
    if (_day == null) return;
    setState(() => _isSaving = true);
    final userId = WorkoutUserResolver.resolve(context);
    await context.read<CustomProgramProvider>().saveDayExercises(
      _day!.id,
      _exercises,
      userId,
    );
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _addExercises() async {
    final selected = await Navigator.of(context)
        .push<List<ExerciseLibraryItem>>(
          MaterialPageRoute(
            builder: (_) => ExerciseLibraryScreen(
              selectionMode: true,
              onSelectionConfirmed: (items) => Navigator.of(context).pop(items),
            ),
          ),
        );

    if (selected == null || selected.isEmpty) return;

    setState(() {
      for (final item in selected) {
        _exercises.add(
          ProgramDayExercise(
            id: _uuid.v4(),
            programDayId: widget.dayId,
            exerciseId: item.id,
            exerciseName: item.name,
            muscleGroup: item.bodyPart,
            gifUrl: item.gifUrl,
            sets: 3,
            reps: '8-12',
            restSeconds: 90,
            sortOrder: _exercises.length,
          ),
        );
      }
    });
    _autosave();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_day == null) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: Center(
          child: Text(
            'Day not found',
            style: TextStyle(color: colors.setupTextPrimary),
          ),
        ),
      );
    }

    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.setupTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _day!.name,
              style: GoogleFonts.montserrat(
                fontSize: 16 * fs,
                fontWeight: FontWeight.w800,
                color: colors.setupTextPrimary,
              ),
            ),
            Text(
              'Day ${_day!.dayNumber}',
              style: GoogleFonts.inter(
                fontSize: 11 * fs,
                color: colors.setupTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.setupPrimary,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Iconsax.add_circle, color: colors.setupPrimary),
            onPressed: _addExercises,
          ),
        ],
      ),
      body: _exercises.isEmpty
          ? _buildEmptyState(s, fs)
          : _buildExerciseList(s, fs),
      bottomNavigationBar: _buildBottomBar(s, fs, bottomSafe),
    );
  }

  Widget _buildEmptyState(double s, double fs) {
    final colors = context.customColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.weight, size: 64 * s, color: colors.surfaceElevated),
          SizedBox(height: 16 * s),
          Text(
            'No exercises added',
            style: GoogleFonts.montserrat(
              fontSize: 18 * fs,
              fontWeight: FontWeight.w700,
              color: colors.setupTextSecondary,
            ),
          ),
          SizedBox(height: 24 * s),
          ElevatedButton.icon(
            onPressed: _addExercises,
            icon: const Icon(Iconsax.add),
            label: const Text('Add Exercises'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.setupPrimary,
              foregroundColor: colors.setupOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(double s, double fs) {
    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 120 * s),
      itemCount: _exercises.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _exercises.removeAt(oldIndex);
          _exercises.insert(newIndex, item);
        });
        _autosave();
      },
      itemBuilder: (context, index) {
        final ex = _exercises[index];
        return _ProgramExerciseRow(
          key: ValueKey(ex.id),
          exercise: ex,
          index: index,
          onRemove: () {
            setState(() => _exercises.removeAt(index));
            _autosave();
          },
          onSetsChanged: (v) {
            setState(() => _exercises[index] = ex.copyWith(sets: v));
            _autosave();
          },
          onRepsChanged: () => _showRepsBottomSheet(ex, index),
          onRestChanged: () => _showRestPicker(ex, index),
          onTap: () => _showExerciseDetail(ex),
        );
      },
    );
  }

  Widget _buildBottomBar(double s, double fs, double bottomSafe) {
    final colors = context.customColors;
    final totalSets = _exercises.fold(0, (sum, ex) => sum + ex.sets);
    final estimatedMin = _day!.estimatedMinutes;

    return Container(
      padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, bottomSafe + 12 * s),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatPill('${_exercises.length}', 'Exercises', fs),
              _StatPill('$totalSets', 'Total Sets', fs),
              _StatPill('~${estimatedMin}m', 'Est. Time', fs),
            ],
          ),
          SizedBox(height: 16 * s),
          GestureDetector(
            onTap: _startWorkout,
            child: Container(
              width: double.infinity,
              height: 54 * s,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.setupPrimary,
                    colors.setupPrimary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.setupPrimary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.flash_1, color: colors.setupOnPrimary, size: 20),
                  SizedBox(width: 8 * s),
                  Text(
                    'Start Workout',
                    style: GoogleFonts.montserrat(
                      fontSize: 16 * fs,
                      fontWeight: FontWeight.w900,
                      color: colors.setupOnPrimary,
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

  Widget _StatPill(String value, String label, double fs) {
    final colors = context.customColors;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16 * fs,
            fontWeight: FontWeight.w800,
            color: colors.setupTextPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11 * fs,
            color: colors.setupTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showRepsBottomSheet(ProgramDayExercise ex, int index) {
    final colors = context.customColors;
    final options = [
      '5',
      '6',
      '8',
      '10',
      '12',
      '15',
      '20',
      '25',
      '30',
      'AMRAP',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Reps',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.setupTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options
                  .map(
                    (opt) => GestureDetector(
                      onTap: () {
                        setState(
                          () => _exercises[index] = ex.copyWith(reps: opt),
                        );
                        Navigator.pop(context);
                        _autosave();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ex.reps == opt
                              ? colors.setupPrimary
                              : colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ex.reps == opt
                                ? colors.setupPrimary
                                : colors.border,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            color: ex.reps == opt
                                ? colors.setupOnPrimary
                                : colors.setupTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showRestPicker(ProgramDayExercise ex, int index) {
    final colors = context.customColors;
    final options = [
      {'label': '60s', 'value': 60},
      {'label': '90s', 'value': 90},
      {'label': '2m', 'value': 120},
      {'label': '3m', 'value': 180},
      {'label': '4m', 'value': 240},
      {'label': '5m', 'value': 300},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rest Duration',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.setupTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((opt) {
                final isSelected = ex.restSeconds == opt['value'];
                return GestureDetector(
                  onTap: () {
                    setState(
                      () => _exercises[index] = ex.copyWith(
                        restSeconds: opt['value'] as int,
                      ),
                    );
                    Navigator.pop(context);
                    _autosave();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.setupPrimary
                          : colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? colors.setupPrimary : colors.border,
                      ),
                    ),
                    child: Text(
                      opt['label'] as String,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colors.setupOnPrimary
                            : colors.setupTextSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(ProgramDayExercise ex) {
    // In a real app, you'd fetch the full ExerciseLibraryItem by ex.exerciseId
    // For now, we'll try to find it from the provider if loaded or just show a basic sheet
    final item = context.read<ExerciseLibraryProvider>().exercises.firstWhere(
      (e) => e.id == ex.exerciseId,
      orElse: () => ExerciseLibraryItem(
        id: ex.exerciseId,
        name: ex.exerciseName,
        bodyPart: ex.muscleGroup ?? '',
        target: '',
        primaryMuscles: [],
        secondaryMuscles: [],
        instructions: [],
        images: [],
        proTips: [],
        gifUrl: ex.gifUrl ?? '',
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: item),
    );
  }

  Future<void> _startWorkout() async {
    HapticFeedback.mediumImpact();
    final workoutExercises = _exercises
        .map((e) => e.toWorkoutExercise())
        .toList();
    final sessionProvider = context.read<WorkoutSessionProvider>();
    final authProvider = context.read<AuthProvider>();

    await sessionProvider.startSession(
      _day!.name,
      authProvider.userId ?? '',
      workoutExercises,
    );

    if (!mounted) return;
    context.push(AppRoutes.workoutSession).then((_) {
      // After the workout session completes and pops back:
      final programProvider = context.read<CustomProgramProvider>();
      final program = programProvider.activeProgram;
      if (program != null) {
        programProvider.completeDay(_day!.id, program);
      }
    });
  }
}

class _ProgramExerciseRow extends StatelessWidget {
  final ProgramDayExercise exercise;
  final int index;
  final VoidCallback onRemove;
  final Function(int) onSetsChanged;
  final VoidCallback onRepsChanged;
  final VoidCallback onRestChanged;
  final VoidCallback onTap;

  const _ProgramExerciseRow({
    super.key,
    required this.exercise,
    required this.index,
    required this.onRemove,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onRestChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return Container(
      margin: EdgeInsets.only(bottom: 10 * s),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(12 * s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ExerciseGifImage(
                  imageUrl: exercise.gifUrl,
                  width: 56 * s,
                  height: 56 * s,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseName,
                    style: GoogleFonts.montserrat(
                      fontSize: 14 * fs,
                      fontWeight: FontWeight.w700,
                      color: colors.setupTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.muscleGroup != null)
                    Text(
                      exercise.muscleGroup!,
                      style: GoogleFonts.inter(
                        fontSize: 11 * fs,
                        color: colors.setupTextSecondary,
                      ),
                    ),
                  SizedBox(height: 10 * s),
                  Wrap(
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _SetsStepper(
                        sets: exercise.sets,
                        onChanged: onSetsChanged,
                        s: s,
                        fs: fs,
                      ),
                      _ActionChip(
                        label: '${exercise.reps} reps',
                        onTap: onRepsChanged,
                        s: s,
                        fs: fs,
                      ),
                      _ActionChip(
                        label: _formatRest(exercise.restSeconds),
                        onTap: onRestChanged,
                        s: s,
                        fs: fs,
                        icon: Iconsax.timer_1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Iconsax.trash, color: colors.error, size: 18),
                ),
                SizedBox(height: 12 * s),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: colors.setupTextSecondary.withValues(alpha: 0.5),
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRest(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    if (remainingSecs == 0) return '${mins}m';
    return '${mins}m ${remainingSecs}s';
  }
}

class _SetsStepper extends StatelessWidget {
  final int sets;
  final Function(int) onChanged;
  final double s;
  final double fs;

  const _SetsStepper({
    required this.sets,
    required this.onChanged,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: sets > 1 ? () => onChanged(sets - 1) : null,
            s: s,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '$sets',
              style: GoogleFonts.montserrat(
                fontSize: 11 * fs,
                fontWeight: FontWeight.w700,
                color: colors.setupTextPrimary,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: sets < 10 ? () => onChanged(sets + 1) : null,
            s: s,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double s;

  const _StepButton({required this.icon, this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22 * s,
        height: 22 * s,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : colors.border,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14 * s,
          color: onTap == null
              ? colors.setupTextSecondary
              : colors.setupTextPrimary,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double s;
  final double fs;
  final IconData? icon;

  const _ActionChip({
    required this.label,
    required this.onTap,
    required this.s,
    required this.fs,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12 * s, color: colors.setupTextSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11 * fs,
                fontWeight: FontWeight.w700,
                color: colors.setupTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
