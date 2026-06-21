// lib/features/setup/presentation/screens/plan_generation_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:befit/core/router/app_routes.dart';
import 'package:befit/features/auth/presentation/providers/auth_provider.dart';
import 'package:befit/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:befit/features/setup/presentation/providers/setup_provider.dart';
import 'package:befit/features/smart_plan/presentation/providers/smart_plan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/befit_theme_extension.dart';

class PlanGenerationScreen extends StatefulWidget {
  const PlanGenerationScreen({super.key});

  @override
  State<PlanGenerationScreen> createState() => _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends State<PlanGenerationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _progressCtrl;

  double _progress = 0.0;
  String _currentStage = 'Analyzing your profile...';
  int _completedStages = 0;
  bool _isDone = false;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _fakeProgressTimer;

  static const List<_Stage> _stages = [
    _Stage(
      label: 'Analyzing your profile',
      icon: Icons.person_outline_rounded,
      color: Color(0xFF6366F1),
    ),
    _Stage(
      label: 'Building your workout plan',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFEC4899),
    ),
    _Stage(
      label: 'Crafting your nutrition plan',
      icon: Icons.restaurant_outlined,
      color: Color(0xFF10B981),
    ),
    _Stage(
      label: 'Personalizing your goals',
      icon: Icons.track_changes_rounded,
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startGeneration());
  }

  @override
  void dispose() {
    _fakeProgressTimer?.cancel();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _startFakeProgress() {
    _fakeProgressTimer = Timer.periodic(const Duration(milliseconds: 80), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progress < 0.92) {
          _progress += 0.004;
          _updateStageFromProgress();
        }
      });
    });
  }

  void _updateStageFromProgress() {
    if (_progress < 0.25) {
      _currentStage = 'Analyzing your profile...';
      _completedStages = 0;
    } else if (_progress < 0.50) {
      _currentStage = 'Building your workout plan...';
      _completedStages = 1;
    } else if (_progress < 0.75) {
      _currentStage = 'Crafting your nutrition plan...';
      _completedStages = 2;
    } else {
      _currentStage = 'Personalizing your goals...';
      _completedStages = 3;
    }
  }

  Future<void> _startGeneration() async {
    _startFakeProgress();
    HapticFeedback.mediumImpact();

    final setup = context.read<SetupProvider>();
    final auth = context.read<AuthProvider>();
    final smartPlan = context.read<SmartPlanProvider>();

    final userId = auth.userId ?? '';

    final success = await smartPlan.generatePlans(
      setup: setup,
      userId: userId,
      onStageChange: (stage) {
        if (mounted) setState(() => _currentStage = stage);
      },
    );

    _fakeProgressTimer?.cancel();
    if (!mounted) return;

    if (success) {
      // Sync calorie goal to nutrition provider (TDEE is displayed in circular progress)
      if (smartPlan.hasMealPlan) {
        context.read<NutritionProvider>().setSmartCalorieGoal(
          smartPlan.mealPlan!.tdee,
        );
      }

      setState(() {
        _progress = 1.0;
        _completedStages = _stages.length;
        _currentStage = 'Your plan is ready!';
        _isDone = true;
      });

      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go(AppRoutes.home);
    } else {
      setState(() {
        _hasError = true;
        _progress = 0.0;
        _errorMessage =
            smartPlan.errorMessage ?? 'Generation failed. Please try again.';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _progress = 0.0;
      _completedStages = 0;
      _isDone = false;
      _currentStage = 'Analyzing your profile...';
    });
    _startGeneration();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isTablet = size.width > 600;
    final theme = context.customColors;

    return PopScope(
      canPop: false, // Prevent back navigation during generation
      child: Scaffold(
        backgroundColor: theme.setupBg,
        body: Stack(
          children: [
            // ── Animated Background ─────────────────────────────────────
            _AnimatedBackground(rotateCtrl: _rotateCtrl, pulseCtrl: _pulseCtrl),

            // ── Content ─────────────────────────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? size.width * 0.15 : 32,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: isSmallScreen ? 40 : 60),

                              if (!_hasError) ...[
                                // ── Central Animation ─────────────────────────────
                                _CentralOrb(
                                  pulseCtrl: _pulseCtrl,
                                  rotateCtrl: _rotateCtrl,
                                  progress: _progress,
                                  isDone: _isDone,
                                  size: isSmallScreen ? 140 : 180,
                                ),

                                SizedBox(height: isSmallScreen ? 32 : 48),

                                // ── Status Text ───────────────────────────────────
                                Text(
                                      _isDone
                                          ? '🎉 Ready!'
                                          : 'Building Your Plan',
                                      style: GoogleFonts.montserrat(
                                        fontSize: isSmallScreen ? 28 : 32,
                                        fontWeight: FontWeight.w900,
                                        color: theme.setupTextPrimary,
                                        letterSpacing: -1,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                    .animate(key: ValueKey(_isDone))
                                    .fadeIn(duration: 400.ms),

                                const SizedBox(height: 12),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: Text(
                                    _currentStage,
                                    key: ValueKey(_currentStage),
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                      color: theme.setupTextSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 32 : 48),

                                // ── Stage Checklist ───────────────────────────────
                                _StageChecklist(
                                  stages: _stages,
                                  completedCount: _completedStages,
                                  isDone: _isDone,
                                ),

                                SizedBox(height: isSmallScreen ? 32 : 40),

                                // ── Progress Bar ──────────────────────────────────
                                _ProgressBar(
                                  progress: _progress,
                                  isDone: _isDone,
                                ),
                              ] else ...[
                                // ── Error State ───────────────────────────────────
                                _ErrorState(
                                  message:
                                      _errorMessage ??
                                      'Something went wrong. Please try again.',
                                  onRetry: _retry,
                                  onSkip: () => context.go(AppRoutes.home),
                                ),
                              ],

                              const Spacer(),

                              // ── Footer Note ───────────────────────────────────────
                              if (!_hasError && !_isDone)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Text(
                                    'This may take a moment — great things take time.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: theme.setupTextSecondary
                                          .withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ).animate().fadeIn(delay: 1000.ms),
                                ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Background ─────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final AnimationController rotateCtrl;
  final AnimationController pulseCtrl;

  const _AnimatedBackground({
    required this.rotateCtrl,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    return AnimatedBuilder(
      animation: Listenable.merge([rotateCtrl, pulseCtrl]),
      builder: (context, child) {
        return Stack(
          children: [
            // Top-left glow
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.setupPrimary.withValues(
                        alpha: 0.15 + pulseCtrl.value * 0.05,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom-right glow
            Positioned(
              bottom: -100,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.calorieRing.withValues(
                        alpha: 0.1 + pulseCtrl.value * 0.05,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Central Orb ─────────────────────────────────────────────────────────────

class _CentralOrb extends StatelessWidget {
  final AnimationController pulseCtrl;
  final AnimationController rotateCtrl;
  final double progress;
  final bool isDone;
  final double size;

  const _CentralOrb({
    required this.pulseCtrl,
    required this.rotateCtrl,
    required this.progress,
    required this.isDone,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    final innerSize = size * 0.625; // Maintains 100/160 ratio

    return AnimatedBuilder(
      animation: Listenable.merge([pulseCtrl, rotateCtrl]),
      builder: (context, child) {
        final scale = 1.0 + pulseCtrl.value * 0.08;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                Transform.rotate(
                  angle: rotateCtrl.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _ArcPainter(
                      progress: progress,
                      color1: theme.setupPrimary,
                      color2: theme.calorieRing,
                    ),
                  ),
                ),
                // Inner pulsing orb
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDone
                            ? [
                                theme.success,
                                theme.success.withValues(alpha: 0.8),
                              ]
                            : [
                                theme.setupPrimary,
                                theme.setupPrimary.withValues(alpha: 0.8),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDone ? theme.success : theme.setupPrimary)
                              .withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : Icons.auto_awesome_rounded,
                      color: theme.setupOnPrimary,
                      size: size * 0.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  _ArcPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track
    final trackPaint = Paint()
      ..color = color1.withValues(alpha: 0.08)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [color1, color2, color1],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ── Stage Checklist ──────────────────────────────────────────────────────────

class _Stage {
  final String label;
  final IconData icon;
  final Color color;
  const _Stage({required this.label, required this.icon, required this.color});
}

class _StageChecklist extends StatelessWidget {
  final List<_Stage> stages;
  final int completedCount;
  final bool isDone;

  const _StageChecklist({
    required this.stages,
    required this.completedCount,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.setupCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: List.generate(stages.length, (i) {
          final stage = stages[i];
          final isComplete = isDone || i < completedCount;
          final isActive = !isDone && i == completedCount;

          return Padding(
            padding: EdgeInsets.only(bottom: i < stages.length - 1 ? 16 : 0),
            child: _StageRow(
              stage: stage,
              isComplete: isComplete,
              isActive: isActive,
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _StageRow extends StatelessWidget {
  final _Stage stage;
  final bool isComplete;
  final bool isActive;

  const _StageRow({
    required this.stage,
    required this.isComplete,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    return Row(
      children: [
        // Icon/Status dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? stage.color
                : isActive
                ? stage.color.withValues(alpha: 0.2)
                : theme.setupTextPrimary.withValues(alpha: 0.06),
            border: Border.all(
              color: isComplete
                  ? stage.color
                  : isActive
                  ? stage.color.withValues(alpha: 0.6)
                  : theme.setupTextPrimary.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isComplete
                ? Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Icon(
                    stage.icon,
                    color: isActive
                        ? stage.color
                        : theme.setupTextSecondary.withValues(alpha: 0.5),
                    size: 14,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            stage.label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: isComplete || isActive
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isComplete
                  ? theme.setupTextPrimary
                  : isActive
                  ? theme.setupTextPrimary.withValues(alpha: 0.9)
                  : theme.setupTextSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (isActive)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: stage.color,
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 800.ms),
      ],
    );
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool isDone;

  const _ProgressBar({required this.progress, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.setupTextSecondary,
              ),
            ),
            Text(
              isDone ? 'Complete!' : 'In progress...',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDone
                    ? theme.success
                    : theme.setupTextSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Container(
                height: 6,
                decoration: BoxDecoration(
                  color: theme.setupTextPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: isDone
                          ? LinearGradient(
                              colors: [
                                theme.success,
                                theme.success.withValues(alpha: 0.7),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                theme.setupPrimary,
                                theme.calorieRing,
                                theme.setupPrimary,
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final theme = context.customColors;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.warning.withValues(alpha: 0.12),
            border: Border.all(color: theme.warning.withValues(alpha: 0.3)),
          ),
          child: Icon(
            Icons.wifi_off_rounded,
            size: isSmallScreen ? 40 : 48,
            color: theme.warning,
          ),
        ),
        SizedBox(height: isSmallScreen ? 20 : 24),
        Text(
          'Connection Issue',
          style: GoogleFonts.montserrat(
            fontSize: isSmallScreen ? 22 : 26,
            fontWeight: FontWeight.w900,
            color: theme.setupTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 14 : 15,
            color: theme.setupTextSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 32 : 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.setupPrimary,
              foregroundColor: theme.setupOnPrimary,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'Skip for now',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.setupTextSecondary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}
