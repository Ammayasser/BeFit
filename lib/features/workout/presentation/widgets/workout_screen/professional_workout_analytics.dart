import 'package:befit/core/router/app_routes.dart';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/features/workout/core/workout_colors.dart';
import 'package:befit/features/workout/data/models/workout_hub_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

class ProfessionalWorkoutAnalytics extends StatelessWidget {
  final WorkoutHubStats stats;
  final EdgeInsetsGeometry? padding;

  const ProfessionalWorkoutAnalytics({
    super.key,
    required this.stats,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _RecoveryStatusCard(stats: stats),
          const SizedBox(height: 16),
          _WorkoutSummaryCard(stats: stats),
          const SizedBox(height: 16),
          _CaloriesChartCard(stats: stats),
          const SizedBox(height: 16),
          _MuscleFocusCard(stats: stats),
        ],
      ),
    );
  }
}

class _RecoveryStatusCard extends StatelessWidget {
  final WorkoutHubStats stats;

  const _RecoveryStatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final recovery = stats.fullBodyRecoveryState;
    final score = recovery?.overallReadinessScore ?? 1.0;
    final pct = (score * 100).toInt();
    final custom = context.customColors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Status colors used ONLY for accents
    final statusColor = pct > 70
        ? custom.success // System success color
        : pct > 40
        ? custom.warning // System warning color
        : theme.colorScheme.error; // System error color

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isSmall = cardWidth < 360;

        // Responsive sizes
        final double paddingVal = isSmall ? 16 : 24;
        final double circleSize = isSmall ? 85 : (cardWidth < 400 ? 95 : 120);
        final double strokeWidth = isSmall ? 9 : 14;
        final double iconSize = isSmall ? 22 : 32;
        final double pctFontSize = isSmall ? 48 : 64;
        final double statusFontSize = isSmall ? 13 : 16;
        final double spacingBetween = isSmall ? 8 : 12;

        return GestureDetector(
          onTap: () => context.push(AppRoutes.workoutRecovery),
          child: Container(
            constraints: BoxConstraints(
              minHeight: isSmall ? 170 : 220,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Stack(
                children: [
                  // 1. Deep Neutral Background (No yellow/status tints)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : theme.colorScheme.surface,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                              : [theme.colorScheme.surface, theme.colorScheme.surface.withValues(alpha: 0.95)],
                        ),
                      ),
                    ),
                  ),

                  // 2. Content
                  Padding(
                    padding: EdgeInsets.all(paddingVal),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // LEFT: Metrics
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shield_rounded,
                                      color: statusColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'READINESS',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: WorkoutColors.onSurfaceMuted(context),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: spacingBetween),
                              Text(
                                '$pct%',
                                style: GoogleFonts.montserrat(
                                  fontSize: pctFontSize,
                                  fontWeight: FontWeight.w900,
                                  color: WorkoutColors.onSurface(context),
                                  letterSpacing: isSmall ? -1.5 : -3,
                                  height: 1,
                                ),
                              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                              const SizedBox(height: 4),
                              Text(
                                pct > 70 ? 'Prime Performance' : pct > 40 ? 'Moderate Recovery' : 'Recovery Phase',
                                style: GoogleFonts.montserrat(
                                  fontSize: statusFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: spacingBetween),
                              // System-themed Pills
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _buildSystemPill(
                                    context,
                                    '${recovery?.readyMuscles.length ?? 0} Ready',
                                  ),
                                  if (stats.topMuscleGroup.isNotEmpty)
                                    _buildSystemPill(context, stats.topMuscleGroup),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // RIGHT: Visualizer
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Base Ring
                                SizedBox(
                                  width: circleSize,
                                  height: circleSize,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: strokeWidth,
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                // Status Progress
                                SizedBox(
                                  width: circleSize,
                                  height: circleSize,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: score),
                                    duration: 1.2.seconds,
                                    curve: Curves.easeOutCubic,
                                    builder: (context, val, _) =>
                                        CircularProgressIndicator(
                                          value: val,
                                          strokeWidth: strokeWidth,
                                          color: statusColor,
                                          strokeCap: StrokeCap.round,
                                        ),
                                  ),
                                ),
                                // Icon Center
                                Icon(
                                  pct > 70
                                      ? Icons.bolt_rounded
                                      : Icons.hourglass_empty_rounded,
                                  color: statusColor,
                                  size: iconSize,
                                ).animate(onPlay: (c) => c.repeat()).shimmer(
                                      duration: 3.seconds,
                                      color: statusColor.withValues(alpha: 0.4),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // UI Hint
                  Positioned(
                    top: paddingVal,
                    right: paddingVal,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 20,
                      color: WorkoutColors.onSurfaceSubtle(
                        context,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.97, 0.97)),
        );
      },
    );
  }

  Widget _buildSystemPill(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: WorkoutColors.onSurfaceMuted(context),
        ),
      ),
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  final WorkoutHubStats stats;

  const _WorkoutSummaryCard({required this.stats});

  String _formatTime(int totalMinutes) {
    if (totalMinutes == 0) return '0h 0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: WorkoutColors.lime(context).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: WorkoutColors.lime(context),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Workout Summary',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: WorkoutColors.onSurface(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryStat(
                label: 'Workouts',
                value: '${stats.weeklyCompleted}',
              ),
              _SummaryStat(
                label: 'Total Time',
                value: _formatTime(stats.totalMinutesThisWeek),
              ),
              _SummaryStat(
                label: 'Calories',
                value: NumberFormat('#,###').format(stats.caloriesThisWeek),
                highlightValue: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlightValue;

  const _SummaryStat({
    required this.label,
    required this.value,
    this.highlightValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: WorkoutColors.onSurfaceMuted(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: highlightValue
                ? WorkoutColors.lime(context)
                : WorkoutColors.onSurface(context),
          ),
        ),
      ],
    );
  }
}

