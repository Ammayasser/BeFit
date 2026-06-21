// lib/features/nutrition/presentation/widgets/hourly_intake_chart.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/befit_theme_extension.dart';

class HourlyIntakeChart extends StatelessWidget {
  final List<int> hourly;

  const HourlyIntakeChart({
    super.key,
    required this.hourly,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.customColors.hydration;
    
    // Show hours from 6 AM (6) to 11 PM (23) - 18 bars
    const startHour = 6;
    const endHour = 23;
    final displayHours = List.generate(endHour - startHour + 1, (i) => startHour + i);
    
    final maxMl = hourly.fold<int>(1, (a, b) => math.max(a, b));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hourly Intake',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '6 AM - 12 AM',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: displayHours.map((hIdx) {
              final ml = hourly[hIdx];
              final ratio = (maxMl > 0 ? ml / maxMl : 0.0).clamp(0.0, 1.0);
              
              // Only show labels for specific intervals to avoid crowding
              final showLabel = hIdx % 4 == 0;
              final label = hIdx == 12 ? '12 PM' : (hIdx < 12 ? '$hIdx AM' : '${hIdx - 12} PM');

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final barH = (c.maxHeight * (0.05 + ratio * 0.95)).clamp(4.0, c.maxHeight);
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                width: double.infinity,
                                height: barH,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: ml > 0
                                      ? LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [accent, accent.withValues(alpha: 0.6)],
                                        )
                                      : null,
                                  color: ml > 0 ? null : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                                  boxShadow: ml > 0
                                      ? [
                                          BoxShadow(
                                            color: accent.withValues(alpha: isDark ? 0.2 : 0.05),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 12,
                        child: Text(
                          showLabel ? label : '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
