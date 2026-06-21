// lib/features/nutrition/presentation/widgets/water_weekly_view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/befit_theme_extension.dart';

import 'bottle_painter.dart';
import 'quick_add_row.dart';
import 'weekly_bars_chart.dart';
import 'ai_reminder_card.dart';

class WaterWeeklyView extends StatelessWidget {
  final double fill;
  final int logged;
  final int goal;
  final List<int> weekTotals;
  final int goalMl;
  final ValueChanged<int> onAddWater;
  final VoidCallback onCustomAmount;

  const WaterWeeklyView({
    super.key,
    required this.fill,
    required this.logged,
    required this.goal,
    required this.weekTotals,
    required this.goalMl,
    required this.onAddWater,
    required this.onCustomAmount,
  });

  String _litersOneDecimal(int ml) => (ml / 1000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('weekly'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeeklyBottleRow(fill: fill, logged: logged, goal: goal, litersFmt: _litersOneDecimal),
        const SizedBox(height: 18),
        QuickAddRow(onAddWater: onAddWater, onCustom: onCustomAmount),
        const SizedBox(height: 22),
        WeeklyBarsChart(
          totalsMl: weekTotals.length == 7 ? weekTotals : List<int>.filled(7, 0),
          goalMl: goalMl,
        ),
        const SizedBox(height: 18),
        AiReminderCard(
          message: _weeklyAiMessage(weekTotals, goalMl),
        ),
      ],
    );
  }

  String _weeklyAiMessage(List<int> totals, int goal) {
    final sum = totals.fold<int>(0, (a, b) => a + b);
    final target = goal * 7;
    if (sum >= target) {
      return 'Outstanding week — you hit your hydration rhythm across most days.';
    }
    final avg = sum / 7;
    final gap = (goal - avg).round();
    if (gap <= 0) {
      return 'Solid weekly average — keep using quick-add after meals.';
    }
    return 'About ${gap}ml/day under target on average — try one extra glass after breakfast.';
  }
}

class _WeeklyBottleRow extends StatelessWidget {
  final double fill;
  final int logged;
  final int goal;
  final String Function(int) litersFmt;

  const _WeeklyBottleRow({
    required this.fill,
    required this.logged,
    required this.goal,
    required this.litersFmt,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.customColors.hydration;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 180,
            child: CustomPaint(
              painter: BottlePainter(
                fill: fill,
                wavePhase: 0,
                accent: accent,
                isDark: isDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This week',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: litersFmt(logged),
                      style: GoogleFonts.orbitron(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '\ntoday · ${litersFmt(goal)} goal',
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
