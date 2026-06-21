// lib/features/workout/presentation/screens/smart_workout_generator_screen.dart

import 'dart:async';
import 'package:befit/features/smart_plan/presentation/providers/smart_plan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/workout_routine.dart';
import '../../core/workout_colors.dart';

import 'smart_plan_preview_screen.dart';
import '../widgets/smart_plan_setup_wizard.dart';

class SmartWorkoutGeneratorScreen extends StatefulWidget {
  final bool isReplacingSmartPlan;

  const SmartWorkoutGeneratorScreen({
    super.key,
    this.isReplacingSmartPlan = false,
  });

  @override
  State<SmartWorkoutGeneratorScreen> createState() =>
      _SmartWorkoutGeneratorScreenState();
}

class _SmartWorkoutGeneratorScreenState
    extends State<SmartWorkoutGeneratorScreen> {
  bool _isGenerating = false;
  String? _statusText;
  bool _showWizard = true;
  double _generationProgress = 0.0;

  Future<void> _startGeneration(Map<String, dynamic> config) async {
    setState(() {
      _showWizard = false;
      _isGenerating = true;
      _generationProgress = 0.0;
      _statusText = 'Connecting to AI Engine...';
    });

    final timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted || !_isGenerating) {
        t.cancel();
        return;
      }

      setState(() {
        if (_generationProgress < 0.95) {
          _generationProgress += 0.005;
        }

        if (_generationProgress < 0.25) {
          _statusText = 'Analyzing your fitness goals...';
        } else if (_generationProgress < 0.50) {
          _statusText = 'Scanning exercise library...';
        } else if (_generationProgress < 0.75) {
          _statusText = 'Optimizing for ${config['duration']}m sessions...';
        } else if (_generationProgress < 0.95) {
          _statusText = 'Finalizing your plan...';
        } else {
          _statusText = 'Crafting your workout plan...';
        }
      });
    });

    try {
      final smartPlan = context.read<SmartPlanProvider>();
      final result = await smartPlan.generateCustomWorkoutPlan(
        goal: config['goal'],
        experience: config['experience'],
        location: config['location'],
        daysPerWeek: config['daysPerWeek'],
        durationMinutes: config['duration'],
        onStatusUpdate: (status) {
          if (mounted) setState(() => _statusText = status);
        },
      );

      timer.cancel();
      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        setState(() => _generationProgress = 1.0);
        await Future.delayed(const Duration(milliseconds: 500));

        final List<WorkoutRoutine> routinesToPreview = [];

        for (var day in result) {
          final routineId = const Uuid().v4();
          final List<RoutineExercise> processedExercises = [];

          for (var e in day.exercises) {
            processedExercises.add(
              RoutineExercise(
                id: const Uuid().v4(),
                routineId: routineId,
                exerciseId: e.exerciseId ?? 'ai_${e.name}',
                exerciseName: e.name,
                muscleGroup: e.muscleGroup,
                gifUrl: e.gifUrl,
                defaultSets: e.sets,
                defaultReps: e.reps,
              ),
            );
          }

          routinesToPreview.add(
            WorkoutRoutine(
              id: routineId,
              name: day.name,
              exercises: processedExercises,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }

        if (routinesToPreview.any((r) => r.exercises.isNotEmpty)) {
          setState(() {
            _isGenerating = false;
            _statusText = null;
          });

          if (!mounted) return;
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => SmartPlanPreviewScreen(
                    routines: routinesToPreview,
                    planName: 'Your Custom Plan',
                    description:
                        'A professional routine tailored to your goals.',
                    isReplacingSmartPlan: widget.isReplacingSmartPlan,
                  ),
                ),
              )
              .then((_) {
                if (mounted) setState(() => _showWizard = true);
              });
        } else {
          setState(() {
            _isGenerating = false;
            _statusText =
                'AI generated a plan but it contained no active workout days. Please try again.';
          });
        }
      } else {
        setState(() {
          _isGenerating = false;
          _statusText =
              'The AI engine is currently busy. Please try again in a moment.';
        });
      }
    } catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusText =
              'An unexpected connection error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      appBar: AppBar(
        title: Text(
          'AI Smart Plan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ─── Decorative Background Glow ────────────────────────────────────
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WorkoutColors.lime(context).withValues(alpha: 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms),

          // ─── Background Hero Content ──────────────────────────────────────
          if (_showWizard && !_isGenerating)
            Positioned(
              top: 40,
              left: 32,
              right: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: WorkoutColors.lime(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.magic_star,
                          size: 14,
                          color: WorkoutColors.lime(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI POWERED',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: WorkoutColors.lime(context),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isReplacingSmartPlan
                        ? 'Let\'s update your\nworkout plan'
                        : 'Let\'s build your\nperfect plan',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: WorkoutColors.onSurface(context),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isReplacingSmartPlan
                        ? 'Re-calculate your weekly schedule with our AI to match your current needs and availability.'
                        : 'Answer a few questions to help our AI craft a professional workout experience tailored just for you.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: WorkoutColors.onSurfaceMuted(context),
                      height: 1.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
            ),

          // ─── Main Content Area ─────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isGenerating) ...[
                    _buildProfessionalLoading(context),
                  ] else if (_statusText != null) ...[
                    // Error state UI
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 64,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'AI Engine Unavailable',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusText!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: WorkoutColors.onSurfaceMuted(context),
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _statusText = null;
                        _showWizard = true;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WorkoutColors.lime(context),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Try Again',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ─── Wizard Overlay ────────────────────────────────────────────────
          if (_showWizard && !_isGenerating)
            Align(
              alignment: Alignment.bottomCenter,
              child: SmartPlanSetupWizard(onComplete: _startGeneration),
            ).animate().slideY(
              begin: 1.0,
              curve: Curves.easeOutQuart,
              duration: 600.ms,
            ),
        ],
      ),
    );
  }

  Widget _buildProfessionalLoading(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WorkoutColors.lime(context).withValues(alpha: 0.05),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                )
                .fadeOut(),

            SizedBox(
              height: 200,
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_m6cu9os9.json',
                errorBuilder: (context, error, stackTrace) => Icon(
                  Iconsax.cpu_charge,
                  size: 80,
                  color: WorkoutColors.lime(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '${(_generationProgress * 100).toInt()}%',
          style: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: WorkoutColors.onSurface(context),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          _statusText ?? 'Processing...',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: WorkoutColors.lime(context),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: WorkoutColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WorkoutColors.border(context)),
          ),
          child: Column(
            children: [
              _buildStageItem(
                context,
                'Goal Analysis',
                _generationProgress > 0.25,
              ),
              const SizedBox(height: 12),
              _buildStageItem(
                context,
                'Exercise Pattern Matching',
                _generationProgress > 0.50,
              ),
              const SizedBox(height: 12),
              _buildStageItem(
                context,
                'Routine Optimization',
                _generationProgress > 0.75,
              ),
              const SizedBox(height: 12),
              _buildStageItem(
                context,
                'Final Protocol Assembly',
                _generationProgress > 0.95,
              ),
            ],
          ),
        ).animate().slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildStageItem(BuildContext context, String label, bool isComplete) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? WorkoutColors.lime(context)
                : Colors.transparent,
            border: Border.all(
              color: isComplete
                  ? WorkoutColors.lime(context)
                  : WorkoutColors.border(context),
              width: 2,
            ),
          ),
          child: isComplete
              ? const Icon(Icons.check, size: 12, color: Colors.black)
              : null,
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isComplete ? FontWeight.w700 : FontWeight.w500,
            color: isComplete
                ? WorkoutColors.onSurface(context)
                : WorkoutColors.onSurfaceMuted(context),
          ),
        ),
      ],
    );
  }
}
