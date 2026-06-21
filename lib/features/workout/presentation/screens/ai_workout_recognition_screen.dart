// lib/features/workout/presentation/screens/ai_workout_recognition_screen.dart
//
// COMPLETELY REWRITTEN: Professional AI Vision workout screen.
//
// Key improvements over the previous version:
//   • CustomPainter skeleton overlay drawn from live ML Kit landmarks
//     (no more base64 image overlay — instant, zero network)
//   • Real-time joint angle display on the skeleton
//   • Phase indicator (Lowering → Bottom → Raising → Top)
//   • Professional HUD with glassmorphism effects
//   • Session timer
//   • Exercise categories in the picker
//   • Camera switch button
//   • Enhanced summary dialog with quality sparkline
//   • Works offline, zero latency

import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/exercise_definitions.dart';
import '../../data/services/exercise_analyzer_service.dart';
import '../../data/services/pose_detector_service.dart';
import '../../core/workout_colors.dart';
import '../providers/ai_workout_provider.dart';

class AiWorkoutRecognitionScreen extends StatefulWidget {
  const AiWorkoutRecognitionScreen({super.key});

  @override
  State<AiWorkoutRecognitionScreen> createState() =>
      _AiWorkoutRecognitionScreenState();
}

class _AiWorkoutRecognitionScreenState
    extends State<AiWorkoutRecognitionScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiWorkoutProvider>().initialize().then((_) {
        if (mounted) {
          final provider = context.read<AiWorkoutProvider>();
          if (provider.selectedExercise == null) {
            _showExercisePicker(context, provider, required: true);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    // BUG #11 FIX: Stop session and release camera when leaving the screen.
    // The provider is global (never auto-disposed), so without this cleanup,
    // the camera keeps streaming in the background, blocking other camera
    // features and draining battery.
    try {
      final provider = context.read<AiWorkoutProvider>();
      provider.releaseCamera();
    } catch (_) {
      // Ignore — provider may be unavailable during app shutdown
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiWorkoutProvider>();
    final lime = WorkoutColors.lime(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Camera Preview ──────────────────────────────────────────────
          RepaintBoundary(
            child:
                provider.cameraController != null &&
                    provider.cameraController!.value.isInitialized
                ? CameraPreview(provider.cameraController!)
                : const _LoadingCamera(),
          ),

          // ── 2. Skeleton Overlay (CustomPainter) ────────────────────────────
          if (provider.lastPoseResult != null && provider.poseDetected)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SkeletonPainter(
                    landmarks: provider.lastPoseResult!.landmarks,
                    imageSize: provider.lastPoseResult!.imageSize,
                    isFrontCamera:
                        provider.cameraController?.description.lensDirection ==
                        CameraLensDirection.front,
                    accentColor: lime,
                    phase: provider.lastAnalysis?.phase ?? ExercisePhase.idle,
                    selectedExercise: provider.selectedExercise,
                    primaryAngle: provider.lastAnalysis?.primaryAngle,
                  ),
                ),
              ),
            )
          else if (provider.state == AiWorkoutState.active && !provider.poseDetected)
            Positioned.fill(
              child: _ScanningReticle(accentColor: lime),
            ),

          // ── 3. Dark Gradient Overlay ───────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.18, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Header HUD ──────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _HeaderIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _ExerciseChip(
                        exercise: provider.selectedExercise?.displayName,
                        phase: provider.phaseLabel,
                        isActive: provider.state == AiWorkoutState.active,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderIconButton(
                      icon: Icons.cameraswitch_outlined,
                      onTap: () => provider.switchCamera(),
                    ),
                    const SizedBox(width: 6),
                    _HeaderIconButton(
                      icon: Iconsax.setting_2,
                      onTap: () => _showExercisePicker(context, provider),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 5. Center Status Cards ─────────────────────────────────────────
          if (provider.state == AiWorkoutState.active && !provider.poseDetected)
            Center(
              child: _AiStatusCard(
                message: 'Position Yourself',
                subMessage: 'Make sure your full body is in frame',
                icon: Iconsax.scan,
                color: Colors.orange,
              ),
            ).animate().fadeIn().scale()
          else if (provider.state == AiWorkoutState.active &&
              provider.lastAnalysis == null)
            Center(
              child: _AiStatusCard(
                message: 'Analyzing...',
                subMessage: 'AI engine warming up',
                icon: Iconsax.radar,
                color: lime,
              ),
            ).animate().fadeIn().scale()
          else if (provider.state == AiWorkoutState.idle &&
              provider.selectedExercise == null)
            Center(
              child: _AiStatusCard(
                message: 'Choose an Exercise',
                subMessage: 'Tap the ⚙ button to select',
                icon: Iconsax.activity,
                color: lime,
              ),
            ).animate().fadeIn().scale(),

          // ── 6. Phase Indicator (center-bottom of camera area) ──────────────
          if (provider.state == AiWorkoutState.active &&
              provider.poseDetected &&
              provider.lastAnalysis != null)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.38,
              left: 0,
              right: 0,
              child: _PhaseIndicator(
                phase: provider.lastAnalysis!.phase,
                angle: provider.lastAnalysis!.primaryAngle,
              )
                  .animate(key: ValueKey(provider.lastAnalysis!.phase))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: 200.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 200.ms),
            ),

          // ── 7. Pause Overlay ───────────────────────────────────────────────
          if (provider.state == AiWorkoutState.paused)
            Center(
              child: _AiStatusCard(
                message: 'Paused',
                subMessage: 'Tap START to resume',
                icon: Iconsax.pause,
                color: Colors.white54,
              ),
            ).animate().fadeIn(),

          // ── 8. Bottom HUD ──────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timer
                if (provider.state == AiWorkoutState.active ||
                    provider.state == AiWorkoutState.paused)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TimerChip(duration: provider.sessionDuration),
                  ),

                // Real-time coaching tip
                if (provider.lastAnalysis != null &&
                    provider.lastAnalysis!.tips.isNotEmpty &&
                    provider.state == AiWorkoutState.active)
                  _AiTipsCard(
                        tips: provider.lastAnalysis!.tips,
                        quality: provider.currentQuality,
                      )
                      .animate(key: ValueKey(provider.lastAnalysis!.tips.first))
                      .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack)
                      .fadeIn(),

                const SizedBox(height: 14),

                // Stats Row
                Row(
                  children: [
                    // REPS counter
                    Expanded(
                      flex: 2,
                      child: _StatCard(
                        key: ValueKey(provider.totalReps),
                        label: 'REPS',
                        value:
                            provider.selectedExercise?.type == ExerciseType.hold
                            ? provider.lastAnalysis?.holdDuration
                                      .toStringAsFixed(1) ??
                                  '0.0'
                            : provider.totalReps.toString(),
                        unit:
                            provider.selectedExercise?.type == ExerciseType.hold
                            ? 's'
                            : '',
                        accentColor: lime,
                        shouldPulse:
                            provider.lastAnalysis?.repJustCounted ?? false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Current form quality
                    Expanded(
                      flex: 2,
                      child: _StatCard(
                        label: 'FORM',
                        value: '${provider.currentQuality}%',
                        isProgressBar: true,
                        progress: provider.currentQuality / 100,
                        accentColor: _getQualityColor(provider.currentQuality),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Session average quality
                    Expanded(
                      flex: 2,
                      child: _StatCard(
                        label: 'AVG',
                        value: '${provider.sessionAvgQuality.round()}%',
                        isProgressBar: true,
                        progress: provider.sessionAvgQuality / 100,
                        accentColor: _getQualityColor(
                          provider.sessionAvgQuality.round(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Controls Row
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: provider.state == AiWorkoutState.active
                            ? 'PAUSE'
                            : 'START',
                        icon: provider.state == AiWorkoutState.active
                            ? Iconsax.pause
                            : Iconsax.play,
                        color: Colors.white.withValues(alpha: 0.12),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (provider.state == AiWorkoutState.active) {
                            provider.pauseSession();
                          } else {
                            if (provider.selectedExercise == null) {
                              _showExercisePicker(
                                context,
                                provider,
                                required: true,
                              );
                            } else {
                              if (provider.state == AiWorkoutState.paused) {
                                provider.resumeSession();
                              } else {
                                provider.startSession(
                                  provider.selectedExercise,
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ActionButton(
                      label: 'FINISH',
                      icon: Iconsax.tick_circle,
                      color: lime,
                      textColor: Colors.black,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        provider.stopSession();
                        _showSummary(context, provider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(int quality) {
    if (quality > 80) return Colors.greenAccent;
    if (quality > 55) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _showExercisePicker(
    BuildContext context,
    AiWorkoutProvider provider, {
    bool required = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !required,
      enableDrag: !required,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: required ? 0.7 : 0.4,
        builder: (_, scrollController) => _ExercisePickerSheet(
          provider: provider,
          scrollController: scrollController,
          isRequired: required,
        ),
      ),
    );
  }

  void _showSummary(BuildContext context, AiWorkoutProvider provider) {
    final summary = provider.getSummary();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WorkoutSummaryDialog(summary: summary),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKELETON PAINTER — Draws pose landmarks and connections on camera preview
// ═══════════════════════════════════════════════════════════════════════════════

class _SkeletonPainter extends CustomPainter {
  final List<DetectedLandmark> landmarks;
  final Size imageSize;
  final bool isFrontCamera;
  final Color accentColor;
  final ExercisePhase phase;
  final ExerciseDefinition? selectedExercise;
  final double? primaryAngle;

  _SkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    required this.isFrontCamera,
    required this.accentColor,
    required this.phase,
    this.selectedExercise,
    this.primaryAngle,
  });

  // Skeleton connections (which joints to draw lines between)
  static const _connections = [
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Left arm
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    // Right arm
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Left leg
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    // Right leg
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty || imageSize.isEmpty) return;

    // Build landmark map for fast lookup
    final map = <PoseLandmarkType, DetectedLandmark>{};
    for (final lm in landmarks) {
      map[lm.type] = lm;
    }

    // Convert normalized coordinates to canvas coordinates
    Offset toCanvas(DetectedLandmark lm) {
      double x = lm.x;
      double y = lm.y;

      // Front camera: mirror X axis so the overlay matches the mirrored preview
      if (isFrontCamera) {
        x = 1.0 - x;
      }

      return Offset(x * size.width, y * size.height);
    }

    // ── Draw connections (bones) ───────────────────────────────────────────
    final boneColor = _phaseColor.withValues(alpha: 0.7);
    final bonePaint = Paint()
      ..color = boneColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glow effect for bones
    final glowPaint = Paint()
      ..color = _phaseColor.withValues(alpha: 0.25)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final conn in _connections) {
      final a = map[conn[0]];
      final b = map[conn[1]];
      if (a != null && b != null && a.likelihood > 0.5 && b.likelihood > 0.5) {
        final offsetA = toCanvas(a);
        final offsetB = toCanvas(b);
        canvas.drawLine(offsetA, offsetB, glowPaint);
        canvas.drawLine(offsetA, offsetB, bonePaint);
      }
    }

    // ── Draw landmarks (joints) ────────────────────────────────────────────
    final jointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final jointGlowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final importantJoints = {
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    };

    for (final lm in landmarks) {
      if (lm.likelihood < 0.5) continue;

      final offset = toCanvas(lm);
      final isImportant = importantJoints.contains(lm.type);
      final radius = isImportant ? 5.0 : 3.0;
      final glowRadius = isImportant ? 10.0 : 6.0;

      // Glow
      canvas.drawCircle(offset, glowRadius, jointGlowPaint);
      // Joint dot
      canvas.drawCircle(offset, radius, jointPaint);
    }

    // ── Draw primary joint highlight & real-time angle badge ───────────────
    if (selectedExercise != null && primaryAngle != null) {
      final midJointType = selectedExercise!.primaryAngle.midJoint;
      final midLm = map[midJointType];
      if (midLm != null && midLm.likelihood > 0.5) {
        final offset = toCanvas(midLm);

        // 1. Draw glowing target rings around the primary tracking joint
        final ringPaint = Paint()
          ..color = _phaseColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final ringGlowPaint = Paint()
          ..color = _phaseColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0;

        canvas.drawCircle(offset, 14.0, ringGlowPaint);
        canvas.drawCircle(offset, 14.0, ringPaint);

        // 2. Draw floating badge next to joint
        _drawAngleLabel(canvas, offset, primaryAngle!, size);
      }
    }
  }

  void _drawAngleLabel(Canvas canvas, Offset offset, double angle, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${angle.round()}°',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double paddingX = 8.0;
    final double paddingY = 4.0;
    final labelWidth = textPainter.width + (paddingX * 2);
    final labelHeight = textPainter.height + (paddingY * 2);

    // Position badge offset from joint dot
    double rectX = offset.dx + 16;
    double rectY = offset.dy - 12 - labelHeight;

    // Boundary check so it doesn't draw off-screen
    if (rectX + labelWidth > size.width) {
      rectX = offset.dx - 16 - labelWidth;
    }
    if (rectY < 0) {
      rectY = offset.dy + 16;
    }

    final rect = Rect.fromLTWH(rectX, rectY, labelWidth, labelHeight);
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Draw background
    final bgPaint = Paint()
      ..color = _phaseColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    
    // Draw glowing border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(rectX + paddingX, rectY + paddingY),
    );
  }

  Color get _phaseColor {
    switch (phase) {
      case ExercisePhase.descending:
        return Colors.orangeAccent;
      case ExercisePhase.bottom:
        return Colors.redAccent;
      case ExercisePhase.ascending:
        return Colors.lightBlueAccent;
      case ExercisePhase.top:
        return Colors.greenAccent;
      case ExercisePhase.idle:
        return accentColor;
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) {
    return true; // Always repaint — landmarks change every frame
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _LoadingCamera extends StatelessWidget {
  const _LoadingCamera();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: WorkoutColors.lime(context),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Starting Camera...',
            style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String? exercise;
  final String phase;
  final bool isActive;
  const _ExerciseChip({
    required this.exercise,
    required this.phase,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final lime = WorkoutColors.lime(context);
    final hasExercise = exercise != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: hasExercise
                ? lime.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasExercise
                  ? lime.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive && hasExercise) ...[
                  _PulsingDot(color: lime),
                  const SizedBox(width: 7),
                ] else ...[
                  Icon(
                    hasExercise ? Iconsax.activity : Iconsax.scan,
                    color: hasExercise ? lime : Colors.white70,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  hasExercise ? exercise! : 'Select Exercise',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isActive && hasExercise) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      phase.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: lime,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.4 + _ctrl.value * 0.6),
        ),
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final ExercisePhase phase;
  final double angle;
  const _PhaseIndicator({required this.phase, required this.angle});

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor;
    final label = _phaseLabel;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_phaseIcon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${angle.round()}°',
                    style: GoogleFonts.montserrat(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _phaseColor {
    switch (phase) {
      case ExercisePhase.descending:
        return Colors.orangeAccent;
      case ExercisePhase.bottom:
        return Colors.redAccent;
      case ExercisePhase.ascending:
        return Colors.lightBlueAccent;
      case ExercisePhase.top:
        return Colors.greenAccent;
      case ExercisePhase.idle:
        return Colors.white54;
    }
  }

  String get _phaseLabel {
    switch (phase) {
      case ExercisePhase.descending:
        return 'LOWERING';
      case ExercisePhase.bottom:
        return 'BOTTOM';
      case ExercisePhase.ascending:
        return 'RAISING';
      case ExercisePhase.top:
        return 'TOP';
      case ExercisePhase.idle:
        return 'READY';
    }
  }

  IconData get _phaseIcon {
    switch (phase) {
      case ExercisePhase.descending:
        return Icons.south_rounded;
      case ExercisePhase.bottom:
        return Icons.fitness_center_rounded;
      case ExercisePhase.ascending:
        return Icons.north_rounded;
      case ExercisePhase.top:
        return Icons.check_circle_rounded;
      case ExercisePhase.idle:
        return Icons.radio_button_unchecked_rounded;
    }
  }
}

class _TimerChip extends StatelessWidget {
  final Duration duration;
  const _TimerChip({required this.duration});

  @override
  Widget build(BuildContext context) {
    final m = duration.inMinutes.toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.timer, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Text(
                  '$m:$s',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isProgressBar;
  final double progress;
  final Color accentColor;
  final bool shouldPulse;

  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.isProgressBar = false,
    this.progress = 0.0,
    required this.accentColor,
    this.shouldPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: shouldPulse
                  ? accentColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
              width: shouldPulse ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: shouldPulse ? 0.15 : 0.04),
                blurRadius: shouldPulse ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              shouldPulse
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                                value,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                              .animate(key: key)
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.25, 1.25),
                                duration: 180.ms,
                                curve: Curves.easeOut,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.25, 1.25),
                                end: const Offset(1, 1),
                                duration: 200.ms,
                              ),
                          if (unit.isNotEmpty)
                            Text(
                              unit,
                              style: GoogleFonts.montserrat(
                                color: Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (unit.isNotEmpty)
                            Text(
                              unit,
                              style: GoogleFonts.montserrat(
                                color: Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
              if (isProgressBar) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 3,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AiTipsCard extends StatelessWidget {
  final List<String> tips;
  final int quality;
  const _AiTipsCard({required this.tips, required this.quality});

  @override
  Widget build(BuildContext context) {
    final bool isWarning = quality < 60;
    final Color color = isWarning ? Colors.deepOrange : const Color(0xFF2563EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Iconsax.warning_2 : Iconsax.info_circle,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWarning ? 'FORM CORRECTION' : 'AI COACH TIP',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  tips.first,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatusCard extends StatelessWidget {
  final String message;
  final String subMessage;
  final IconData icon;
  final Color color;
  const _AiStatusCard({
    required this.message,
    required this.subMessage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 44)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 1.seconds,
                  )
                  .custom(
                    builder: (context, value, child) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2 * value),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
              const SizedBox(height: 14),
              Text(
                message,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = textColor == Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE PICKER SHEET — Categorized exercise selection
// ═══════════════════════════════════════════════════════════════════════════════

class _ExercisePickerSheet extends StatefulWidget {
  final AiWorkoutProvider provider;
  final ScrollController scrollController;
  final bool isRequired;

  const _ExercisePickerSheet({
    required this.provider,
    required this.scrollController,
    this.isRequired = false,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final lime = WorkoutColors.lime(context);
    final categories = ExerciseRegistry.categories;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161618),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isRequired
                          ? 'Choose Your Exercise'
                          : 'Switch Exercise',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'AI tracks your form & counts reps on-device',
                      style: GoogleFonts.montserrat(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isRequired)
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: categories.length,
              itemBuilder: (context, catIndex) {
                final category = categories[catIndex];
                final exercises = ExerciseRegistry.getByCategory(category);
                final isExpanded = _expandedCategory == category;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category header
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedCategory = isExpanded ? null : category;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              category.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Exercise list
                    if (isExpanded)
                      ...exercises.map((ex) {
                        final isSelected =
                            widget.provider.selectedExercise?.key == ex.key;
                        return _ExerciseTile(
                          exercise: ex,
                          isSelected: isSelected,
                          lime: lime,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.provider.selectExercise(ex);
                            context.pop();
                            if (widget.provider.state !=
                                AiWorkoutState.active) {
                              widget.provider.startSession(ex);
                            }
                          },
                        );
                      }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseDefinition exercise;
  final bool isSelected;
  final Color lime;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.exercise,
    required this.isSelected,
    required this.lime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? lime.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? lime.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? lime.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  exercise.iconEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        exercise.displayName,
                        style: GoogleFonts.montserrat(
                          color: isSelected ? lime : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (exercise.type == ExerciseType.hold)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'HOLD',
                            style: GoogleFonts.montserrat(
                              color: Colors.white38,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (exercise.tips.isNotEmpty)
                    Text(
                      exercise.tips.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: lime, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT SUMMARY DIALOG — Professional with quality sparkline
// ═══════════════════════════════════════════════════════════════════════════════

class _WorkoutSummaryDialog extends StatelessWidget {
  final AiSessionSummary summary;
  const _WorkoutSummaryDialog({required this.summary});

  @override
  Widget build(BuildContext context) {
    final lime = WorkoutColors.lime(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF161618),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: lime,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.tick_circle,
                    color: Colors.black,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Great Work!',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.exerciseName,
                  style: GoogleFonts.montserrat(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _SummaryStatBox(
                        label: 'REPS',
                        value: '${summary.totalReps}',
                        accentColor: lime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryStatBox(
                        label: 'AVG FORM',
                        value: '${summary.averageQuality}%',
                        accentColor: _qualityColor(summary.averageQuality),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryStatBox(
                        label: 'DURATION',
                        value: summary.formattedDuration,
                        accentColor: Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryStatBox(
                        label: 'PEAK',
                        value: '${summary.peakQuality}%',
                        accentColor: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),

                // Quality sparkline
                if (summary.qualityHistory.length > 5) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 60,
                    child: CustomPaint(
                      size: Size(double.infinity, 60),
                      painter: _QualitySparklinePainter(
                        data: summary.qualityHistory,
                        color: lime,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Form quality over time',
                    style: GoogleFonts.montserrat(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.pop(); // Close dialog
                      context.pop(); // Exit recognition screen
                    },
                    child: Text(
                      'DONE',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _qualityColor(int q) {
    if (q > 80) return Colors.greenAccent;
    if (q > 55) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

class _SummaryStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _SummaryStatBox({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini sparkline chart showing form quality over time.
class _QualitySparklinePainter extends CustomPainter {
  final List<int> data;
  final Color color;

  _QualitySparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    // Downsample if too many points
    final points = data.length > 100 ? _downsample(data, 100) : data;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] / 100) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  List<int> _downsample(List<int> data, int targetSize) {
    final step = data.length / targetSize;
    final result = <int>[];
    for (double i = 0; i < data.length; i += step) {
      result.add(data[i.round()]);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _QualitySparklinePainter oldDelegate) =>
      data != oldDelegate.data;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCANNING RETICLE — Glowing tech reticle when pose not detected
// ═══════════════════════════════════════════════════════════════════════════════

class _ScanningReticle extends StatefulWidget {
  final Color accentColor;
  const _ScanningReticle({required this.accentColor});

  @override
  State<_ScanningReticle> createState() => _ScanningReticleState();
}

class _ScanningReticleState extends State<_ScanningReticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ReticlePainter(
            scanProgress: _controller.value,
            color: widget.accentColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _ReticlePainter extends CustomPainter {
  final double scanProgress;
  final Color color;

  _ReticlePainter({required this.scanProgress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Define the scanning box target zone
    final double marginX = size.width * 0.12;
    final double marginTop = size.height * 0.18;
    final double height = size.height * 0.50;
    final double width = size.width - (marginX * 2);
    final rect = Rect.fromLTWH(marginX, marginTop, width, height);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // 2. Draw Corner Brackets [ ]
    final double cornerLength = 30.0;

    void drawCorner(Offset corner, Offset horizontalDir, Offset verticalDir) {
      // Horizontal segment
      canvas.drawLine(corner, corner + horizontalDir * cornerLength, glowPaint);
      canvas.drawLine(corner, corner + horizontalDir * cornerLength, linePaint);

      // Vertical segment
      canvas.drawLine(corner, corner + verticalDir * cornerLength, glowPaint);
      canvas.drawLine(corner, corner + verticalDir * cornerLength, linePaint);
    }

    // Top-Left
    drawCorner(rect.topLeft, const Offset(1, 0), const Offset(0, 1));
    // Top-Right
    drawCorner(rect.topRight, const Offset(-1, 0), const Offset(0, 1));
    // Bottom-Left
    drawCorner(rect.bottomLeft, const Offset(1, 0), const Offset(0, -1));
    // Bottom-Right
    drawCorner(rect.bottomRight, const Offset(-1, 0), const Offset(0, -1));

    // 3. Draw scanning laser line
    final double y = rect.top + rect.height * scanProgress;
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color,
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(rect.left, y - 5, rect.right, y + 5))
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final laserGlowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(rect.left, y - 20, rect.right, y + 20))
      ..strokeWidth = 20.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), laserGlowPaint);
    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), laserPaint);

    // 4. Draw bounding box with very low opacity
    final boxPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, boxPaint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.color != color;
  }
}
