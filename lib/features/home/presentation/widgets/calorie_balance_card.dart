library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:befit/features/home/presentation/widgets/home_theme.dart';
import 'package:befit/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:befit/features/workout/presentation/providers/workout_hub_provider.dart';
import 'package:befit/features/nutrition/data/models/meal_log.dart';

class CalorieBalanceCard extends StatelessWidget {
  const CalorieBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final nutritionProvider = context.watch<NutritionProvider>();
    final hubProvider = context.watch<WorkoutHubProvider>();
    
    final nutrition = nutritionProvider.dailyNutrition;
    final customColors = context.customColors;

    final isDataReady = nutritionProvider.isInitialized &&
        !nutritionProvider.isLoading &&
        nutrition.calorieGoal > 0;

    if (!isDataReady) {
      return _buildLoadingState(context);
    }

    final goal = nutrition.calorieGoal;
    final food = nutrition.totalCalories.round();
    final exercise = hubProvider.isInitialized ? hubProvider.stats.caloriesToday : 0;
    
    final totalBudget = goal + exercise;
    final remaining = totalBudget - food;
    final isOverBudget = remaining < 0;
    
    final statusColor = isOverBudget ? customColors.failure : customColors.success;
    
    final progress = totalBudget > 0 ? (food / totalBudget).clamp(0.0, 1.5) : 0.0;
    final displayProgress = progress.clamp(0.0, 1.0);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Responsive scaling factors
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  customColors.surfaceMuted.withValues(alpha: 0.85),
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.80),
                ],
        ),
        borderRadius: BorderRadius.circular(28 * s),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFF111827).withValues(alpha: 0.04),
          width: 1.2 * s,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 24 * s,
            spreadRadius: 2 * s,
            offset: Offset(0, 8 * s),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.02),
            blurRadius: 16 * s,
            offset: Offset(0, 4 * s),
          ),
        ],
      ),
      padding: EdgeInsets.all(22 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calorie Balance',
                      style: GoogleFonts.montserrat(
                        fontSize: 18 * fs,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7 * s,
                          height: 7 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.6),
                                blurRadius: 6 * s,
                                spreadRadius: 1 * s,
                              ),
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1200.ms)
                            .fadeIn(begin: 0.5, duration: 1200.ms),
                        SizedBox(width: 6 * s),
                        Expanded(
                          child: Text(
                            'TODAY BUDGET STATUS',
                            style: GoogleFonts.montserrat(
                              fontSize: 10 * fs,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                isOverBudget: isOverBudget,
                diff: remaining.abs(),
                color: statusColor,
              ),
            ],
          ),
          SizedBox(height: 20 * s),

          // ── Gauge & Equation Section ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: 3/4 Arc Gauge
              Expanded(
                flex: 5,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: displayProgress),
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOutQuart,
                        builder: (context, animVal, _) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: _CalorieGaugePainter(
                              progress: animVal,
                              activeColor: statusColor,
                              trackColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                              strokeWidth: 9.0 * s,
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.all(12 * s),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOverBudget ? 'SURPLUS' : 'REMAINING',
                              style: GoogleFonts.montserrat(
                                fontSize: 9 * fs,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatNumber(remaining.abs()),
                                style: GoogleFonts.montserrat(
                                  fontSize: 28 * fs,
                                  fontWeight: FontWeight.w900,
                                  color: isOverBudget ? customColors.failure : theme.colorScheme.onSurface,
                                  height: 1.0,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'kcal',
                              style: GoogleFonts.montserrat(
                                fontSize: 11 * fs,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 20 * s),

              // Right: Calorie Equation breakdown
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _EquationTile(
                      label: 'Base Goal',
                      value: '$goal',
                      unit: 'kcal',
                      icon: Icons.flag_rounded,
                      color: HomeUi.accent(context),
                      bgColor: HomeUi.accent(context).withValues(alpha: 0.06),
                    ),
                    SizedBox(height: 8 * s),
                    _EquationTile(
                      label: 'Workouts',
                      value: '+$exercise',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orange,
                      bgColor: Colors.orange.withValues(alpha: 0.06),
                    ),
                    SizedBox(height: 8 * s),
                    _EquationTile(
                      label: 'Food Eaten',
                      value: '-$food',
                      unit: 'kcal',
                      icon: Icons.restaurant_rounded,
                      color: customColors.protein,
                      bgColor: customColors.protein.withValues(alpha: 0.06),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 22 * s),

          // ── Divider ────────────────────────────────────────
          Container(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          SizedBox(height: 18 * s),

          // ── Macros Section ─────────────────────────────────
          Text(
            'Macros Breakdown',
            style: GoogleFonts.montserrat(
              fontSize: 13 * fs,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 12 * s),
          Row(
            children: [
              Expanded(
                child: _CircularMacroRing(
                  label: 'Protein',
                  current: nutrition.totalProtein,
                  goal: nutrition.proteinGoalG,
                  color: customColors.protein,
                  letter: 'P',
                ),
              ),
              SizedBox(width: 8 * s),
              Expanded(
                child: _CircularMacroRing(
                  label: 'Carbs',
                  current: nutrition.totalCarbs,
                  goal: nutrition.carbsGoalG,
                  color: customColors.carbs,
                  letter: 'C',
                ),
              ),
              SizedBox(width: 8 * s),
              Expanded(
                child: _CircularMacroRing(
                  label: 'Fats',
                  current: nutrition.totalFat,
                  goal: nutrition.fatGoalG,
                  color: customColors.fat,
                  letter: 'F',
                ),
              ),
            ],
          ),
          SizedBox(height: 22 * s),

          // ── Meal Distribution Section ──────────────────────
          Text(
            'Calorie Intake Distribution',
            style: GoogleFonts.montserrat(
              fontSize: 13 * fs,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 12 * s),
          _MealDistributionChart(nutrition: nutrition),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final s = Responsive.scale(context, 1.0);

    return Container(
      decoration: cardDecoration(context),
      padding: EdgeInsets.all(22 * s),
      height: 380 * s,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140 * s,
                    height: 20 * s,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  Container(
                    width: 100 * s,
                    height: 12 * s,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 80 * s,
                height: 28 * s,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * s),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20 * s),
              Expanded(
                flex: 6,
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: EdgeInsets.only(bottom: 8.0 * s),
                      child: Container(
                        height: 38 * s,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * s),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8.0 * s : 0.0),
                  child: Container(
                    height: 80 * s,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .shimmer(
            duration: 1500.ms,
            color: colorScheme.primary.withValues(alpha: 0.08),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

class _CalorieGaugePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;

  _CalorieGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = 3 * math.pi / 4;
    const totalSweepAngle = 3 * math.pi / 2;
    final sweepAngle = totalSweepAngle * progress.clamp(0.0, 1.0);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw glowing background backing
    final glowBacking = Paint()
      ..shader = RadialGradient(
        colors: [activeColor.withValues(alpha: 0.05), activeColor.withValues(alpha: 0.0)],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.95, glowBacking);

    // 2. Draw outer boundary ring
    final outerRingPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + strokeWidth * 0.9),
      startAngle - 0.02,
      totalSweepAngle + 0.04,
      false,
      outerRingPaint,
    );

    // 3. Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, totalSweepAngle, false, trackPaint);

    // 4. Draw tachometer tick marks
    const numTicks = 28;
    final tickLength = 4.0;
    final tickRadius = radius - strokeWidth / 2 - 3;

    for (int i = 0; i <= numTicks; i++) {
      final tickPercent = i / numTicks;
      final tickAngle = startAngle + (totalSweepAngle * tickPercent);
      final tickCos = math.cos(tickAngle);
      final tickSin = math.sin(tickAngle);

      final isTickActive = progress > 0 && tickPercent <= progress;

      final startOffset = Offset(
        center.dx + (tickRadius + tickLength) * tickCos,
        center.dy + (tickRadius + tickLength) * tickSin,
      );
      final endOffset = Offset(
        center.dx + tickRadius * tickCos,
        center.dy + tickRadius * tickSin,
      );

      final tickPaint = Paint()
        ..color = isTickActive
            ? activeColor.withValues(alpha: 0.4)
            : trackColor.withValues(alpha: 0.25)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startOffset, endOffset, tickPaint);
    }

    if (progress <= 0) return;

    // 5. Draw active progress with glow
    final gradient = SweepGradient(
      colors: [activeColor.withValues(alpha: 0.35), activeColor],
      stops: const [0.0, 1.0],
      transform: GradientRotation(startAngle),
    );

    // Blurred outer glow
    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.25
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Sharp active path
    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);

    // 6. Draw knob/thumb at the end of progress
    final endAngle = startAngle + sweepAngle;
    final knobOffset = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    // Knob glow
    final knobGlow = Paint()
      ..color = activeColor.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawCircle(knobOffset, strokeWidth * 1.1, knobGlow);

    // Knob outer white border
    final knobOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(knobOffset, strokeWidth * 0.75, knobOuter);

    // Knob inner color dot
    final knobInner = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(knobOffset, strokeWidth * 0.42, knobInner);
  }

  @override
  bool shouldRepaint(covariant _CalorieGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}

class _MacroProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _MacroProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Active
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _MacroProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isOverBudget,
    required this.diff,
    required this.color,
  });

  final bool isOverBudget;
  final int diff;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
          width: 1.0 * s,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverBudget ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            size: 13 * s,
            color: color,
          ),
          SizedBox(width: 4 * s),
          Text(
            isOverBudget ? '${formatNumber(diff)} over' : '${formatNumber(diff)} left',
            style: GoogleFonts.montserrat(
              fontSize: 10 * fs,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquationTile extends StatelessWidget {
  const _EquationTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFF111827).withValues(alpha: 0.035),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.01),
            blurRadius: 4 * s,
            offset: Offset(0, 2 * s),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Icon(
              icon,
              size: 15 * s,
              color: color,
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11 * fs,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 13 * fs,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: GoogleFonts.montserrat(
                    fontSize: 10 * fs,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
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

class _CircularMacroRing extends StatelessWidget {
  const _CircularMacroRing({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.letter,
  });

  final String label;
  final double current;
  final double goal;
  final Color color;
  final String letter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);
    
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final pct = goal > 0 ? (current / goal * 100).round() : 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 12 * s),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFF111827).withValues(alpha: 0.035),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(38 * s, 38 * s),
                painter: _MacroProgressPainter(
                  progress: progress,
                  color: color,
                  trackColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 3.5 * s,
                ),
              ),
              Text(
                letter,
                style: GoogleFonts.montserrat(
                  fontSize: 12 * fs,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11 * fs,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 2 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${current.round()}/${goal.round()}g',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 9 * fs,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: 6 * s),
          ClipRRect(
            borderRadius: BorderRadius.circular(6 * s),
            child: Container(
              height: 14 * s,
              width: double.infinity,
              color: color.withValues(alpha: 0.08),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$pct%',
                  style: GoogleFonts.montserrat(
                    fontSize: 9 * fs,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealDistributionChart extends StatelessWidget {
  const _MealDistributionChart({required this.nutrition});

  final dynamic nutrition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final double bf = nutrition.mealCalories(MealType.breakfast);
    final double lh = nutrition.mealCalories(MealType.lunch);
    final double dn = nutrition.mealCalories(MealType.dinner);
    final double sn = nutrition.mealCalories(MealType.snacks);
    
    final double total = bf + lh + dn + sn;
    
    // Segment Colors
    const bfColor = Color(0xFF60A5FA); // Blue
    const lhColor = Color(0xFF34D399); // Emerald Green
    const dnColor = Color(0xFF818CF8); // Indigo
    const snColor = Color(0xFFFBBF24); // Amber Yellow
    
    final s = Responsive.scale(context, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6 * s),
          child: Container(
            height: 9 * s,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            child: total > 0
                ? Row(
                    children: [
                      if (bf > 0)
                        Expanded(
                          flex: (bf * 10).round(),
                          child: Container(color: bfColor),
                        ),
                      if (lh > 0)
                        Expanded(
                          flex: (lh * 10).round(),
                          child: Container(color: lhColor),
                        ),
                      if (dn > 0)
                        Expanded(
                          flex: (dn * 10).round(),
                          child: Container(color: dnColor),
                        ),
                      if (sn > 0)
                        Expanded(
                          flex: (sn * 10).round(),
                          child: Container(color: snColor),
                        ),
                    ],
                  )
                : Container(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
          ),
        ),
        SizedBox(height: 12 * s),
        Wrap(
          spacing: 12 * s,
          runSpacing: 6 * s,
          alignment: WrapAlignment.start,
          children: [
            _MealLegendItem(label: 'Breakfast', value: bf.round(), color: bfColor),
            _MealLegendItem(label: 'Lunch', value: lh.round(), color: lhColor),
            _MealLegendItem(label: 'Dinner', value: dn.round(), color: dnColor),
            _MealLegendItem(label: 'Snacks', value: sn.round(), color: snColor),
          ],
        ),
      ],
    );
  }
}

class _MealLegendItem extends StatelessWidget {
  const _MealLegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 6 * s,
          height: 6 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 5 * s),
        Text(
          '$label:',
          style: GoogleFonts.montserrat(
            fontSize: 9.5 * fs,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 2 * s),
        Text(
          '$value kcal',
          style: GoogleFonts.montserrat(
            fontSize: 9.5 * fs,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

