import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout/data/repositories/workout_log_repository.dart';
import '../../../workout/data/models/workout_history_entry.dart';
import '../../../nutrition/data/repositories/nutrition_repository.dart';
import '../../../nutrition/domain/entities/calorie_history_item.dart';

enum ChartTab { workouts, calories }

class ProgressSummaryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final double s;

  const ProgressSummaryCard({
    super.key,
    required this.data,
    required this.s,
  });

  @override
  State<ProgressSummaryCard> createState() => _ProgressSummaryCardState();
}

class _ProgressSummaryCardState extends State<ProgressSummaryCard> {
  final WorkoutLogRepository _logRepo = WorkoutLogRepository();
  final NutritionRepository _nutritionRepo = NutritionRepository();

  List<WorkoutHistoryEntry> _workoutHistory = [];
  List<CalorieHistoryItem> _calorieHistory = [];
  bool _loading = true;
  ChartTab _selectedTab = ChartTab.workouts;

  @override
  void initState() {
    super.initState();
    _detectInitialTab();
    _loadData();
  }

  void _detectInitialTab() {
    final title = widget.data['title']?.toString().toLowerCase() ?? '';
    final subtitle = widget.data['subtitle']?.toString().toLowerCase() ?? '';
    if (title.contains('calor') ||
        subtitle.contains('calor') ||
        title.contains('nutrit') ||
        subtitle.contains('nutrit') ||
        title.contains('eat') ||
        subtitle.contains('eat')) {
      _selectedTab = ChartTab.calories;
    } else {
      _selectedTab = ChartTab.workouts;
    }
  }