class _CaloriesChartCard extends StatelessWidget {
  final WorkoutHubStats stats;

  const _CaloriesChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxCalories = stats.caloriesByWeekday.fold(
      0,
      (a, b) => a > b ? a : b,
    );
    final double maxY =
        (maxCalories < 1000 ? 1000 : ((maxCalories ~/ 500) + 1) * 500)
            .toDouble();

    // Shift array to start on Monday (1) to Sunday (7) if needed, assuming it's already Mon-Sun
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calories Burned',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: WorkoutColors.onSurface(context),
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(stats.caloriesThisWeek)} kcal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: WorkoutColors.onSurface(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: WorkoutColors.border(context).withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxY / 2,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value >= 1000
                                ? '${(value / 1000).toStringAsFixed(0)}K'
                                : value.toStringAsFixed(0),
                            style: GoogleFonts.inter(
                              color: WorkoutColors.onSurfaceMuted(context),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[index],
                            style: GoogleFonts.inter(
                              color: WorkoutColors.onSurfaceMuted(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} kcal',
                        GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stats.caloriesByWeekday[i].toDouble(),
                        color: WorkoutColors.lime(context),
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleFocusCard extends StatelessWidget {
  final WorkoutHubStats stats;

  const _MuscleFocusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.muscleVolume.isEmpty) return const SizedBox.shrink();

    // Calculate total volume to get percentages
    final double totalVolume = stats.muscleVolume.values.fold(
      0,
      (sum, v) => sum + v,
    );
    if (totalVolume == 0) return const SizedBox.shrink();

    // Sort by volume descending and take top 4
    final sortedEntries = stats.muscleVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(4).toList();

    // Professional color palette for chart segments
    final colors = [
      WorkoutColors.lime(context),
      WorkoutColors.lime(context).withValues(alpha: 0.6),
      WorkoutColors.lime(context).withValues(alpha: 0.3),
      WorkoutColors.onSurfaceMuted(context).withValues(alpha: 0.4),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Focus',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: WorkoutColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Doughnut Chart
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    sections: topEntries.asMap().entries.map((e) {
                      final pct = (e.value.value / totalVolume) * 100;
                      return PieChartSectionData(
                        color: colors[e.key],
                        value: pct,
                        title: '',
                        radius: 20,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Legend
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: topEntries.asMap().entries.map((e) {
                    final pct = (e.value.value / totalVolume) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[e.key],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _capitalize(e.value.key),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: WorkoutColors.onSurface(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: WorkoutColors.onSurfaceMuted(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
