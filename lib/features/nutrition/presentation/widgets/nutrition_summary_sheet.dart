// lib/features/nutrition/presentation/widgets/nutrition_summary_sheet.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/daily_nutrition.dart';
import '../providers/nutrition_provider.dart';
import 'nutrition_colors.dart';
import 'nutrition_analytics_report.dart';

class NutritionSummarySheet extends StatelessWidget {
  const NutritionSummarySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NutritionProvider>(),
        child: const NutritionSummarySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: NColors.bgElevated(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(NColors.radiusModal),
            ),
          ),
          child: Consumer<NutritionProvider>(
            builder: (context, provider, _) {
              final nutrition = provider.dailyNutrition;
              final dateStr =
                  DateFormat('EEEE, MMM d').format(nutrition.date);

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: NColors.textTertiary(context).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Performance Insights',
                                style: GoogleFonts.montserrat(
                                  color: NColors.textPrimary(context),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: GoogleFonts.inter(
                                  color: NColors.textSecondary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: NColors.bgPrimary(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Iconsax.chart_21, color: NColors.textPrimary(context), size: 20),
                        ),
                        ],
                        ),
                        ),

                        const SizedBox(height: 12),
                        Divider(indent: 24, endIndent: 24, color: NColors.divider(context)),

                  // 1. Advanced Calorie Tracking (Day, Week, Month, Year)
                  const SizedBox(
                    height: 420,
                    child: NutritionAnalyticsReport(),
                  ),

                  const SizedBox(height: 16),

                  // 2. Macro Distribution Breakdown
                  _SectionTitle(title: 'Macro Distribution'),
                  const SizedBox(height: 16),
                  _MacroPieChart(nutrition: nutrition),
                  const SizedBox(height: 24),

                  // 3. Macronutrients Details
                  _SectionTitle(title: 'Nutrient Details'),
                  const SizedBox(height: 12),
                  _NutrientRow(
                    icon: Iconsax.weight_1,
                    name: 'Protein',
                    eaten: nutrition.totalProtein,
                    goal: nutrition.proteinGoalG,
                    color: NColors.accentSecondary(context),
                    unit: 'g',
                  ),
                  _NutrientRow(
                    icon: Iconsax.category,
                    name: 'Carbohydrates',
                    eaten: nutrition.totalCarbs,
                    goal: nutrition.carbsGoalG,
                    color: NColors.warningAccent(context),
                    unit: 'g',
                  ),
                  _NutrientRow(
                    icon: Iconsax.drop,
                    name: 'Fat',
                    eaten: nutrition.totalFat,
                    goal: nutrition.fatGoalG,
                    color: NColors.dangerAccent(context),
                    unit: 'g',
                  ),
                  _NutrientRow(
                    icon: Iconsax.tree,
                    name: 'Fiber',
                    eaten: _sumNutrient(nutrition, (f) => f.fiberPer100g),
                    goal: 25,
                    color: NColors.accentPrimary(context),
                    unit: 'g',
                  ),
                  _NutrientRow(
                    icon: Iconsax.cake,
                    name: 'Sugar',
                    eaten: _sumNutrient(nutrition, (f) => f.sugarPer100g),
                    goal: 50,
                    color: NColors.purple,
                    unit: 'g',
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _sumNutrient(
      DailyNutrition nutrition, double? Function(dynamic) getter) {
    double total = 0;
    for (final log in nutrition.logs) {
      final per100 = getter(log.foodItem);
      if (per100 != null) {
        total += (per100 * log.quantityGrams) / 100;
      }
    }
    return total;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          color: NColors.textPrimary(context),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final double eaten;
  final double goal;
  final Color color;
  final String unit;

  const _NutrientRow({
    required this.icon,
    required this.name,
    required this.eaten,
    required this.goal,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (eaten / goal).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: GoogleFonts.inter(
                color: NColors.textPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${eaten.toStringAsFixed(1)}$unit / ${goal.toInt()}$unit',
              style: GoogleFonts.inter(
                color: NColors.textSecondary(context),
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: NColors.divider(context),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPieChart extends StatelessWidget {
  final DailyNutrition nutrition;
  const _MacroPieChart({required this.nutrition});

  BorderSide _sliceBorder(BuildContext context) => BorderSide(
        color: NColors.bgSecondary(context),
        width: 1.2,
      );

  LinearGradient _macroGradient(BuildContext context, Color base) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(base, isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white, 0.22)!,
        base,
        Color.lerp(base, isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF0F172A), 0.08)!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total =
        nutrition.totalProtein + nutrition.totalCarbs + nutrition.totalFat;
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: NColors.bgSecondary(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: NColors.divider(context),
            ),
          ),
          child: Center(
            child: Text(
              'No macro data yet',
              style: GoogleFonts.inter(
                color: NColors.textTertiary(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    final proteinPct = nutrition.totalProtein / total * 100;
    final carbsPct = nutrition.totalCarbs / total * 100;
    final fatPct = nutrition.totalFat / total * 100;
    const outerRadius = 52.0;
    const innerRadius = 34.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        decoration: BoxDecoration(
          color: NColors.bgSecondary(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: NColors.divider(context),
          ),
          boxShadow: NColors.cardGlow(context),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 152,
              height: 152,
              child: RepaintBoundary(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 1.2,
                        centerSpaceRadius: innerRadius,
                        sections: [
                          PieChartSectionData(
                            value: math.max(nutrition.totalProtein, 0.01),
                            radius: outerRadius,
                            showTitle: false,
                            borderSide: _sliceBorder(context),
                            gradient: _macroGradient(context, NColors.accentSecondary(context)),
                          ),
                          PieChartSectionData(
                            value: math.max(nutrition.totalCarbs, 0.01),
                            radius: outerRadius,
                            showTitle: false,
                            borderSide: _sliceBorder(context),
                            gradient: _macroGradient(context, NColors.warningAccent(context)),
                          ),
                          PieChartSectionData(
                            value: math.max(nutrition.totalFat, 0.01),
                            radius: outerRadius,
                            showTitle: false,
                            borderSide: _sliceBorder(context),
                            gradient: _macroGradient(context, NColors.dangerAccent(context)),
                          ),
                        ],
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toStringAsFixed(0),
                          style: GoogleFonts.montserrat(
                            color: NColors.textPrimary(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'grams',
                          style: GoogleFonts.inter(
                            color: NColors.textTertiary(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'P · C · F',
                          style: GoogleFonts.inter(
                            color: NColors.textSecondary(context),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribution',
                    style: GoogleFonts.inter(
                      color: NColors.textSecondary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LegendItem(
                    color: NColors.accentSecondary(context),
                    label: 'Protein',
                    pct: proteinPct,
                    grams: nutrition.totalProtein,
                  ),
                  const SizedBox(height: 10),
                  _LegendItem(
                    color: NColors.warningAccent(context),
                    label: 'Carbs',
                    pct: carbsPct,
                    grams: nutrition.totalCarbs,
                  ),
                  const SizedBox(height: 10),
                  _LegendItem(
                    color: NColors.dangerAccent(context),
                    label: 'Fat',
                    pct: fatPct,
                    grams: nutrition.totalFat,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  final double grams;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.pct,
    this.grams = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, 0.25)!,
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: NColors.textPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (grams > 0)
          Text(
            '${grams.toStringAsFixed(0)}g · ',
            style: GoogleFonts.inter(
              color: NColors.textTertiary(context),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: GoogleFonts.montserrat(
            color: NColors.textPrimary(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

}

