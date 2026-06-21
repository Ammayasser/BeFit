// lib/features/profile/presentation/widgets/activity_heatmap_card.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../features/workout/data/models/workout_history_entry.dart';
import '../../../../features/workout/presentation/providers/workout_history_provider.dart';
import '../../../../features/workout/data/repositories/workout_stats_repository.dart';
import '../providers/user_provider.dart';

enum HeatmapMetric { workouts, calories, volume, duration }

// ── Supporting Data Classes (Moved up to fix "not a type" errors) ──

class _DayData {
  final String date;
  final int sessionCount, totalDurationSeconds;
  final double totalVolume;
  final int totalCalories, totalSets, totalReps;
  final List<String> workoutNames;
  final int intensityLevel;

  _DayData({
    required this.date,
    required this.sessionCount,
    required this.totalDurationSeconds,
    required this.totalVolume,
    required this.totalCalories,
    required this.totalSets,
    required this.totalReps,
    required this.workoutNames,
    this.intensityLevel = 0,
  });

  _DayData copyWith({
    int? intensityLevel,
    int? sessionCount,
    int? totalDurationSeconds,
    double? totalVolume,
    int? totalCalories,
    int? totalSets,
    int? totalReps,
    List<String>? workoutNames,
  }) => _DayData(
    date: date,
    sessionCount: sessionCount ?? this.sessionCount,
    totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
    totalVolume: totalVolume ?? this.totalVolume,
    totalCalories: totalCalories ?? this.totalCalories,
    totalSets: totalSets ?? this.totalSets,
    totalReps: totalReps ?? this.totalReps,
    workoutNames: workoutNames ?? this.workoutNames,
    intensityLevel: intensityLevel ?? this.intensityLevel,
  );
}

class _HeatmapDay {
  final String date;
  final bool isInYear, isFuture, isToday;
  final _DayData? data;
  _HeatmapDay({
    required this.date,
    required this.isInYear,
    required this.isFuture,
    required this.isToday,
    this.data,
  });
}

class _HeatmapSummary {
  final double totalValue;
  final String totalLabel;
  final int longestStreak, totalActiveDays;
  _HeatmapSummary({
    required this.totalValue,
    required this.totalLabel,
    required this.longestStreak,
    required this.totalActiveDays,
  });
}

class _HeatmapData {
  final List<List<_HeatmapDay>> grid;
  final _HeatmapSummary summary;
  final Map<String, _DayData> dayDataMap;
  _HeatmapData({
    required this.grid,
    required this.summary,
    required this.dayDataMap,
  });
}

// ── Main Card Widget ──

class ActivityHeatmapCard extends StatefulWidget {
  const ActivityHeatmapCard({super.key});

  @override
  State<ActivityHeatmapCard> createState() => _ActivityHeatmapCardState();
}

