// lib/features/home/presentation/widgets/activity_rings_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:befit/features/home/presentation/widgets/home_theme.dart';
import 'package:befit/features/workout/data/models/workout_history_entry.dart';
import 'package:befit/features/workout/presentation/providers/workout_hub_provider.dart';
import 'package:befit/features/workout/presentation/providers/workout_history_provider.dart';

class ActivityRingsCard extends StatelessWidget {
  const ActivityRingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hubProvider = context.watch<WorkoutHubProvider>();
    final historyProvider = context.watch<WorkoutHistoryProvider>();

    final isNotReady = !hubProvider.isInitialized || !historyProvider.isInitialized;
    final isLoading = hubProvider.isLoading || historyProvider.isLoading;

    if (isNotReady || (isLoading && hubProvider.stats.weeklyGoal == 0)) {
      return _buildLoadingState(context);
    }

    final stats = hubProvider.stats;
    final barData = _buildBarData(historyProvider.history);
    final todayIdx = DateTime.now().weekday - 1;
    final maxMin = barData.map((d) => d.minutes).fold(0.0, (a, b) => a > b ? a : b);
    final todayMinutes = barData[todayIdx].minutes;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final customColors = context.customColors;
    final accent = HomeUi.accent(context);

    // Responsive scaling
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
            color: accent.withValues(alpha: isDark ? 0.06 : 0.02),
            blurRadius: 24 * s,
            spreadRadius: 1 * s,
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
                      'Weekly Activity',
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
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.6),
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
                            'ACTIVE TRAINING TRACKER',
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
              _StreakBadge(streak: stats.currentStreak),
            ],
          ),
          SizedBox(height: 18 * s),

          // ── Today Status Banner ────────────────────────────
          _TodayBanner(
            trainedToday: stats.trainedToday,
            todayMinutes: todayMinutes,
          ),
          SizedBox(height: 22 * s),

          // ── 7-Day Bar Chart ────────────────────────────────
          _WeekView(
            bars: barData,
            todayIdx: todayIdx,
            maxMinutes: maxMin > 0 ? maxMin : 45.0,
          ),
          SizedBox(height: 22 * s),

          // ── Divider ────────────────────────────────────────
          Container(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          SizedBox(height: 18 * s),

          // ── Bottom Summary Tiles ───────────────────────────
          _StatsRow(stats: stats),
        ],
      ),
    );
  }

  List<_DayData> _buildBarData(List<WorkoutHistoryEntry> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return List.generate(7, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      double mins = 0;
      for (final e in history) {
        if (e.date == key) mins += e.durationSeconds / 60.0;
      }
      return _DayData(label: labels[i], minutes: mins);
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final colorScheme = Theme.of(context).colorScheme;
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
                    height: 18 * s,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  Container(
                    width: 100 * s,
                    height: 12 * s,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 60 * s,
                height: 30 * s,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          SizedBox(height: 18 * s),
          Container(
            width: double.infinity,
            height: 46 * s,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          SizedBox(height: 24 * s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              7,
              (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16 * s,
                        height: (40 + (i % 4) * 16).toDouble() * s,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      Container(
                        width: 12 * s,
                        height: 12 * s,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24 * s),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8.0 * s : 0.0),
                  child: Container(
                    height: 54 * s,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(14),
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
            color: colorScheme.primary.withValues(alpha: 0.07),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today Banner
// ─────────────────────────────────────────────────────────────────────────────

class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.trainedToday, required this.todayMinutes});

  final bool trainedToday;
  final double todayMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = HomeUi.accent(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    final bg = trainedToday
        ? accent.withValues(alpha: isDark ? 0.08 : 0.06)
        : theme.colorScheme.onSurface.withValues(alpha: 0.04);
    final border = trainedToday
        ? accent.withValues(alpha: 0.16)
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final iconColor = trainedToday ? accent : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: border, width: 1.0 * s),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              color: trainedToday
                  ? accent.withValues(alpha: 0.12)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              trainedToday ? Icons.fitness_center_rounded : Icons.info_outline_rounded,
              color: iconColor,
              size: 16 * s,
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trainedToday ? 'Today\'s Session Complete' : 'Active Recovery Day',
                  style: GoogleFonts.montserrat(
                    fontSize: 13 * fs,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trainedToday
                      ? 'You crushed your training today! Logged ${todayMinutes.round()}m of active time.'
                      : 'Take it easy today. Focus on stretching, breathing, and muscle recovery.',
                  style: GoogleFonts.montserrat(
                    fontSize: 10.5 * fs,
                    fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// 7-Day Bar Chart
// ─────────────────────────────────────────────────────────────────────────────

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.bars,
    required this.todayIdx,
    required this.maxMinutes,
  });

  final List<_DayData> bars;
  final int todayIdx;
  final double maxMinutes;

  static const double _kBarH = 112;
  static const double _kGap = 7;
  static const double _kTopRadius = 12;

  @override
  Widget build(BuildContext context) {
    final accent = HomeUi.accent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.04);
        
    final dashedLineColor = theme.colorScheme.onSurface.withValues(alpha: 0.12);

    return LayoutBuilder(
      builder: (context, box) {
        final scaledGap = _kGap * s;
        final barW = (box.maxWidth - scaledGap * (bars.length - 1)) / bars.length;

        // Base goal line relative position (assuming daily goal is 45 min)
        final dailyGoal = 45.0;
        final goalHeight = (_kBarH * s * (dailyGoal / maxMinutes).clamp(0.0, 1.0));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // ── Dashed goal line in background ───────────────────
                Positioned(
                  bottom: goalHeight,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          size: const Size(double.infinity, 1.0),
                          painter: _DashedLinePainter(color: dashedLineColor),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Goal (45m)',
                        style: GoogleFonts.montserrat(
                          fontSize: 8.5 * fs,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Ticks + Bars ─────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(top: 18 * s), // spacing for labels
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < bars.length; i++) ...[
                        if (i > 0) SizedBox(width: scaledGap),
                        SizedBox(
                          width: barW,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Text value above the bar
                              SizedBox(
                                height: 16 * s,
                                child: bars[i].minutes > 0
                                    ? Center(
                                        child: Text(
                                          '${bars[i].minutes.round()}m',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 9 * fs,
                                            fontWeight: FontWeight.w800,
                                            color: i == todayIdx ? accent : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              
                              // Capsule bar
                              _Bar(
                                data: bars[i],
                                isToday: i == todayIdx,
                                isFuture: i > todayIdx,
                                maxMinutes: maxMinutes,
                                dailyGoal: dailyGoal,
                                barH: _kBarH * s,
                                barW: barW,
                                radius: _kTopRadius * s,
                                trackColor: trackColor,
                                accent: accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Base line
            Container(
              height: 1.5 * s,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.0),
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Day Labels
            Row(
              children: [
                for (int i = 0; i < bars.length; i++) ...[
                  if (i > 0) SizedBox(width: scaledGap),
                  SizedBox(
                    width: barW,
                    child: Text(
                      bars[i].label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 12 * fs,
                        fontWeight: i == todayIdx ? FontWeight.w900 : FontWeight.w700,
                        color: i == todayIdx
                            ? accent
                            : i > todayIdx
                            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.data,
    required this.isToday,
    required this.isFuture,
    required this.maxMinutes,
    required this.dailyGoal,
    required this.barH,
    required this.barW,
    required this.radius,
    required this.trackColor,
    required this.accent,
  });

  final _DayData data;
  final bool isToday;
  final bool isFuture;
  final double maxMinutes;
  final double dailyGoal;
  final double barH;
  final double barW;
  final double radius;
  final Color trackColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1.0);
    final hasActivity = data.minutes > 0;
    
    final fillH = hasActivity
        ? (barH * (data.minutes / maxMinutes).clamp(0.0, 1.0)).clamp(6.0 * s, barH)
        : 0.0;

    final topRadius = BorderRadius.circular(radius);

    // track color
    final track = isFuture ? trackColor.withValues(alpha: trackColor.a * 0.5) : trackColor;

    // fill color
    final gradientColors = isToday
        ? [accent, accent.withValues(alpha: 0.8)]
        : [accent.withValues(alpha: 0.75), accent.withValues(alpha: 0.6)];

    final reachedGoal = data.minutes >= dailyGoal;

    return SizedBox(
      width: barW,
      height: barH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ── track ─────────────────────────────────────────────
          Container(
            width: barW,
            height: barH,
            decoration: BoxDecoration(
              color: track,
              borderRadius: topRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.02),
                width: 1.0 * s,
              ),
            ),
          ),

          // ── animated fill ─────────────────────────────────────
          if (hasActivity)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fillH),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, h, _) {
                final liveRadius = BorderRadius.circular(radius);
                return Container(
                  width: barW,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: gradientColors,
                    ),
                    borderRadius: liveRadius,
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.28),
                              blurRadius: 10 * s,
                              offset: Offset(0, -3 * s),
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),

          // ── today active base indicator dot ──
          if (isToday && !hasActivity)
            Positioned(
              bottom: 5 * s,
              child: Container(
                width: 5 * s,
                height: 5 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.60),
                ),
              ),
            ),

          // ── met-goal indicator dot above the bar ──
          if (hasActivity && reachedGoal)
            Positioned(
              top: -6 * s,
              child: Container(
                width: 4 * s,
                height: 4 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.8),
                      blurRadius: 4 * s,
                      spreadRadius: 0.5 * s,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Summary Tiles
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    final accent = HomeUi.accent(context);
    final customColors = context.customColors;
    
    final s = Responsive.scale(context, 1.0);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Sessions',
            value: '${stats.weeklyCompleted}',
            suffix: '/${stats.weeklyGoal}',
            icon: Icons.check_circle_outline_rounded,
            color: accent,
            progress: stats.weeklyGoal > 0
                ? (stats.weeklyCompleted / stats.weeklyGoal).clamp(0.0, 1.0)
                : 0.0,
          ),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: _SummaryCard(
            label: 'Minutes',
            value: '${stats.totalMinutesThisWeek}',
            suffix: ' min',
            icon: Icons.timer_outlined,
            color: customColors.calorieRing,
          ),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: _SummaryCard(
            label: 'Calories',
            value: '${stats.caloriesThisWeek}',
            suffix: ' kcal',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
    this.progress,
  });

  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    return Container(
      padding: EdgeInsets.all(12 * s),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13 * s, color: color),
              SizedBox(width: 4 * s),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 10 * fs,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.montserrat(
                      fontSize: 18 * fs,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: suffix,
                    style: GoogleFonts.montserrat(
                      fontSize: 10 * fs,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (progress != null) ...[
            SizedBox(height: 8 * s),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 4 * s,
                child: Stack(
                  children: [
                    Container(color: color.withValues(alpha: 0.12)),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.70), color],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    const fireColor = Color(0xFFF97316);
    
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: fireColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(
          color: fireColor.withValues(alpha: 0.16),
          width: 1.0 * s,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: fireColor,
            size: 14 * s,
          ),
          SizedBox(width: 4 * s),
          Text(
            '$streak Day Streak',
            style: GoogleFonts.montserrat(
              fontSize: 10 * fs,
              fontWeight: FontWeight.w800,
              color: fireColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayData {
  const _DayData({required this.label, required this.minutes});
  final String label;
  final double minutes;
}

