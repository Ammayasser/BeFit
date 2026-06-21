import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../core/workout_user_resolver.dart';
import '../../data/models/custom_program_models.dart';
import '../providers/custom_program_provider.dart';

class CustomProgramEditorScreen extends StatefulWidget {
  final String programId;

  const CustomProgramEditorScreen({super.key, required this.programId});

  @override
  State<CustomProgramEditorScreen> createState() =>
      _CustomProgramEditorScreenState();
}

class _CustomProgramEditorScreenState extends State<CustomProgramEditorScreen> {
  CustomProgram? _program;
  int _selectedWeekIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    setState(() => _isLoading = true);
    final program = await context.read<CustomProgramProvider>().loadProgramFull(
      widget.programId,
    );
    if (mounted) {
      setState(() {
        _program = program;
        _isLoading = false;
      });
    }
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

    if (_program == null) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text(
            'Program not found',
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
        title: GestureDetector(
          onTap: _showRenameProgramDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _program!.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 18 * fs,
                    fontWeight: FontWeight.w800,
                    color: colors.setupTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6 * s),
              Icon(Iconsax.edit_2, color: colors.setupPrimary, size: 14 * s),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.save_2, color: colors.setupTextPrimary),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekTabBar(s, fs),
          Expanded(child: _buildDayGrid(s, fs)),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(s, fs, bottomSafe),
    );
  }

  Widget _buildWeekTabBar(double s, double fs) {
    final colors = context.customColors;
    return SizedBox(
      height: 60 * s,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 10 * s),
        itemCount: _program!.totalWeeks,
        itemBuilder: (_, i) {
          final isSelected = i == _selectedWeekIndex;
          final week = _program!.weeks[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedWeekIndex = i),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: EdgeInsets.only(right: 8 * s),
              padding: EdgeInsets.symmetric(
                horizontal: 16 * s,
                vertical: 6 * s,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.setupPrimary : colors.bgSecondary,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? colors.setupPrimary
                      : colors.border,
                ),
              ),
              child: Center(
                child: Text(
                  week.displayName,
                  style: GoogleFonts.montserrat(
                    fontSize: 12 * fs,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.setupOnPrimary : colors.setupTextSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayGrid(double s, double fs) {
    final week = _program!.weeks[_selectedWeekIndex];

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 100 * s),
      itemCount: week.days.length,
      itemBuilder: (_, i) {
        final day = week.days[i];
        return _DayEditorCard(
          day: day,
          onTap: () => _openDayEditor(day),
          onRestToggle: () => _toggleRestDay(day),
          onRename: () => _showRenameDayDialog(day),
          index: i,
        );
      },
    );
  }

  Widget _buildBottomActionBar(double s, double fs, double bottomSafe) {
    final colors = context.customColors;
    final isLastWeek = _selectedWeekIndex == _program!.totalWeeks - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, bottomSafe + 12 * s),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLastWeek ? null : _duplicateWeek,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isLastWeek
                      ? colors.border
                      : colors.setupPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 14 * s),
              ),
              child: Text(
                'Copy Week →',
                style: GoogleFonts.montserrat(
                  fontSize: 13 * fs,
                  fontWeight: FontWeight.w700,
                  color: isLastWeek
                      ? colors.setupTextSecondary
                      : colors.setupPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                height: 48 * s,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.setupPrimary, colors.setupPrimary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Save Program',
                    style: GoogleFonts.montserrat(
                      fontSize: 14 * fs,
                      fontWeight: FontWeight.w800,
                      color: colors.setupOnPrimary,
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

  void _openDayEditor(ProgramDay day) async {
    await context.push(
      '${AppRoutes.customPrograms}/${_program!.id}/day/${day.id}',
    );
    _loadProgram(); // Refresh when returning
  }

  void _toggleRestDay(ProgramDay day) async {
    await context.read<CustomProgramProvider>().updateDayRestStatus(
      day,
      !day.isRestDay,
    );
    _loadProgram();
  }

  void _showRenameProgramDialog() {
    final colors = context.customColors;
    final controller = TextEditingController(text: _program!.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text(
          'Rename Program',
          style: GoogleFonts.montserrat(color: colors.setupTextPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.setupTextPrimary),
          decoration: InputDecoration(
            hintText: 'Program name',
            hintStyle: TextStyle(color: colors.setupTextSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await context.read<CustomProgramProvider>().updateProgramMeta(
                  _program!.copyWith(name: controller.text.trim()),
                );
                Navigator.pop(context);
                _loadProgram();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRenameDayDialog(ProgramDay day) {
    final colors = context.customColors;
    final controller = TextEditingController(text: day.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text(
          'Rename Day',
          style: GoogleFonts.montserrat(color: colors.setupTextPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.setupTextPrimary),
          decoration: InputDecoration(
            hintText: 'Day name (e.g. Push Day)',
            hintStyle: TextStyle(color: colors.setupTextSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await context.read<CustomProgramProvider>().updateDayName(
                  day,
                  controller.text.trim(),
                );
                Navigator.pop(context);
                _loadProgram();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _duplicateWeek() async {
    final currentWeek = _program!.weeks[_selectedWeekIndex];
    final nextWeek = _program!.weeks[_selectedWeekIndex + 1];
    final userId = WorkoutUserResolver.resolve(context);
    final provider = context.read<CustomProgramProvider>();

    for (int i = 0; i < currentWeek.days.length; i++) {
      final sourceDay = currentWeek.days[i];
      final targetDay = nextWeek.days[i];

      // Copy exercises
      final newExercises = sourceDay.exercises
          .map(
            (ex) =>
                ex.copyWith(id: const Uuid().v4(), programDayId: targetDay.id),
          )
          .toList();

      await provider.saveDayExercises(targetDay.id, newExercises, userId);

      // Also copy rest status and name if it's not the default "Day X"
      if (sourceDay.isRestDay != targetDay.isRestDay ||
          sourceDay.name != targetDay.name) {
        await provider.updateDayRestStatus(targetDay, sourceDay.isRestDay);
        await provider.updateDayName(targetDay, sourceDay.name);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${currentWeek.displayName} to ${nextWeek.displayName}',
        ),
      ),
    );
    _loadProgram();
  }
}

class _DayEditorCard extends StatelessWidget {
  final ProgramDay day;
  final VoidCallback onTap;
  final VoidCallback onRestToggle;
  final VoidCallback onRename;
  final int index;

  const _DayEditorCard({
    required this.day,
    required this.onTap,
    required this.onRestToggle,
    required this.onRename,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return Container(
          margin: EdgeInsets.only(bottom: 12 * s),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16 * s,
                  14 * s,
                  16 * s,
                  day.isRestDay ? 14 * s : 8 * s,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32 * s,
                      height: 32 * s,
                      decoration: BoxDecoration(
                        color: day.isRestDay
                            ? colors.border
                            : colors.setupPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.dayNumber}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13 * fs,
                            fontWeight: FontWeight.w800,
                            color: day.isRestDay
                                ? colors.setupTextSecondary
                                : colors.setupPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: GestureDetector(
                        onTap: onRename,
                        child: Text(
                          day.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 15 * fs,
                            fontWeight: FontWeight.w700,
                            color: colors.setupTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onRestToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: day.isRestDay
                              ? colors.border
                              : colors.bgSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          day.isRestDay ? '😴 Rest' : 'Set Rest',
                          style: GoogleFonts.inter(
                            fontSize: 11 * fs,
                            color: colors.setupTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!day.isRestDay) ...[
                if (day.exercises.isEmpty)
                  _AddExercisesPrompt(onTap: onTap)
                else
                  _ExerciseChipsPreview(exercises: day.exercises),
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 14 * s),
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.setupPrimary.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.edit_2,
                            color: colors.setupPrimary,
                            size: 15 * s,
                          ),
                          SizedBox(width: 6 * s),
                          Text(
                            day.exercises.isEmpty
                                ? 'Add Exercises'
                                : 'Edit Day',
                            style: GoogleFonts.montserrat(
                              fontSize: 13 * fs,
                              fontWeight: FontWeight.w700,
                              color: colors.setupPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08);
  }
}

class _ExerciseChipsPreview extends StatelessWidget {
  final List<ProgramDayExercise> exercises;

  const _ExerciseChipsPreview({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * s),
      child: Wrap(
        spacing: 6 * s,
        runSpacing: 6 * s,
        children: [
          ...exercises
              .take(3)
              .map(
                (ex) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ex.exerciseName.length > 14
                        ? '${ex.exerciseName.substring(0, 12)}...'
                        : ex.exerciseName,
                    style: GoogleFonts.montserrat(
                      fontSize: 10 * fs,
                      fontWeight: FontWeight.w600,
                      color: colors.setupTextSecondary,
                    ),
                  ),
                ),
              ),
          if (exercises.length > 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${exercises.length - 3}',
                style: GoogleFonts.montserrat(
                  fontSize: 10 * fs,
                  fontWeight: FontWeight.w600,
                  color: colors.setupPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddExercisesPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExercisesPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14 * s),
        margin: EdgeInsets.symmetric(horizontal: 16 * s),
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.border,
            style: BorderStyle.none,
          ), // dashed border not supported directly in BoxDecoration
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.add_circle,
              color: colors.setupTextSecondary,
              size: 18 * s,
            ),
            SizedBox(width: 8 * s),
            Text(
              'Tap to add exercises',
              style: GoogleFonts.inter(
                fontSize: 13 * fs,
                color: colors.setupTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