  Future<void> _loadData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId ?? '';
      if (userId.isNotEmpty) {
        final start = DateTime.now().subtract(const Duration(days: 6));
        final end = DateTime.now();

        final results = await Future.wait([
          _logRepo.getWorkoutHistory(userId),
          _nutritionRepo.getCalorieHistory(userId, start, end),
        ]);

        if (mounted) {
          setState(() {
            _workoutHistory = results[0] as List<WorkoutHistoryEntry>;
            _calorieHistory = results[1] as List<CalorieHistoryItem>;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final data = widget.data;
    final streak = data['streak'] ?? 0;
    final workouts = data['completedWorkouts'] ?? data['workouts'] ?? 0;
    final calories = data['caloriesAvg'] ?? data['calories'] ?? 0;
    final protein = data['proteinAvg'] ?? data['protein'] ?? 0;

    final custom = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final greenAccent = custom.calorieRing;
    final blueAccent = custom.protein;
    final redAccent = custom.fat;
    final orangeAccent = custom.carbs;

    // Calculate Y / X Bounds and spots depending on selected tab
    final List<FlSpot> spots = [];
    final Map<double, String> xLabels = {};
    bool isEmptyState = false;
    double minY = 0;
    double maxY = 100;
    double minX = 0;
    double maxX = 5;

    if (_selectedTab == ChartTab.workouts) {
      isEmptyState = _workoutHistory.isEmpty;
      if (!isEmptyState) {
        final recent = _workoutHistory.take(7).toList().reversed.toList();
        for (int i = 0; i < recent.length; i++) {
          final entry = recent[i];
          spots.add(FlSpot(i.toDouble(), entry.totalVolume));

          String label = '';
          try {
            final parsed = DateTime.tryParse(entry.completedAt ?? entry.date);
            if (parsed != null) {
              label = DateFormat('M/d').format(parsed);
            } else {
              label = entry.date.substring(5);
            }
          } catch (_) {
            label = 'W${i + 1}';
          }
          xLabels[i.toDouble()] = label;
        }

        if (spots.length == 1) {
          final val = spots.first.y;
          minY = val * 0.8;
          maxY = val * 1.2 == 0 ? 100 : val * 1.2;
          minX = -0.5;
          maxX = 0.5;
        } else {
          final yValues = spots.map((e) => e.y).toList();
          minY = (yValues.reduce((a, b) => a < b ? a : b) * 0.85).clamp(0.0, double.infinity);
          final rawMaxY = yValues.reduce((a, b) => a > b ? a : b) * 1.15;
          maxY = rawMaxY == minY ? minY + 100 : rawMaxY;
          minX = 0;
          maxX = (spots.length - 1).toDouble();
        }
      }
    } else {
      // Calories tab
      isEmptyState = _calorieHistory.isEmpty;
      if (!isEmptyState) {
        final sortedCalories = List<CalorieHistoryItem>.from(_calorieHistory)
          ..sort((a, b) => a.date.compareTo(b.date));

        for (int i = 0; i < sortedCalories.length; i++) {
          final item = sortedCalories[i];
          spots.add(FlSpot(i.toDouble(), item.caloriesEaten));
          xLabels[i.toDouble()] = DateFormat('M/d').format(item.date);
        }

        if (spots.isNotEmpty) {
          final yValues = spots.map((e) => e.y).toList();
          minY = 0.0;
          final maxVal = yValues.reduce((a, b) => a > b ? a : b);
          final goalVal = calories > 0 ? calories.toDouble() : 2000.0;
          final rawMaxY = maxVal > goalVal ? maxVal : goalVal;
          maxY = (rawMaxY * 1.15).clamp(2000.0, double.infinity);
          minX = 0;
          maxX = (spots.length - 1).toDouble();
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: custom.surfaceCard,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: custom.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16 * s),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                  custom.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * s),
                  decoration: BoxDecoration(
                    color: blueAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10 * s),
                  ),
                  child: Icon(Iconsax.graph, color: blueAccent, size: 20 * s),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Progress Report',
                        style: GoogleFonts.montserrat(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (data['subtitle'] != null)
                        Text(
                          data['subtitle'],
                          style: GoogleFonts.inter(
                            fontSize: 11 * s,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Grid
          Padding(
            padding: EdgeInsets.all(16 * s),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12 * s,
              mainAxisSpacing: 12 * s,
              childAspectRatio: 1.6,
              children: [
                _buildStatItem(context, '⚡', '$streak days', 'Active Streak', greenAccent),
                _buildStatItem(context, '💪', '$workouts sessions', 'Workouts Done', blueAccent),
                _buildStatItem(context, '🔥', '$calories kcal', 'Avg Calories', redAccent),
                _buildStatItem(context, '🍗', '${protein}g', 'Avg Protein', orangeAccent),
              ],
            ),
          ),

          // Segmented Tab Selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
            child: Container(
              height: 36 * s,
              padding: EdgeInsets.all(3 * s),
              decoration: BoxDecoration(
                color: custom.surfaceElevated,
                borderRadius: BorderRadius.circular(10 * s),
                border: Border.all(color: custom.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = ChartTab.workouts),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedTab == ChartTab.workouts
                              ? custom.surfaceCard
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8 * s),
                        ),
                        child: Text(
                          'Workouts',
                          style: GoogleFonts.montserrat(
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w700,
                            color: _selectedTab == ChartTab.workouts
                                ? greenAccent
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = ChartTab.calories),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedTab == ChartTab.calories
                              ? custom.surfaceCard
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8 * s),
                        ),
                        child: Text(
                          'Calories',
                          style: GoogleFonts.montserrat(
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w700,
                            color: _selectedTab == ChartTab.calories
                                ? redAccent
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Interactive Progress Chart
          if (_loading)
            Container(
              height: 180 * s,
              width: double.infinity,
              alignment: Alignment.center,
              child: CircularProgressIndicator(color: greenAccent),
            )
          else if (isEmptyState)
            Container(
              height: 140 * s,
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 16 * s),
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              decoration: BoxDecoration(
                color: custom.surfaceElevated,
                borderRadius: BorderRadius.circular(16 * s),
                border: Border.all(color: custom.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedTab == ChartTab.workouts ? Iconsax.chart_21 : Iconsax.judge,
                    color: custom.chartLabel,
                    size: 36 * s,
                  ),
                  SizedBox(height: 12 * s),
                  Text(
                    _selectedTab == ChartTab.workouts
                        ? 'No Workout History Yet'
                        : 'No Calorie History Yet',
                    style: GoogleFonts.montserrat(
                      fontSize: 12 * s,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4 * s),
                  Text(
                    _selectedTab == ChartTab.workouts
                        ? 'Complete session logs to visualize your progressive volume trend here.'
                        : 'Log food items in your diary to visualize your calorie trend here.',
                    style: GoogleFonts.inter(
                      fontSize: 10 * s,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 4 * s),
              child: Text(
                _selectedTab == ChartTab.workouts ? 'Training Volume Trend' : 'Calorie Intake Trend',
                style: GoogleFonts.montserrat(
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              height: 160 * s,
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(12 * s, 16 * s, 20 * s, 8 * s),
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: minX,
                  maxX: maxX,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: custom.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                          return Text(
                            _selectedTab == ChartTab.workouts
                                ? (value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(1)}k'
                                    : value.toStringAsFixed(0))
                                : value.toStringAsFixed(0),
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final label = xLabels[value] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (_selectedTab == ChartTab.calories && calories > 0)
                        HorizontalLine(
                          y: calories.toDouble(),
                          color: redAccent.withValues(alpha: 0.6),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 8, bottom: 2),
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: redAccent,
                            ),
                            labelResolver: (line) => 'Goal: $calories kcal',
                          ),
                        ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => custom.surfaceElevated,
                      tooltipBorderRadius: BorderRadius.circular(8),
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            _selectedTab == ChartTab.workouts
                                ? '${spot.y.toStringAsFixed(0)} kg\n'
                                : '${spot.y.toStringAsFixed(0)} kcal\n',
                            GoogleFonts.montserrat(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: _selectedTab == ChartTab.workouts
                                    ? 'Total Volume'
                                    : 'Calorie Intake',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 9,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      gradient: LinearGradient(
                        colors: _selectedTab == ChartTab.workouts
                            ? (isDark
                                ? [const Color(0xFFB5FF4D), const Color(0xFF7CA794)]
                                : [const Color(0xFF16A34A), const Color(0xFF059669)])
                            : (isDark
                                ? [const Color(0xFFEF4444), const Color(0xFFF59E0B)]
                                : [const Color(0xFFDC2626), const Color(0xFFD97706)]),
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: _selectedTab == ChartTab.workouts
                              ? greenAccent
                              : redAccent,
                          strokeWidth: 2,
                          strokeColor: custom.surfaceCard,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: _selectedTab == ChartTab.workouts
                              ? [
                                  greenAccent.withValues(alpha: 0.15),
                                  greenAccent.withValues(alpha: 0.0),
                                ]
                              : [
                                  redAccent.withValues(alpha: 0.15),
                                  redAccent.withValues(alpha: 0.0),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12 * s),
          ],

          // Coach Note
          if (data['coachNote'] != null)
            Container(
              margin: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
              padding: EdgeInsets.all(14 * s),
              decoration: BoxDecoration(
                color: blueAccent.withValues(alpha: isDark ? 0.06 : 0.04),
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(color: blueAccent.withValues(alpha: isDark ? 0.15 : 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.message_favorite, color: blueAccent, size: 16 * s),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      data['coachNote'],
                      style: GoogleFonts.inter(
                        fontSize: 12 * s,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String emoji, String value, String label, Color accentColor) {
    final s = widget.s;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final custom = context.customColors;

    return Container(
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: custom.surfaceElevated,
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: custom.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 14 * s)),
              SizedBox(width: 6 * s),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10 * s,
                    color: isDark ? const Color(0xFFA0A3AB) : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 15 * s,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
