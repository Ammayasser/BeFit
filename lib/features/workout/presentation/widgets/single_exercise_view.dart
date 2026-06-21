// lib/features/workout/presentation/widgets/single_exercise_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/mappers/workout_mapper.dart';
import '../../data/models/workout_models.dart';
import '../../domain/entities/workout_session.dart';
import '../providers/workout_session_provider.dart';
import '../providers/workout_history_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/workout_hub_provider.dart';
import '../widgets/exercise_gif_image.dart';
import '../widgets/fitbod_muscle_diagram.dart';

class SingleExerciseView extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;

  const SingleExerciseView({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
  });

  @override
  State<SingleExerciseView> createState() => _SingleExerciseViewState();
}

class _SingleExerciseViewState extends State<SingleExerciseView> {
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};
  List<WorkoutSet> _previousSets = [];
  ExerciseLibraryItem? _libraryDetails;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadLibraryDetails();
  }

  void _syncControllers() {
    final sets = widget.exercise.loggedSets;
    for (int i = 0; i < sets.length; i++) {
      if (!_weightControllers.containsKey(i)) {
        final weightVal = sets[i].weightKg;
        _weightControllers[i] = TextEditingController(
          text: weightVal == 0.0
              ? ''
              : weightVal.toStringAsFixed(weightVal % 1 == 0 ? 0 : 1),
        );
      }
      if (!_repsControllers.containsKey(i)) {
        final repsVal = sets[i].reps;
        _repsControllers[i] = TextEditingController(
          text: repsVal == 0 ? '' : repsVal.toString(),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    final historyProvider = context.read<WorkoutHistoryProvider>();
    final authProvider = context.read<AuthProvider>();
    final sets = await historyProvider.getExerciseHistory(
      widget.exercise.name,
      authProvider.userId ?? '',
    );

    if (mounted) {
      setState(() {
        if (sets.isNotEmpty) {
          final lastDate = sets.last.loggedAt;
          _previousSets = sets
              .where(
                (s) =>
                    s.loggedAt.year == lastDate.year &&
                    s.loggedAt.month == lastDate.month &&
                    s.loggedAt.day == lastDate.day,
              )
              .map(WorkoutMapper.toEntitySet)
              .toList();
        }
      });
    }
  }

  Future<void> _loadLibraryDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingDetails = true);
    try {
      final library = context.read<ExerciseLibraryProvider>();

      // If library is empty, try to load it
      if (library.exercises.isEmpty) {
        await library.loadExercises();
      }

      // Find the exercise by name in the library to get instructions
      final items = library.exercises
          .where(
            (e) =>
                e.name.toLowerCase().trim() ==
                widget.exercise.name.toLowerCase().trim(),
          )
          .toList();

      if (items.isNotEmpty) {
        setState(() => _libraryDetails = items.first);
        debugPrint(
          '[SingleExerciseView] Loaded library details for ${widget.exercise.name}. Video: ${_libraryDetails?.videoUrl}',
        );
      } else {
        debugPrint(
          '[SingleExerciseView] Could not find library details for ${widget.exercise.name}',
        );
      }
    } catch (e) {
      debugPrint('[SingleExerciseView] Error loading library details: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  void dispose() {
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildRecoveryDot(BuildContext context, String? muscleGroup) {
    if (muscleGroup == null) return const SizedBox.shrink();

    final hub = context.watch<WorkoutHubProvider>();
    final recoveryState = hub.stats.fullBodyRecoveryState;
    if (recoveryState == null) return const SizedBox.shrink();

    final key = muscleGroup.toLowerCase().trim();
    String resolvedKey = key;
    if (key.contains('pec') || key.contains('chest')) {
      resolvedKey = 'chest';
    } else if (key.contains('lat') || key.contains('back')) {
      resolvedKey = 'back';
    } else if (key.contains('bicep')) {
      resolvedKey = 'biceps';
    } else if (key.contains('tricep')) {
      resolvedKey = 'triceps';
    } else if (key.contains('shoulder') || key.contains('deltoid')) {
      resolvedKey = 'shoulders';
    } else if (key.contains('quad')) {
      resolvedKey = 'quadriceps';
    } else if (key.contains('hamstring')) {
      resolvedKey = 'hamstrings';
    } else if (key.contains('calf') || key.contains('calves')) {
      resolvedKey = 'calves';
    } else if (key.contains('glute')) {
      resolvedKey = 'glutes';
    } else if (key.contains('abs') || key.contains('core')) {
      resolvedKey = 'abs';
    }

    final state = recoveryState.muscles[resolvedKey];
    if (state == null || state.recentEngagements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: '${state.muscleName}: ${state.recoveryTier.name}',
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(color: state.color, shape: BoxShape.circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    _syncControllers();
    final provider = context.watch<WorkoutSessionProvider>();

    final instructions = _libraryDetails?.instructions ?? [];
    final secondaryMuscles = _libraryDetails?.secondaryMuscles ?? [];
    final mediaUrl =
        _libraryDetails?.videoUrl ??
        _libraryDetails?.gifUrl ??
        widget.exercise.gifUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        if (isWide) {
          return _buildWideLayout(
              context, provider, instructions, secondaryMuscles, mediaUrl, s);
        } else {
          return _buildNarrowLayout(
              context, provider, instructions, secondaryMuscles, mediaUrl, s);
        }
      },
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    WorkoutSessionProvider provider,
    List<String> instructions,
    List<String> secondaryMuscles,
    String? mediaUrl,
    double s,
  ) {
    final colors = context.customColors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 20 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Section
          ExerciseGifImage(
            imageUrl: mediaUrl,
            width: double.infinity,
            height: 220 * s,
            borderRadius: BorderRadius.circular(24 * s),
          ),

          SizedBox(height: 24 * s),

          // Title and Muscles
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.exercise.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w900,
                    color: colors.setupTextPrimary,
                    height: 1.1,
                  ),
                ),
              ),
              _buildRecoveryDot(context, widget.exercise.muscleGroup),
            ],
          ),
          if (widget.exercise.muscleGroup != null) ...[
            SizedBox(height: 8 * s),
            Text(
              widget.exercise.muscleGroup!.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 12 * s,
                fontWeight: FontWeight.w700,
                color: colors.setupPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ],

          SizedBox(height: 32 * s),

          // Logging Section (Moved Up - directly under video/title)
          Row(
            children: [
              Text(
                'LOG SETS',
                style: GoogleFonts.montserrat(
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w800,
                  color: colors.setupTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _HeaderCircleStat(
                value: '${widget.exercise.loggedSets.length}',
                label: 'SETS',
                s: 0.8 * s,
              ),
            ],
          ),
          SizedBox(height: 16 * s),
          _buildSetTable(provider, s),

          // Add Set Button
          SizedBox(height: 16 * s),
          InkWell(
            onTap: () => provider.addEmptySet(widget.exerciseIndex),
            borderRadius: BorderRadius.circular(16 * s),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14 * s),
              decoration: BoxDecoration(
                color: colors.setupPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16 * s),
                border: Border.all(
                    color: colors.setupPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: colors.setupPrimary,
                    size: 20 * s,
                  ),
                  SizedBox(width: 8 * s),
                  Text(
                    'ADD NEW SET',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 12 * s,
                      color: colors.setupPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 32 * s),

          // Muscle Diagram
          Container(
            padding: EdgeInsets.all(16 * s),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: FitbodMuscleDiagram(
              primaryMuscle: widget.exercise.muscleGroup ?? '',
              secondaryMuscles: secondaryMuscles,
            ),
          ),

          SizedBox(height: 24 * s),

          // Instructions Section
          Text(
            'INSTRUCTIONS',
            style: GoogleFonts.montserrat(
              fontSize: 12 * s,
              fontWeight: FontWeight.w800,
              color: colors.setupTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12 * s),
          if (_isLoadingDetails)
            const LinearProgressIndicator(minHeight: 2)
          else if (instructions.isEmpty)
            Text(
              'No specific instructions available for this exercise.',
              style: GoogleFonts.inter(
                fontSize: 14 * s,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: colors.setupTextPrimary.withValues(alpha: 0.5),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: instructions.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8 * s),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: GoogleFonts.inter(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.bold,
                          color: colors.setupPrimary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            fontSize: 14 * s,
                            height: 1.5,
                            color:
                                colors.setupTextPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 40 * s),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    WorkoutSessionProvider provider,
    List<String> instructions,
    List<String> secondaryMuscles,
    String? mediaUrl,
    double s,
  ) {
    final colors = context.customColors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 20 * s),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Media & Muscle Diagram (width 9 flex)
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExerciseGifImage(
                      imageUrl: mediaUrl,
                      width: double.infinity,
                      height: 280 * s,
                      borderRadius: BorderRadius.circular(24 * s),
                    ),
                    SizedBox(height: 24 * s),
                    Container(
                      padding: EdgeInsets.all(16 * s),
                      decoration: BoxDecoration(
                        color: colors.bgSecondary,
                        borderRadius: BorderRadius.circular(20 * s),
                        border: Border.all(
                            color: colors.border.withValues(alpha: 0.5)),
                      ),
                      child: FitbodMuscleDiagram(
                        primaryMuscle: widget.exercise.muscleGroup ?? '',
                        secondaryMuscles: secondaryMuscles,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24 * s),
              // Right Column: Title, Sets Table, Instructions (width 11 flex)
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Muscles
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.exercise.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 26 * s,
                              fontWeight: FontWeight.w900,
                              color: colors.setupTextPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                        _buildRecoveryDot(context, widget.exercise.muscleGroup),
                      ],
                    ),
                    if (widget.exercise.muscleGroup != null) ...[
                      SizedBox(height: 8 * s),
                      Text(
                        widget.exercise.muscleGroup!.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w700,
                          color: colors.setupPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],

                    SizedBox(height: 24 * s),

                    // Logging Section
                    Row(
                      children: [
                        Text(
                          'LOG SETS',
                          style: GoogleFonts.montserrat(
                            fontSize: 12 * s,
                            fontWeight: FontWeight.w800,
                            color: colors.setupTextSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        _HeaderCircleStat(
                          value: '${widget.exercise.loggedSets.length}',
                          label: 'SETS',
                          s: 0.8 * s,
                        ),
                      ],
                    ),
                    SizedBox(height: 16 * s),
                    _buildSetTable(provider, s),

                    // Add Set Button
                    SizedBox(height: 16 * s),
                    InkWell(
                      onTap: () => provider.addEmptySet(widget.exerciseIndex),
                      borderRadius: BorderRadius.circular(16 * s),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14 * s),
                        decoration: BoxDecoration(
                          color: colors.setupPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16 * s),
                          border: Border.all(
                              color:
                                  colors.setupPrimary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: colors.setupPrimary,
                              size: 20 * s,
                            ),
                            SizedBox(width: 8 * s),
                            Text(
                              'ADD NEW SET',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w800,
                                fontSize: 12 * s,
                                color: colors.setupPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32 * s),

                    // Instructions Section
                    Text(
                      'INSTRUCTIONS',
                      style: GoogleFonts.montserrat(
                        fontSize: 12 * s,
                        fontWeight: FontWeight.w800,
                        color: colors.setupTextSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 12 * s),
                    if (_isLoadingDetails)
                      const LinearProgressIndicator(minHeight: 2)
                    else if (instructions.isEmpty)
                      Text(
                        'No specific instructions available for this exercise.',
                        style: GoogleFonts.inter(
                          fontSize: 14 * s,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                          color: colors.setupTextPrimary.withValues(alpha: 0.5),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: instructions.asMap().entries.map((entry) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8 * s),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key + 1}. ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14 * s,
                                    fontWeight: FontWeight.bold,
                                    color: colors.setupPrimary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: GoogleFonts.inter(
                                      fontSize: 14 * s,
                                      height: 1.5,
                                      color: colors.setupTextPrimary
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: 40 * s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetTable(WorkoutSessionProvider provider, double s) {
    final sets = widget.exercise.loggedSets;
    final colors = context.customColors;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0 * s),
          child: Row(
            children: [
              SizedBox(
                width: 24 * s,
                child: Text(
                  'SET',
                  style: GoogleFonts.montserrat(
                    fontSize: 9 * s,
                    fontWeight: FontWeight.w800,
                    color: colors.setupTextSecondary,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Expanded(
                child: Text(
                  'PREV',
                  style: GoogleFonts.montserrat(
                    fontSize: 9 * s,
                    fontWeight: FontWeight.w800,
                    color: colors.setupTextSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 64 * s,
                child: Center(
                  child: Text(
                    'KG',
                    style: GoogleFonts.montserrat(
                      fontSize: 9 * s,
                      fontWeight: FontWeight.w800,
                      color: colors.setupTextSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              SizedBox(
                width: 64 * s,
                child: Center(
                  child: Text(
                    'REPS',
                    style: GoogleFonts.montserrat(
                      fontSize: 9 * s,
                      fontWeight: FontWeight.w800,
                      color: colors.setupTextSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 40 * s),
              SizedBox(width: 28 * s),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < sets.length; i++)
          _buildSetRow(sets[i], i, provider, s),
      ],
    );
  }

  Widget _buildSetRow(
    WorkoutSet set,
    int index,
    WorkoutSessionProvider provider,
    double s,
  ) {
    String previousPerf = "—";
    if (index < _previousSets.length) {
      final prev = _previousSets[index];
      previousPerf =
          "${prev.weightKg.toStringAsFixed(prev.weightKg % 1 == 0 ? 0 : 1)}k";
    }

    final isCompleted = set.isCompleted;
    final weightController = _weightControllers[index];
    final repsController = _repsControllers[index];
    final colors = context.customColors;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6 * s, horizontal: 8 * s),
      margin: EdgeInsets.only(bottom: 4 * s),
      decoration: BoxDecoration(
        color: isCompleted
            ? colors.success.withValues(alpha: 0.08)
            : colors.bgSecondary,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(
          color: isCompleted
              ? colors.success.withValues(alpha: 0.2)
              : colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24 * s,
            child: Text(
              '${set.setNumber}',
              style: GoogleFonts.montserrat(
                fontSize: 13 * s,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 8 * s),
          Expanded(
            child: Text(
              previousPerf,
              style: GoogleFonts.montserrat(
                fontSize: 12 * s,
                color: colors.setupTextSecondary,
              ),
            ),
          ),
          _buildSetInput(weightController, isCompleted, (v) {
            provider.editSet(
              widget.exerciseIndex,
              index,
              double.tryParse(v) ?? 0,
              int.tryParse(repsController?.text ?? '') ?? 0,
            );
          }, s),
          SizedBox(width: 8 * s),
          _buildSetInput(
            repsController,
            isCompleted,
            (v) {
              provider.editSet(
                widget.exerciseIndex,
                index,
                double.tryParse(weightController?.text ?? '') ?? 0,
                int.tryParse(v) ?? 0,
              );
            },
            s,
            isReps: true,
          ),
          SizedBox(width: 12 * s),
          GestureDetector(
            onTap: () {
              final weight =
                  double.tryParse(weightController?.text ?? '') ?? 0.0;
              final reps = int.tryParse(repsController?.text ?? '') ?? 0;
              provider.toggleSetCompleted(
                widget.exerciseIndex,
                index,
                weight,
                reps,
                !isCompleted,
              );
              if (!isCompleted) HapticFeedback.selectionClick();
            },
            child: Container(
              width: 28 * s,
              height: 28 * s,
              decoration: BoxDecoration(
                color: isCompleted ? colors.success : colors.bgPrimary,
                borderRadius: BorderRadius.circular(8 * s),
              ),
              child: Icon(
                Icons.check_rounded,
                color: isCompleted
                    ? Colors.white
                    : colors.setupTextSecondary.withValues(alpha: 0.3),
                size: 16 * s,
              ),
            ),
          ),
          SizedBox(width: 8 * s),
          IconButton(
            onPressed: () => provider.deleteSet(widget.exerciseIndex, index),
            icon: Icon(
              Iconsax.trash,
              size: 16 * s,
              color: colors.error.withValues(alpha: 0.5),
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 28 * s),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInput(
    TextEditingController? ctrl,
    bool isCompleted,
    Function(String) onChanged,
    double s, {
    bool isReps = false,
  }) {
    final colors = context.customColors;
    return SizedBox(
      width: 64 * s,
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        enabled: !isCompleted,
        onChanged: onChanged,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w800,
          fontSize: 14 * s,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10 * s),
          fillColor: colors.bgPrimary.withValues(alpha: 0.5),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10 * s),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleStat extends StatelessWidget {
  final String value;
  final String label;
  final double s;

  const _HeaderCircleStat({
    required this.value,
    required this.label,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40 * s,
          height: 40 * s,
          decoration: BoxDecoration(
            border: Border.all(color: colors.border, width: 2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8 * s,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
