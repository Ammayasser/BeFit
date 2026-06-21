// lib/features/nutrition/presentation/widgets/weekly_bars_chart.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/befit_theme_extension.dart';

class WeeklyBarsChart extends StatelessWidget {
  final List<int> totalsMl;
  final int goalMl;

  const WeeklyBarsChart({
    super.key,
    required this.totalsMl,
    required this.goalMl,
  });

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final cap = math.max(goalMl, totalsMl.fold<int>(1, (a, b) => math.max(a, b)));
    final accent = context.customColors.hydration;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily totals',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final ml = totalsMl[i];
              final t = (ml / cap).clamp(0.0, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final barH = (c.maxHeight * (0.1 + t * 0.9)).clamp(5.0, c.maxHeight);
                            final hit = ml >= goalMl;
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                width: double.infinity,
                                height: barH,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: ml > 0
                                      ? LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: hit
                                              ? [const Color(0xFF34D399), const Color(0xFF059669)]
                                              : [accent, accent.withValues(alpha: 0.7)],
                                        )
                                      : null,
                                  color: ml > 0 ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _days[i],
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
