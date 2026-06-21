// lib/features/nutrition/presentation/widgets/daily_summary_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/models/daily_nutrition.dart';
import '../../../smart_plan/presentation/providers/smart_plan_provider.dart';
import 'nutrition_colors.dart';

class DailySummaryCard extends StatelessWidget {
  final DailyNutrition nutrition;
  final int burnedCalories;

  const DailySummaryCard({
    super.key,
    required this.nutrition,
    this.burnedCalories = 0,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = size.width / 390;
    final isTablet = size.width > 600;
    final isSmallScreen = size.height < 700;

    final smartPlan = context.watch<SmartPlanProvider>();
    final calorieGoal = (smartPlan.hasMealPlan)
        ? smartPlan.mealPlan!.tdee.toInt()
        : nutrition.calorieGoal;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 0 : 16 * s,
            vertical: 8 * s,
          ),
          decoration: BoxDecoration(
            color: NColors.bgSecondary(context),
            borderRadius: BorderRadius.circular(24 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8 * s,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 24 * s,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: NColors.divider(context).withValues(alpha: 0.4),
              width: 1.0 * s,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24 * s),
            child: Stack(
              children: [
                // Extremely Subtle Premium Glow
                Positioned(
                  top: -60 * s,
                  right: -60 * s,
                  child: Container(
                    width: 180 * s,
                    height: 180 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          NColors.accentPrimary(context).withValues(alpha: 0.02),
                          NColors.accentPrimary(context).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 * s : 14 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EnergyHeader(calorieGoal: calorieGoal, s: s),
                      SizedBox(height: isSmallScreen ? 8 * s : 12 * s),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final innerIsWide = constraints.maxWidth > 400;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: innerIsWide ? 10 : 9,
                                child: _CalorieVisualizer(
                                  nutrition: nutrition,
                                  calorieGoal: calorieGoal,
                                  s: s,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 * s : 12 * s),
                              Expanded(
                                flex: innerIsWide ? 14 : 15,
                                child: _MacroVerticalList(
                                  nutrition: nutrition,
                                  s: s,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 10 * s : 14 * s),
                      _QuickStatsBar(
                        nutrition: nutrition,
                        calorieGoal: calorieGoal,
                        burned: burnedCalories,
                        s: s,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms)
    .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

class _EnergyHeader extends StatelessWidget {
  final int calorieGoal;
  final double s;
  const _EnergyHeader({required this.calorieGoal, required this.s});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4 * s,
                    height: 4 * s,
                    decoration: BoxDecoration(
                      color: NColors.accentPrimary(context),
                      borderRadius: BorderRadius.circular(1.2),
                    ),
                  ),
                  SizedBox(width: 6 * s),
                  Flexible(
                    child: Text(
                      'DAILY OVERVIEW',
                      style: GoogleFonts.montserrat(
                        color: NColors.textSecondary(context),
                        fontSize: 8.5 * s,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1 * s),
              Text(
                'Nutrition Status',
                style: GoogleFonts.montserrat(
                  color: NColors.textPrimary(context),
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
          decoration: BoxDecoration(
            color: NColors.bgPrimary(context),
            borderRadius: BorderRadius.circular(10 * s),
            border: Border.all(color: NColors.divider(context).withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Text(
                'TARGET',
                style: GoogleFonts.montserrat(
                  color: NColors.textTertiary(context),
                  fontSize: 6.5 * s,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '$calorieGoal',
                style: GoogleFonts.montserrat(
                  color: NColors.textPrimary(context),
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalorieVisualizer extends StatelessWidget {
  final DailyNutrition nutrition;
  final int calorieGoal;
  final double s;
  const _CalorieVisualizer({
    required this.nutrition,
    required this.calorieGoal,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final eaten = nutrition.totalCalories;
    final progress = calorieGoal > 0 ? (eaten / calorieGoal).clamp(0.0, 1.0) : 0.0;
    
    final totalGrams = nutrition.totalProtein + nutrition.totalCarbs + nutrition.totalFat;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Premium Multi-Segment Ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: 1500.ms,
            curve: Curves.easeOutExpo,
            builder: (context, val, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ModernCirclePainter(
                  progress: val,
                  nutrition: nutrition,
                  s: s,
                  context: context,
                ),
              );
            },
          ),

          // Central Hub
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(
                  eaten.toInt().toString(),
                  style: GoogleFonts.montserrat(
                    color: NColors.textPrimary(context),
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'KCAL',
                style: GoogleFonts.montserrat(
                  color: NColors.textSecondary(context),
                  fontSize: 7.5 * s,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              if (totalGrams > 0) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: NColors.divider(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${totalGrams.toInt()}g',
                    style: GoogleFonts.montserrat(
                      color: NColors.textTertiary(context),
                      fontSize: 7.5 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernCirclePainter extends CustomPainter {
  final double progress;
  final DailyNutrition nutrition;
  final double s;
  final BuildContext context;

  _ModernCirclePainter({
    required this.progress,
    required this.nutrition,
    required this.s,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = 8 * s;
    final radius = (size.width - width) / 2;
    const startAngle = -math.pi / 2;
    final fullSweep = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Shadowed Track
    final trackPaint = Paint()
      ..color = NColors.divider(context).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // 2. Segmented Macro Arcs
    final totalMacros = nutrition.totalProtein + nutrition.totalCarbs + nutrition.totalFat;
    if (totalMacros <= 0) {
      final p = Paint()
        ..color = NColors.accentPrimary(context)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, fullSweep, false, p);
      return;
    }

    final pRatio = nutrition.totalProtein / totalMacros;
    final cRatio = nutrition.totalCarbs / totalMacros;
    final fRatio = nutrition.totalFat / totalMacros;

    final pSweep = fullSweep * pRatio;
    final cSweep = fullSweep * cRatio;
    final fSweep = fullSweep * fRatio;

    // We use a small gap between segments for that "modular" look
    const gap = 0.04;
    
    _drawSegment(canvas, rect, startAngle, (pSweep - gap).clamp(0, 2*math.pi), NColors.accentSecondary(context), width);
    _drawSegment(canvas, rect, startAngle + pSweep, (cSweep - gap).clamp(0, 2*math.pi), NColors.warningAccent(context), width);
    _drawSegment(canvas, rect, startAngle + pSweep + cSweep, (fSweep - gap).clamp(0, 2*math.pi), NColors.dangerAccent(context), width);
  }

  void _drawSegment(Canvas canvas, Rect rect, double start, double sweep, Color color, double width) {
    if (sweep <= 0.05) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ModernCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MacroVerticalList extends StatelessWidget {
  final DailyNutrition nutrition;
  final double s;
  const _MacroVerticalList({required this.nutrition, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MacroProgressItem(
          label: 'Protein',
          current: nutrition.totalProtein,
          goal: nutrition.proteinGoalG,
          color: NColors.accentSecondary(context),
          icon: PhosphorIcons.egg(PhosphorIconsStyle.fill),
          s: s,
        ),
        SizedBox(height: 8 * s),
        _MacroProgressItem(
          label: 'Carbs',
          current: nutrition.totalCarbs,
          goal: nutrition.carbsGoalG,
          color: NColors.warningAccent(context),
          icon: PhosphorIcons.bread(PhosphorIconsStyle.fill),
          s: s,
        ),
        SizedBox(height: 8 * s),
        _MacroProgressItem(
          label: 'Fats',
          current: nutrition.totalFat,
          goal: nutrition.fatGoalG,
          color: NColors.dangerAccent(context),
          icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
          s: s,
        ),
      ],
    );
  }
}

class _MacroProgressItem extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final PhosphorIconData icon;
  final double s;

  const _MacroProgressItem({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.icon,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 11 * s, color: color),
                  SizedBox(width: 5 * s),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w800,
                        color: NColors.textPrimary(context),
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${current.toInt()}g',
              style: GoogleFonts.montserrat(
                fontSize: 11 * s,
                fontWeight: FontWeight.w900,
                color: NColors.textPrimary(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * s),
        Stack(
          children: [
            Container(
              height: 5 * s,
              width: double.infinity,
              decoration: BoxDecoration(
                color: NColors.divider(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: 1000.ms,
              curve: Curves.easeOutCubic,
              widthFactor: progress,
              child: Container(
                height: 5 * s,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickStatsBar extends StatelessWidget {
  final DailyNutrition nutrition;
  final int calorieGoal;
  final int burned;
  final double s;

  const _QuickStatsBar({
    required this.nutrition,
    required this.calorieGoal,
    required this.burned,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (calorieGoal - nutrition.totalCalories + burned)
        .round();
    final net = (nutrition.totalCalories - burned).round();

    return Container(
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
        color: NColors.bgPrimary(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: NColors.divider(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _ModernStat(
            label: 'LEFT',
            value: remaining.abs().toString(),
            color: remaining >= 0
                ? NColors.accentPrimary(context)
                : NColors.dangerAccent(context),
            icon: Iconsax.timer_1,
            s: s,
          ),
          _VerticalDivider(s: s),
          _ModernStat(
            label: 'BURNED',
            value: burned.toString(),
            color: const Color(0xFFF97316),
            icon: Iconsax.flash_1,
            s: s,
          ),
          _VerticalDivider(s: s),
          _ModernStat(
            label: 'NET',
            value: net.toString(),
            color: NColors.textPrimary(context),
            icon: Iconsax.chart_1,
            s: s,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final double s;
  const _VerticalDivider({required this.s});
  @override
  Widget build(BuildContext context) => Container(
    width: 0.8,
    height: 16 * s,
    margin: EdgeInsets.symmetric(horizontal: 3 * s),
    color: NColors.divider(context).withValues(alpha: 0.4),
  );
}

class _ModernStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final double s;

  const _ModernStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 8 * s, color: NColors.textTertiary(context)),
                SizedBox(width: 2 * s),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 7 * s,
                    fontWeight: FontWeight.w900,
                    color: NColors.textTertiary(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14 * s,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
