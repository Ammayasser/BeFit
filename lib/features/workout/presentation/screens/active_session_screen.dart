// lib/features/workout/presentation/screens/active_session_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:befit/features/workout/presentation/screens/exercise_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

import '../providers/workout_session_provider.dart';
import '../widgets/single_exercise_view.dart';

import 'package:befit/features/workout/data/mappers/workout_mapper.dart';
import 'package:befit/features/workout/domain/entities/workout_session.dart';

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  int _currentExerciseIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final session = context.read<WorkoutSessionProvider>().session;
      if (session != null && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(session.startedAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return "$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  void _nextExercise(int total) {
    if (_currentExerciseIndex < total - 1) {
      HapticFeedback.mediumImpact();
      setState(() => _currentExerciseIndex++);
      _pageController.animateToPage(
        _currentExerciseIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevExercise() {
    if (_currentExerciseIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentExerciseIndex--);
      _pageController.animateToPage(
        _currentExerciseIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutSessionProvider>();
    final session = provider.session;
    final colors = context.customColors;
    final s = Responsive.scale(context, 1);

    if (session == null) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final totalExercises = session.exercises.length;
    final isEmpty = totalExercises == 0;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildResponsiveHeader(session, provider, s, totalExercises),
            Expanded(
              child: isEmpty
                  ? _buildEmptyState(context, s)
                  : PageView.builder(
                      controller: _pageController,
                      physics:
                          const NeverScrollableScrollPhysics(), // Only button navigation
                      itemCount: totalExercises,
                      itemBuilder: (context, index) {
                        return SingleExerciseView(
                          exercise: session.exercises[index],
                          exerciseIndex: index,
                          key: ValueKey(session.exercises[index].id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isEmpty
          ? null
          : _buildBottomAction(context, provider, s, totalExercises),
      bottomSheet: provider.state == SessionState.resting
          ? _buildRestOverlay(provider, s)
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, double s) {
    final colors = context.customColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32 * s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24 * s),
              decoration: BoxDecoration(
                color: colors.setupPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.add_square,
                size: 64 * s,
                color: colors.setupPrimary,
              ),
            ),
            SizedBox(height: 24 * s),
            Text(
              'Your Session is Empty',
              style: GoogleFonts.montserrat(
                fontSize: 22 * s,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12 * s),
            Text(
              'Add your first exercise to start tracking your progress and smashing your goals.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15 * s,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32 * s),
            ElevatedButton(
              onPressed: () => _openExercisePicker(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.setupPrimary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 32 * s,
                  vertical: 16 * s,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16 * s),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20 * s),
                  SizedBox(width: 8 * s),
                  Text(
                    'ADD EXERCISE',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 14 * s,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExercisePicker(BuildContext context) async {
    final provider = context.read<WorkoutSessionProvider>();

    // We'll navigate to the library in selection mode.
    // Since AppRouter might not have a dedicated route with these parameters,
    // we can use a direct MaterialPageRoute or update the router.
    // Using MaterialPageRoute for immediate functional fix.

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          selectionMode: true,
          onSelectionConfirmed: (selectedExercises) async {
            // Add each selected exercise to the session
            for (final ex in selectedExercises) {
              await provider.addExerciseToSession(ex);
            }
            // Go back to the session screen
            if (context.mounted) {
              Navigator.pop(context);
              // If it was empty, we might need to reset the page index if current was 0
              setState(() {
                _currentExerciseIndex = 0;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader(
    WorkoutSessionEntity session,
    WorkoutSessionProvider provider,
    double s,
    int total,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;
    final isEmpty = total == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 16 * s),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32 * s)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15 * s,
            offset: Offset(0, 4 * s),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showCancelConfirmation(context, provider),
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 24 * s,
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                isEmpty
                    ? 'QUICK START'
                    : 'EXERCISE ${_currentExerciseIndex + 1} OF $total',
                style: GoogleFonts.montserrat(
                  fontSize: 10 * s,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(_elapsed),
                style: GoogleFonts.montserrat(
                  fontSize: 22 * s,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!isEmpty)
            IconButton(
              onPressed: () => _openExercisePicker(context),
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: colorScheme.primary,
                size: 28 * s,
              ),
            )
          else
            _HeaderCircleStat(value: '0', label: 'EXS', s: s),
        ],
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    WorkoutSessionProvider provider,
    double s,
    int total,
  ) {
    final colors = context.customColors;
    final isLast = _currentExerciseIndex == total - 1;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20 * s,
        16 * s,
        20 * s,
        max(16 * s, safeBottom + 12 * s),
      ),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20 * s,
            offset: Offset(0, -5 * s),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentExerciseIndex > 0)
            Padding(
              padding: EdgeInsets.only(right: 12 * s),
              child: SizedBox(
                width: 60 * s,
                height: 56 * s,
                child: OutlinedButton(
                  onPressed: _prevExercise,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16 * s),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20 * s,
                    color: colors.setupTextPrimary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: ElevatedButton(
              onPressed: isLast
                  ? () => _showFinishConfirmation(context, provider)
                  : () => _nextExercise(total),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? colors.success : colors.setupPrimary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56 * s),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16 * s),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'FINISH WORKOUT' : 'NEXT EXERCISE',
                    style: GoogleFonts.montserrat(
                      fontSize: 15 * s,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!isLast) ...[
                    SizedBox(width: 8 * s),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16 * s),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestOverlay(WorkoutSessionProvider provider, double s) {
    final colors = context.customColors;

    return Container(
      height: 110 * s,
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32 * s)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20 * s,
            offset: Offset(0, -5 * s),
          ),
        ],
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12 * s),
            decoration: BoxDecoration(
              color: colors.setupPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: colors.setupPrimary,
              size: 24 * s,
            ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REST TIMER',
                  style: GoogleFonts.montserrat(
                    fontSize: 10 * s,
                    fontWeight: FontWeight.w800,
                    color: colors.setupTextSecondary.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${provider.restSecondsRemaining ~/ 60}:${(provider.restSecondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.montserrat(
                    fontSize: 28 * s,
                    fontWeight: FontWeight.w900,
                    color: colors.setupTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _RestAdjustButton(
                icon: Icons.remove_rounded,
                onTap: () => provider.adjustRest(-15),
                s: s,
              ),
              SizedBox(width: 8 * s),
              _RestAdjustButton(
                icon: Icons.add_rounded,
                onTap: () => provider.adjustRest(15),
                s: s,
              ),
              SizedBox(width: 16 * s),
              TextButton(
                onPressed: () => provider.skipRest(),
                style: TextButton.styleFrom(
                  backgroundColor: colors.setupPrimary.withValues(alpha: 0.1),
                  foregroundColor: colors.setupPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * s,
                    vertical: 12 * s,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14 * s),
                  ),
                ),
                child: Text(
                  'SKIP',
                  style: GoogleFonts.montserrat(
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    WorkoutSessionProvider provider,
  ) {
    final colors = context.customColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Discard Workout?',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Are you sure? All logged sets will be lost forever.',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.cancelWorkout();
              context.go(AppRoutes.workout);
            },
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmation(
    BuildContext context,
    WorkoutSessionProvider provider,
  ) {
    final colors = context.customColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.check_rounded,
                  color: colors.success,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Finish Workout?',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Amazing work! Ready to save your progress and see your stats?',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'NOT YET',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(
                        AppRoutes.workoutSummary,
                        extra: WorkoutMapper.toModelSession(provider.session!),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('SAVE WORKOUT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double s;

  const _RestAdjustButton({
    required this.icon,
    required this.onTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    return Material(
      color: colors.setupPrimary.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: EdgeInsets.all(8 * s),
          child: Icon(icon, color: colors.setupPrimary, size: 20 * s),
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

    return Column(
      children: [
        Container(
          width: 44 * s,
          height: 44 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border, width: 2),
          ),
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
              color: colors.setupTextPrimary,
            ),
          ),
        ),
        SizedBox(height: 4 * s),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 9 * s,
            fontWeight: FontWeight.w800,
            color: colors.setupTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
