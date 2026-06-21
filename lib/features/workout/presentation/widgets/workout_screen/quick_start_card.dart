// lib/features/workout/presentation/widgets/workout_screen/quick_start_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:befit/core/utils/responsive.dart';
import 'package:befit/features/home/presentation/widgets/home_theme.dart';

class QuickStartCard extends StatelessWidget {
  final VoidCallback onTap;

  const QuickStartCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = HomeUi.accent(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    accentColor.withValues(alpha: 0.08),
                  ]
                : [
                    theme.colorScheme.surface,
                    accentColor.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.22),
            width: 1.2 * s,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
              blurRadius: 15 * s,
              offset: Offset(0, 5 * s),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24 * s),
          child: Stack(
            children: [
              // 1. Subtle background glow in corner
              Positioned(
                right: -25 * s,
                top: -25 * s,
                child: Container(
                  width: 110 * s,
                  height: 110 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.12),
                        accentColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 2. Card Content layout
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 18 * s),
                child: Row(
                  children: [
                    // Glowing plus button
                    Container(
                      width: 50 * s,
                      height: 50 * s,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(16 * s),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 10 * s,
                            offset: Offset(0, 3 * s),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: isDark ? const Color(0xFF17191E) : Colors.white,
                        size: 30 * s,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(0.97, 0.97), end: const Offset(1.03, 1.03), duration: 1500.ms),
                    SizedBox(width: 18 * s),
                    
                    // Text Description
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Start',
                            style: GoogleFonts.montserrat(
                              fontSize: 18 * fs,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Launch a custom workout session',
                            style: GoogleFonts.montserrat(
                              fontSize: 12.5 * fs,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // Circular chevron action indicator
                    Container(
                      width: 30 * s,
                      height: 30 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                          width: 1.0 * s,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18 * s,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}