class _ActivityHeatmapCardState extends State<ActivityHeatmapCard> {
  int _selectedYear = DateTime.now().year;
  HeatmapMetric _selectedMetric = HeatmapMetric.workouts;
  String? _hoveredDate;
  Offset? _hoverPosition;
  Timer? _dismissTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToToday();
  }

  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final s = Responsive.scale(context, 1);
        final cellSize = 13 * s;
        final gap = 3 * s;
        final now = DateTime.now();
        final jan1 = DateTime(now.year, 1, 1);
        final weekIdx = (now.difference(jan1).inDays / 7).floor();
        final scrollPos =
            (weekIdx * (cellSize + gap)) -
            (MediaQuery.of(context).size.width / 3);
        _scrollController.animateTo(
          scrollPos.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showTooltip(String date, Offset pos, {bool autoDismiss = false}) {
    _dismissTimer?.cancel();
    setState(() {
      _hoveredDate = date;
      _hoverPosition = pos;
    });
    if (autoDismiss) {
      _dismissTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _hoveredDate = null;
            _hoverPosition = null;
          });
        }
      });
    }
  }

  void _hideTooltip() {
    _dismissTimer?.cancel();
    if (_hoveredDate != null) {
      setState(() {
        _hoveredDate = null;
        _hoverPosition = null;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = Theme.of(context);
    final customColors = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final history = context.watch<WorkoutHistoryProvider>().history;
    final userWeight = context.watch<UserProvider>().weight;
    final data = _useHeatmapData(
      _selectedYear,
      _selectedMetric,
      history,
      userWeight,
    );

    return Listener(
      onPointerDown: (_) => _hideTooltip(),
      child: GestureDetector(
        onTap: _hideTooltip,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24 * s),
          decoration: BoxDecoration(
            color: isDark ? customColors.surfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(24 * s),
            border: Border.all(color: customColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVITY HISTORY',
                          style: GoogleFonts.montserrat(
                            fontSize: 10 * s,
                            fontWeight: FontWeight.w800,
                            color: customColors.setupTextSecondary.withValues(
                              alpha: 0.6,
                            ),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 6 * s),
                        _buildSummaryText(
                          context,
                          data.summary,
                          _selectedMetric,
                          s,
                        ),
                      ],
                    ),
                  ),
                  _YearSelector(
                    year: _selectedYear,
                    onChanged: (y) {
                      setState(() => _selectedYear = y);
                      HapticFeedback.selectionClick();
                      _scrollToToday();
                    },
                    s: s,
                  ),
                ],
              ),
              SizedBox(height: 24 * s),
              _MetricToggle(
                selected: _selectedMetric,
                onChanged: (m) {
                  setState(() => _selectedMetric = m);
                  HapticFeedback.lightImpact();
                },
                s: s,
              ),
              SizedBox(height: 24 * s),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = 13 * s;
                  final gap = 3 * s;
                  final gridHeight = (cellSize + gap) * 7 + 25 * s;
                  return SizedBox(
                    height: gridHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WeekdayLabels(cellSize: cellSize, gap: gap, s: s),
                        SizedBox(width: 8 * s),
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: _HeatmapGrid(
                                  grid: data.grid,
                                  metric: _selectedMetric,
                                  isDark: isDark,
                                  cellSize: cellSize,
                                  gap: gap,
                                  s: s,
                                  onHover: (date, pos) =>
                                      _showTooltip(date, pos),
                                  onTap: (date, pos) => _showTooltip(
                                    date,
                                    pos,
                                    autoDismiss: true,
                                  ),
                                  onLeave: () => _hideTooltip(),
                                ),
                              ),
                              if (_hoveredDate != null &&
                                  _hoverPosition != null)
                                _HeatmapTooltip(
                                  date: _hoveredDate!,
                                  data: data.dayDataMap[_hoveredDate],
                                  position: _hoverPosition!,
                                  s: s,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 12 * s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BottomStat(
                    label: 'Streak',
                    value: '${data.summary.longestStreak} days',
                    icon: PhosphorIcons.fire(PhosphorIconsStyle.fill),
                    color: Colors.orange,
                    s: s,
                  ),
                  _HeatmapLegend(metric: _selectedMetric, isDark: isDark, s: s),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryText(
    BuildContext context,
    _HeatmapSummary summary,
    HeatmapMetric metric,
    double s,
  ) {
    final colors = context.customColors;
    return RichText(
      text: TextSpan(
        style: GoogleFonts.montserrat(
          fontSize: 14 * s,
          fontWeight: FontWeight.w600,
          color: colors.setupTextPrimary,
        ),
        children: [
          TextSpan(
            text: summary.totalLabel.split(' ')[0],
            style: TextStyle(
              color: colors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: ' ${summary.totalLabel.split(' ').sublist(1).join(' ')}',
          ),
        ],
      ),
    );
  }

  _HeatmapData _useHeatmapData(
    int year,
    HeatmapMetric metric,
    List<WorkoutHistoryEntry> history,
    double userWeight,
  ) {
    final dayDataMap = <String, _DayData>{};
    for (final entry in history) {
      DateTime? dt;
      try {
        dt = DateTime.parse(entry.date);
      } catch (_) {
        continue;
      }
      if (dt.year != year) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(dt);
      final existing = dayDataMap[dateKey];
      if (existing == null) {
        dayDataMap[dateKey] = _DayData(
          date: dateKey,
          sessionCount: 1,
          totalDurationSeconds: entry.durationSeconds,
          totalVolume: entry.totalVolume,
          totalCalories: WorkoutStatsRepository.estimateCaloriesFromLog(entry, userWeight),
          totalSets: entry.totalSets,
          totalReps: entry.totalReps,
          workoutNames: [entry.focus ?? 'Workout'],
        );
      } else {
        dayDataMap[dateKey] = existing.copyWith(
          sessionCount: existing.sessionCount + 1,
          totalDurationSeconds:
              existing.totalDurationSeconds + entry.durationSeconds,
          totalVolume: existing.totalVolume + entry.totalVolume,
          totalCalories:
              existing.totalCalories +
              WorkoutStatsRepository.estimateCaloriesFromLog(entry, userWeight),
          totalSets: existing.totalSets + entry.totalSets,
          totalReps: existing.totalReps + entry.totalReps,
          workoutNames: [...existing.workoutNames, entry.focus ?? 'Workout'],
        );
      }
    }
    final nonZeroValues =
        dayDataMap.values
            .map((d) => _getMetricValue(d, metric))
            .where((v) => v > 0)
            .toList()
          ..sort();
    final thresholds = _computeThresholds(nonZeroValues);
    for (final date in dayDataMap.keys) {
      final d = dayDataMap[date]!;
      dayDataMap[date] = d.copyWith(
        intensityLevel: _getIntensityLevel(
          _getMetricValue(d, metric),
          thresholds,
        ),
      );
    }
    return _HeatmapData(
      grid: _buildYearGrid(year, dayDataMap),
      summary: _computeYearSummary(dayDataMap, metric, year),
      dayDataMap: dayDataMap,
    );
  }

  double _getMetricValue(_DayData data, HeatmapMetric metric) {
    switch (metric) {
      case HeatmapMetric.workouts:
        return data.sessionCount.toDouble();
      case HeatmapMetric.calories:
        return data.totalCalories.toDouble();
      case HeatmapMetric.volume:
        return data.totalVolume;
      case HeatmapMetric.duration:
        return data.totalDurationSeconds.toDouble();
    }
  }

  List<double> _computeThresholds(List<double> values) {
    if (values.isEmpty) return [0, 0, 0, 0];
    final n = values.length;
    if (n == 1) return [values[0] - 1, values[0], values[0], values[0]];
    return [
      values[(n * 0.25).floor().clamp(0, n - 1)],
      values[(n * 0.50).floor().clamp(0, n - 1)],
      values[(n * 0.75).floor().clamp(0, n - 1)],
      values[(n * 0.95).floor().clamp(0, n - 1)],
    ];
  }

  int _getIntensityLevel(double value, List<double> thresholds) {
    if (value <= 0) return 0;
    if (value < thresholds[0]) return 1;
    if (value < thresholds[1]) return 2;
    if (value < thresholds[2]) return 3;
    return 4;
  }

  List<List<_HeatmapDay>> _buildYearGrid(
    int year,
    Map<String, _DayData> dayDataMap,
  ) {
    final jan1 = DateTime(year, 1, 1);
    var current = jan1.subtract(Duration(days: jan1.weekday - 1));
    final weeks = <List<_HeatmapDay>>[];
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    for (var w = 0; w < 54; w++) {
      final week = <_HeatmapDay>[];
      for (var d = 0; d < 7; d++) {
        final dateStr = DateFormat('yyyy-MM-dd').format(current);
        week.add(
          _HeatmapDay(
            date: dateStr,
            isInYear: current.year == year,
            isFuture: current.isAfter(now),
            isToday: dateStr == todayStr,
            data: current.year == year && !current.isAfter(now)
                ? dayDataMap[dateStr]
                : null,
          ),
        );
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
      if (current.year > year && current.weekday == 1) break;
    }
    return weeks;
  }

  _HeatmapSummary _computeYearSummary(
    Map<String, _DayData> dayDataMap,
    HeatmapMetric metric,
    int year,
  ) {
    final activeDays = dayDataMap.values
        .where((d) => d.sessionCount > 0)
        .toList();
    final totalValue = activeDays.fold(
      0.0,
      (sum, d) => sum + _getMetricValue(d, metric),
    );
    int longestStreak = 0;
    int currentStreak = 0;
    final sortedDates = activeDays.map((d) => DateTime.parse(d.date)).toList()
      ..sort();
    if (sortedDates.isNotEmpty) {
      currentStreak = 1;
      for (var i = 0; i < sortedDates.length - 1; i++) {
        if (sortedDates[i + 1].difference(sortedDates[i]).inDays == 1) {
          currentStreak++;
        } else {
          longestStreak = math.max(longestStreak, currentStreak);
          currentStreak = 1;
        }
      }
      longestStreak = math.max(longestStreak, currentStreak);
    }
    return _HeatmapSummary(
      totalValue: totalValue,
      totalLabel: _formatMetricTotal(totalValue, metric),
      longestStreak: longestStreak,
      totalActiveDays: activeDays.length,
    );
  }

  String _formatMetricTotal(double value, HeatmapMetric metric) {
    switch (metric) {
      case HeatmapMetric.workouts:
        return '${value.toInt()} sessions';
      case HeatmapMetric.calories:
        return '${NumberFormat('#,###').format(value)} kcal';
      case HeatmapMetric.volume:
        return value >= 1000
            ? '${(value / 1000).toStringAsFixed(1)}k kg'
            : '${value.toInt()} kg';
      case HeatmapMetric.duration:
        return '${(value / 3600).floor()} hours';
    }
  }
}

// ── Shared UI Helpers ──

Color _getCellColor(int level, HeatmapMetric metric, bool isDark) {
  final darkColors = {
    HeatmapMetric.workouts: [
      const Color(0xFF2C3036),
      const Color(0xFF0E4429),
      const Color(0xFF006D32),
      const Color(0xFF26A641),
      const Color(0xFF39D353),
    ],
    HeatmapMetric.calories: [
      const Color(0xFF2C3036),
      const Color(0xFF3D1A00),
      const Color(0xFF7A3500),
      const Color(0xFFB85000),
      const Color(0xFFD4845A),
    ],
    HeatmapMetric.volume: [
      const Color(0xFF2C3036),
      const Color(0xFF0D2D4A),
      const Color(0xFF1A4A7A),
      const Color(0xFF1E6BBF),
      const Color(0xFF4DA6FF),
    ],
    HeatmapMetric.duration: [
      const Color(0xFF2C3036),
      const Color(0xFF2D1B4E),
      const Color(0xFF4A2D7A),
      const Color(0xFF6B3FA0),
      const Color(0xFF9B59D0),
    ],
  };
  final lightColors = {
    HeatmapMetric.workouts: [
      const Color(0xFFE5E7EB),
      const Color(0xFF9BE9A8),
      const Color(0xFF40C463),
      const Color(0xFF30A14E),
      const Color(0xFF216E39),
    ],
    HeatmapMetric.calories: [
      const Color(0xFFE5E7EB),
      const Color(0xFFFFCBA4),
      const Color(0xFFFF8C42),
      const Color(0xFFE06A1A),
      const Color(0xFFC0440A),
    ],
    HeatmapMetric.volume: [
      const Color(0xFFE5E7EB),
      const Color(0xFFB3D1EC),
      const Color(0xFF5A8FA8),
      const Color(0xFF2A6FA8),
      const Color(0xFF0D4F8C),
    ],
    HeatmapMetric.duration: [
      const Color(0xFFE5E7EB),
      const Color(0xFFD8B4F0),
      const Color(0xFFA855F7),
      const Color(0xFF7C3AED),
      const Color(0xFF5B21B6),
    ],
  };
  return (isDark ? darkColors[metric]! : lightColors[metric]!)[level.clamp(
    0,
    4,
  )];
}

// ── Components ──

class _WeekdayLabels extends StatelessWidget {
  final double cellSize, gap, s;
  const _WeekdayLabels({
    required this.cellSize,
    required this.gap,
    required this.s,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      SizedBox(height: 25 * s),
      _label('Mon'),
      SizedBox(height: cellSize + gap),
      _label('Wed'),
      SizedBox(height: cellSize + gap),
      _label('Fri'),
    ],
  );
  Widget _label(String txt) => Container(
    height: cellSize,
    alignment: Alignment.centerRight,
    child: Text(
      txt,
      style: GoogleFonts.montserrat(
        fontSize: 8 * s,
        fontWeight: FontWeight.w700,
        color: Colors.grey.withValues(alpha: 0.5),
      ),
    ),
  );
}

class _HeatmapGrid extends StatelessWidget {
  final List<List<_HeatmapDay>> grid;
  final HeatmapMetric metric;
  final bool isDark;
  final double cellSize, gap, s;
  final Function(String, Offset) onHover, onTap;
  final VoidCallback onLeave;

  const _HeatmapGrid({
    required this.grid,
    required this.metric,
    required this.isDark,
    required this.cellSize,
    required this.gap,
    required this.s,
    required this.onHover,
    required this.onTap,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: _buildMonthLabels(s)),
      SizedBox(height: 8 * s),
      Row(
        children: grid
            .map(
              (week) => Column(
                children: week
                    .map(
                      (day) => _HeatmapCell(
                        day: day,
                        metric: metric,
                        isDark: isDark,
                        size: cellSize,
                        gap: gap,
                        onHover: onHover,
                        onTap: onTap,
                        onLeave: onLeave,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    ],
  );

  List<Widget> _buildMonthLabels(double s) {
    final labels = <Widget>[];
    String lastMonth = '';
    for (var w = 0; w < grid.length; w++) {
      final dt = DateTime.parse(grid[w][0].date);
      final monthName = DateFormat('MMM').format(dt);
      if (monthName != lastMonth) {
        labels.add(
          SizedBox(
            width: (cellSize + gap) * 4.3,
            child: Text(
              monthName,
              style: GoogleFonts.montserrat(
                fontSize: 9 * s,
                fontWeight: FontWeight.w700,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
        lastMonth = monthName;
        w += 3;
      }
    }
    return labels;
  }
}

class _HeatmapCell extends StatelessWidget {
  final _HeatmapDay day;
  final HeatmapMetric metric;
  final bool isDark;
  final double size, gap;
  final Function(String, Offset) onHover, onTap;
  final VoidCallback onLeave;

  const _HeatmapCell({
    required this.day,
    required this.metric,
    required this.isDark,
    required this.size,
    required this.gap,
    required this.onHover,
    required this.onTap,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    if (!day.isInYear) return SizedBox(width: size + gap, height: size + gap);
    final color = _getCellColor(day.data?.intensityLevel ?? 0, metric, isDark);
    return MouseRegion(
      onEnter: (event) {
        if (!day.isFuture) onHover(day.date, event.position);
      },
      onHover: (event) {
        if (!day.isFuture) onHover(day.date, event.position);
      },
      onExit: (_) => onLeave(),
      child: GestureDetector(
        onTap: () {
          if (!day.isFuture) onTap(day.date, Offset.zero);
        },
        child: Container(
          width: size,
          height: size,
          margin: EdgeInsets.all(gap / 2),
          decoration: BoxDecoration(
            color: day.isFuture ? color.withValues(alpha: 0.1) : color,
            borderRadius: BorderRadius.circular(2.5),
            border: day.isToday
                ? Border.all(color: context.customColors.success, width: 1.5)
                : null,
          ),
        ),
      ),
    );
  }
}

class _HeatmapTooltip extends StatelessWidget {
  final String date;
  final _DayData? data;
  final Offset position;
  final double s;
  const _HeatmapTooltip({
    required this.date,
    this.data,
    required this.position,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final custom = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final tooltipWidth = 170 * s;
    final tooltipHeight = 110 * s;
    double left = position.dx - (tooltipWidth / 2);
    if (left + tooltipWidth > screenWidth - 20) {
      left = screenWidth - tooltipWidth - 20;
    }
    if (left < 20) {
      left = 20;
    }
    double top = position.dy - tooltipHeight - 20;
    if (top < 20) {
      top = position.dy + 20;
    }

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: EdgeInsets.all(12 * s),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(12 * s),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15),
            ],
            border: Border.all(color: custom.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(DateTime.parse(date)),
                style: GoogleFonts.montserrat(
                  fontSize: 10 * s,
                  fontWeight: FontWeight.w700,
                  color: custom.setupTextSecondary,
                ),
              ),
              const Divider(height: 12),
              if (data == null)
                Text(
                  'Rest Day 😴',
                  style: GoogleFonts.inter(
                    fontSize: 11 * s,
                    color: custom.setupTextPrimary,
                  ),
                )
              else ...[
                _row('💪', '${data!.sessionCount} sessions'),
                _row('🔥', '${data!.totalCalories} kcal'),
                _row('🏋️', '${data!.totalVolume.toInt()} kg'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String i, String l) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(i, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Text(
          l,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

class _HeatmapLegend extends StatelessWidget {
  final HeatmapMetric metric;
  final bool isDark;
  final double s;
  const _HeatmapLegend({
    required this.metric,
    required this.isDark,
    required this.s,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'Less',
        style: GoogleFonts.montserrat(fontSize: 9 * s, color: Colors.grey),
      ),
      SizedBox(width: 6 * s),
      ...List.generate(
        5,
        (i) => Container(
          width: 9 * s,
          height: 9 * s,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: _getCellColor(i, metric, isDark),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      SizedBox(width: 6 * s),
      Text(
        'More',
        style: GoogleFonts.montserrat(fontSize: 9 * s, color: Colors.grey),
      ),
    ],
  );
}

class _MetricToggle extends StatelessWidget {
  final HeatmapMetric selected;
  final Function(HeatmapMetric) onChanged;
  final double s;
  const _MetricToggle({
    required this.selected,
    required this.onChanged,
    required this.s,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab(context, '💪', HeatmapMetric.workouts),
        SizedBox(width: 8 * s),
        _tab(context, '🔥', HeatmapMetric.calories),
        SizedBox(width: 8 * s),
        _tab(context, '🏋️', HeatmapMetric.volume),
        SizedBox(width: 8 * s),
        _tab(context, '⏱', HeatmapMetric.duration),
      ],
    );
  }

  Widget _tab(BuildContext context, String icon, HeatmapMetric m) {
    final colors = context.customColors;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(m),
        child: Container(
          height: 38 * s,
          decoration: BoxDecoration(
            color: selected == m ? colors.setupPrimary : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(10 * s),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: TextStyle(fontSize: 16 * s)),
        ),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final Function(int) onChanged;
  final double s;
  const _YearSelector({
    required this.year,
    required this.onChanged,
    required this.s,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.customColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onChanged(year - 1),
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 18 * s,
              color: c.setupTextSecondary,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * s),
            child: Text(
              '$year',
              style: GoogleFonts.montserrat(
                fontSize: 13 * s,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: year < DateTime.now().year
                ? () => onChanged(year + 1)
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 18 * s,
              color: year < DateTime.now().year
                  ? c.setupTextSecondary
                  : Colors.grey.withValues(alpha: 0.3),
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _BottomStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final double s;
  const _BottomStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.s,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 9 * s,
          fontWeight: FontWeight.w700,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Icon(icon, size: 16 * s, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ],
  );
}
