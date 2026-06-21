// lib/features/nutrition/presentation/widgets/nutrition_analytics_report.dart

import 'dart:math' as math;
import 'package:befit/features/nutrition/data/models/meal_log.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/nutrition_provider.dart';
import '../../domain/entities/calorie_history_item.dart';
import 'nutrition_colors.dart';

class NutritionAnalyticsReport extends StatefulWidget {
  const NutritionAnalyticsReport({super.key});

  @override
  State<NutritionAnalyticsReport> createState() =>
      _NutritionAnalyticsReportState();
}

class _NutritionAnalyticsReportState extends State<NutritionAnalyticsReport>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _periods = ['Day', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _periods.length,
      vsync: this,
      initialIndex: 1,
    ); // Default to Week
    _tabController.addListener(_handleTabChange);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionProvider>().loadHistoryReport('week');
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final period = _periods[_tabController.index].toLowerCase();
      context.read<NutritionProvider>().loadHistoryReport(period);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 390;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Period Selector (Sleek Pill Shape)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * s),
            child: Container(
              height: 46 * s,
              padding: EdgeInsets.all(4 * s),
              decoration: BoxDecoration(
                color: NColors.bgSecondary(context),
                borderRadius: BorderRadius.circular(24 * s),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20 * s),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: NColors.textSecondary(context),
                labelStyle: GoogleFonts.inter(
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w600,
                ),
                tabs: _periods.map((p) => Tab(text: p)).toList(),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
          ),

          SizedBox(height: 28 * s),

          // 2. Summary Stats Row
          Consumer<NutritionProvider>(
            builder: (context, provider, _) {
              if (provider.isHistoryLoading) {
                return const SizedBox.shrink();
              }
              return _SummaryStatsRow(
                avg: provider.averageCaloriesInHistory.toInt(),
                adherence: provider.goalAdherenceRate.toInt(),
                period: _periods[_tabController.index],
                s: s,
              );
            },
          ),

          SizedBox(height: 20 * s),

          // 3. Chart Container
          Expanded(
            child: Consumer<NutritionProvider>(
              builder: (context, provider, _) {
                if (provider.isHistoryLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: NColors.accentPrimary(context),
                      strokeWidth: 3,
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 24 * s, 10 * s),
                  child: _buildChart(provider, s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(NutritionProvider provider, double s) {
    final period = _periods[_tabController.index].toLowerCase();

    if (provider.calorieHistory.isEmpty && period != 'day') {
      return Center(
        child: Text(
          'No data for this period',
          style: GoogleFonts.inter(
            color: NColors.textSecondary(context),
            fontSize: 14 * s,
          ),
        ),
      );
    }

    switch (period) {
      case 'day':
        return _DayMealChart(provider: provider, s: s);
      case 'week':
        return _WeekCalorieChart(history: provider.calorieHistory, s: s);
      case 'month':
        return _MonthTrendChart(history: provider.calorieHistory, s: s);
      case 'year':
        return _YearAggregateChart(history: provider.calorieHistory, s: s);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SummaryStatsRow extends StatelessWidget {
  final int avg;
  final int adherence;
  final String period;
  final double s;

  const _SummaryStatsRow({
    required this.avg,
    required this.adherence,
    required this.period,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * s),
      child: Center(
        child: _StatItem(
          label: 'AVERAGE',
          value: '$avg kcal',
          icon: Iconsax.chart_1,
          color: NColors.textPrimary(context),
          s: s,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double s;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12 * s, color: NColors.textSecondary(context)),
            SizedBox(width: 6 * s),
            Text(
              label,
              style: GoogleFonts.inter(
                color: NColors.textSecondary(context),
                fontSize: 10 * s,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * s),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: color,
            fontSize: 20 * s,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DayMealChart extends StatelessWidget {
  final NutritionProvider provider;
  final double s;
  const _DayMealChart({required this.provider, required this.s});

  @override
  Widget build(BuildContext context) {
    final nutrition = provider.dailyNutrition;
    final types = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    final cals = [
      nutrition.mealCalories(MealType.breakfast),
      nutrition.mealCalories(MealType.lunch),
      nutrition.mealCalories(MealType.dinner),
      nutrition.mealCalories(MealType.snacks),
    ];
    final maxCal = cals.reduce(math.max);
    final maxY = math.max(maxCal * 1.2, 500.0);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => NColors.bgElevated(context),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${types[group.x.toInt()]}\n${rod.toY.toInt()} kcal',
                GoogleFonts.inter(
                  color: NColors.textPrimary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    types[value.toInt()].substring(0, 3),
                    style: GoogleFonts.inter(
                      color: NColors.textSecondary(context),
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32 * s,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: GoogleFonts.inter(
                    color: NColors.textSecondary(context),
                    fontSize: 10 * s,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: NColors.divider(context), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(4, (i) {
          final colors = [
            const Color(0xFF3B82F6), // Blue
            const Color(0xFFF59E0B), // Amber
            const Color(0xFF10B981), // Emerald
            const Color(0xFF8B5CF6), // Violet
          ];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cals[i],
                color: colors[i],
                width: 32 * s,
                borderRadius: BorderRadius.circular(8 * s),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: NColors.bgSecondary(context),
                ),
              ),
            ],
          );
        }),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

class _WeekCalorieChart extends StatelessWidget {
  final List<CalorieHistoryItem> history;
  final double s;
  const _WeekCalorieChart({required this.history, required this.s});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final maxCal = history.map((e) => e.caloriesEaten).reduce(math.max);
    final maxGoal = history
        .map((e) => e.calorieGoal.toDouble())
        .reduce(math.max);
    final maxY = math.max(math.max(maxCal, maxGoal) * 1.2, 1000.0);

    return BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => NColors.bgElevated(context),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = history[group.x.toInt()];
                  final date = DateFormat('MMM d').format(item.date);
                  return BarTooltipItem(
                    '$date\n${rod.toY.toInt()} kcal',
                    GoogleFonts.inter(
                      color: NColors.textPrimary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= history.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(history[i].date),
                        style: GoogleFonts.inter(
                          color: NColors.textSecondary(context),
                          fontSize: 10 * s,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32 * s,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      '${value.toInt()}',
                      style: GoogleFonts.inter(
                        color: NColors.textSecondary(context),
                        fontSize: 10 * s,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: NColors.divider(context), strokeWidth: 1),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: history.last.calorieGoal.toDouble(),
                  color: NColors.textTertiary(context).withValues(alpha: 0.3),
                  strokeWidth: 1.5,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: GoogleFonts.inter(
                      color: NColors.textTertiary(context),
                      fontSize: 9 * s,
                      fontWeight: FontWeight.w700,
                    ),
                    labelResolver: (_) => 'GOAL',
                  ),
                ),
              ],
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(history.length, (i) {
              final item = history[i];
              final isGoalMet = item.isGoalMet;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: item.caloriesEaten,
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isGoalMet
                          ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                          : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                    ),
                    width: 14 * s,
                    borderRadius: BorderRadius.circular(4 * s),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: NColors.bgSecondary(context),
                    ),
                  ),
                ],
              );
            }),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scaleY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack);
  }
}

class _MonthTrendChart extends StatelessWidget {
  final List<CalorieHistoryItem> history;
  final double s;
  const _MonthTrendChart({required this.history, required this.s});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      history.length,
      (i) => FlSpot(i.toDouble(), history[i].caloriesEaten),
    );
    final maxCal = history.map((e) => e.caloriesEaten).reduce(math.max);
    final maxGoal = history
        .map((e) => e.calorieGoal.toDouble())
        .reduce(math.max);
    final maxY = math.max(math.max(maxCal, maxGoal) * 1.2, 1000.0);

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => NColors.bgElevated(context),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final item = history[s.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(item.date)}\n${s.y.toInt()} kcal',
                  GoogleFonts.inter(
                    color: NColors.textPrimary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= history.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('Md').format(history[i].date),
                    style: GoogleFonts.inter(
                      color: NColors.textSecondary(context),
                      fontSize: 9 * s,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32 * s,
              getTitlesWidget: (value, meta) {
                if (value % 500 != 0 || value == 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}',
                  style: GoogleFonts.inter(
                    color: NColors.textSecondary(context),
                    fontSize: 10 * s,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: NColors.divider(context), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: history.last.calorieGoal.toDouble(),
              color: NColors.textTertiary(context).withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  const Color(0xFF3B82F6).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _YearAggregateChart extends StatelessWidget {
  final List<CalorieHistoryItem> history;
  final double s;
  const _YearAggregateChart({required this.history, required this.s});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Group by month
    final monthlyData = <int, List<double>>{};
    for (final item in history) {
      final month = item.date.month;
      monthlyData[month] = (monthlyData[month] ?? [])..add(item.caloriesEaten);
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    final avgMonthly = sortedMonths.map((m) {
      final list = monthlyData[m]!;
      return list.reduce((a, b) => a + b) / list.length;
    }).toList();

    final maxAvg = avgMonthly.isNotEmpty ? avgMonthly.reduce(math.max) : 2000.0;
    final maxY = math.max(maxAvg * 1.25, 2000.0);

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= sortedMonths.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM').format(DateTime(2024, sortedMonths[i])),
                    style: GoogleFonts.inter(
                      color: NColors.textSecondary(context),
                      fontSize: 9 * s,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32 * s,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: GoogleFonts.inter(
                    color: NColors.textSecondary(context),
                    fontSize: 10 * s,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(avgMonthly.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: avgMonthly[i],
                color: NColors.accentPrimary(context),
                width: 16 * s,
                borderRadius: BorderRadius.circular(4 * s),
              ),
            ],
          );
        }),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
