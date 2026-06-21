// lib/features/progress/presentation/widgets/weight_chart.dart

import 'package:befit/features/progress/data/models/weight_log.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';

class WeightChart extends StatelessWidget {
  final List<WeightLog> logs; // sorted ASC (oldest first)
  final double? goalWeight; // in preferred unit
  final String unit;

  const WeightChart({
    super.key,
    required this.logs,
    this.goalWeight,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstDate = logs.first.loggedAt;

    // Convert logs to spots
    final List<FlSpot> spots = [];
    final Map<double, String> xToDateMap = {};

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      // X is days since the first log to space data points relative to time
      final double x = log.loggedAt.difference(firstDate).inDays.toDouble();

      // If we already have a log on this day, offset it slightly to avoid duplicate X values in fl_chart
      double uniqueX = x;
      while (xToDateMap.containsKey(uniqueX)) {
        uniqueX += 0.01;
      }

      spots.add(
        FlSpot(uniqueX, log.weightKg),
      ); // Note: provider translates unit or we translate here. Let's pass weight values already in preferred unit.
      xToDateMap[uniqueX] = DateFormat('MMM d').format(log.loggedAt);
    }

    final weights = spots.map((s) => s.y).toList();
    double minWeight = weights.reduce((a, b) => a < b ? a : b);
    double maxWeight = weights.reduce((a, b) => a > b ? a : b);

    if (goalWeight != null) {
      if (goalWeight! < minWeight) minWeight = goalWeight!;
      if (goalWeight! > maxWeight) maxWeight = goalWeight!;
    }

    // Give some padding on the Y axis
    final yPadding = ((maxWeight - minWeight) * 0.15).clamp(2.0, 10.0);
    final minY = (minWeight - yPadding).clamp(0.0, double.infinity);
    final maxY = maxWeight + yPadding;

    // Give padding on X axis as well
    final double minX = spots.first.x;
    final double maxX = spots.last.x == minX ? minX + 1 : spots.last.x;
    final xRange = maxX - minX;

    // Calculate grid intervals
    final yInterval = ((maxY - minY) / 4).clamp(1.0, double.infinity);
    // xInterval would be (xRange / 4).clamp(1.0, double.infinity) — not used currently

    final isTablet = Responsive.isTablet(context);
    final isLandscape = Responsive.isLandscape(context);
    final double aspectRatio;
    if (isTablet) {
      aspectRatio = isLandscape ? 3.0 : 2.3;
    } else {
      aspectRatio = isLandscape ? 2.2 : 1.6;
    }

    final double labelFontSize = Responsive.fontScale(context, 9);
    final double goalLabelFontSize = Responsive.fontScale(context, 10);
    final double tooltipTitleFontSize = Responsive.fontScale(context, 10);
    final double tooltipValueFontSize = Responsive.fontScale(context, 14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, left: 4, top: 10),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: minX - (xRange * 0.05),
                maxX: maxX + (xRange * 0.05),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: custom.chartGridLine.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [5, 5],
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
                      reservedSize: 42,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${value.toStringAsFixed(0)} $unit',
                          style: GoogleFonts.montserrat(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w600,
                            color: custom.chartLabel,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (goalWeight != null)
                      HorizontalLine(
                        y: goalWeight!,
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 8, bottom: 2),
                          style: GoogleFonts.montserrat(
                            fontSize: goalLabelFontSize,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                          labelResolver: (line) =>
                              'Goal: ${goalWeight!.toStringAsFixed(1)} $unit',
                        ),
                      ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.35,
                              ),
                              strokeWidth: 2,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 6,
                                    color: theme.colorScheme.primary,
                                    strokeWidth: 3,
                                    strokeColor: isDark
                                        ? custom.bgPrimary
                                        : Colors.white,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? custom.surfaceElevated : Colors.white,
                    tooltipBorderRadius: BorderRadius.circular(16),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final dateStr = xToDateMap[touchedSpot.x] ?? '';
                        return LineTooltipItem(
                          '$dateStr\n',
                          GoogleFonts.montserrat(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: tooltipTitleFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: '${touchedSpot.y.toStringAsFixed(1)} $unit',
                              style: GoogleFonts.montserrat(
                                color: theme.colorScheme.onSurface,
                                fontSize: tooltipValueFontSize,
                                fontWeight: FontWeight.w800,
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
                    barWidth: 4.5,
                    isStrokeCapRound: true,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    dotData: FlDotData(
                      show: spots.length < 15,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: isDark ? custom.bgPrimary : Colors.white,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.primary,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                          theme.colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 46, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (logs.length == 1)
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMM d').format(logs.first.loggedAt),
                      style: GoogleFonts.montserrat(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: custom.chartLabel,
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  DateFormat('MMM d').format(logs.first.loggedAt),
                  style: GoogleFonts.montserrat(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: custom.chartLabel,
                  ),
                ),
                if (logs.length > 2)
                  Text(
                    DateFormat('MMM d').format(logs[logs.length ~/ 2].loggedAt),
                    style: GoogleFonts.montserrat(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: custom.chartLabel,
                    ),
                  ),
                Text(
                  DateFormat('MMM d').format(logs.last.loggedAt),
                  style: GoogleFonts.montserrat(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: custom.chartLabel,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
