// lib/features/nutrition/presentation/widgets/water_daily_view.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/befit_theme_extension.dart';

import 'bottle_painter.dart';
import 'quick_add_row.dart';
import 'hourly_intake_chart.dart';
import 'ai_reminder_card.dart';

class WaterDailyView extends StatelessWidget {
  final double fill;
  final int logged;
  final int goal;
  final List<int> hourly;
  final Animation<double> waveListenable;
  final ValueChanged<int> onAddWater;
  final bool isTodayView;
  final VoidCallback onCustomAmount;

  const WaterDailyView({
    super.key,
    required this.fill,
    required this.logged,
    required this.goal,
    required this.hourly,
    required this.waveListenable,
    required this.onAddWater,
    required this.isTodayView,
    required this.onCustomAmount,
  });

  String _litersOneDecimal(int ml) => (ml / 1000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('daily'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DailyBottleRow(
          fill: fill,
          logged: logged,
          goal: goal,
          litersFmt: _litersOneDecimal,
          waveListenable: waveListenable,
        ),
        const SizedBox(height: 18),
        QuickAddRow(onAddWater: onAddWater, onCustom: onCustomAmount),
        const SizedBox(height: 22),
        HourlyIntakeChart(hourly: hourly.length == 24 ? hourly : List<int>.filled(24, 0)),
        const SizedBox(height: 18),
        AiReminderCard(
          message: _dailyAiMessage(logged, goal, isTodayView),
        ),
      ],
    );
  }

  String _dailyAiMessage(int logged, int goal, bool today) {
    if (!today) {
      return 'Review this day anytime — consistent logging builds better insights.';
    }
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final expected = (goal * minutes / (24 * 60)).round();
    final behind = expected - logged;
    if (behind <= 150) {
      return 'You\'re on pace — small sips through the afternoon keep energy steady.';
    }
    final hint = now.hour < 14
        ? 'top up before lunch'
        : 'drink before your afternoon workout';
    return 'You\'re ${behind}ml behind schedule — $hint';
  }
}

class _DailyBottleRow extends StatelessWidget {
  final double fill;
  final int logged;
  final int goal;
  final String Function(int) litersFmt;
  final Animation<double> waveListenable;

  const _DailyBottleRow({
    required this.fill,
    required this.logged,
    required this.goal,
    required this.litersFmt,
    required this.waveListenable,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.customColors.hydration;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 200,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: waveListenable,
                builder: (context, _) {
                  return CustomPaint(
                    painter: BottlePainter(
                      fill: fill,
                      wavePhase: waveListenable.value * math.pi * 2,
                      accent: accent,
                      isDark: isDark,
                    ),
                  );
                },
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
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: litersFmt(logged),
                      style: GoogleFonts.orbitron(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${litersFmt(goal)} L',
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${((fill) * 100).round()}% of daily goal',
                style: GoogleFonts.inter(
                  color: accent.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
