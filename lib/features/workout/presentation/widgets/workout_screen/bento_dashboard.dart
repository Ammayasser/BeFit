// lib/features/workout/presentation/widgets/workout_screen/bento_dashboard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:befit/core/constants/app_colors.dart';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import '../../../data/models/workout_hub_stats.dart';
import 'workout_hub_shared.dart';

class BentoDashboard extends StatelessWidget {
  final WorkoutHubStats stats;

  const BentoDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _StatusCard(
              title: stats.trainedToday ? 'Trained' : 'Active',
              subtitle: stats.trainedToday ? 'Great job today!' : 'Time to move?',
              value: '${stats.caloriesToday}',
              unit: 'KCAL',
              icon: stats.trainedToday ? Icons.check_circle_rounded : Iconsax.status_up,
              color: stats.trainedToday ? WorkoutHubTokens.emerald : AppColors.primary,
              progress: (stats.caloriesToday / 500).clamp(0.0, 1.0),
              s: s,
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _SmallStatCard(
                  title: 'Streak',
                  value: '${stats.currentStreak}',
                  unit: 'days',
                  icon: Iconsax.flash_1,
                  color: WorkoutHubTokens.amber,
                  s: s,
                ),
                SizedBox(height: 12 * s),
                _SmallStatCard(
                  title: 'Goal',
                  value: '${stats.weeklyCompleted}',
                  unit: '/${stats.weeklyGoal}',
                  icon: Iconsax.flag,
                  color: WorkoutHubTokens.violet,
                  s: s,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title, subtitle, value, unit;
  final IconData icon;
  final Color color;
  final double progress;
  final double s;

  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.progress,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      height: 168 * s,
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rLG * s),
        border: Border.all(color: isDark ? colors.border : const Color(0xFFF1F5F9)),
        boxShadow: WorkoutHubTokens.lift(color: isDark ? Colors.black : Colors.black26, s: s, cBlur: 4, fBlur: 16, cDy: 1, fDy: 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7 * s),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18 * s),
              ),
              SizedBox(width: 10 * s),
              Text(
                title,
                style: GoogleFonts.montserrat(fontSize: 13 * s, fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.2),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.montserrat(fontSize: 34 * s, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -1.0, height: 1.0),
              ),
              SizedBox(width: 5 * s),
              Text(
                unit,
                style: GoogleFonts.montserrat(fontSize: 11 * s, fontWeight: FontWeight.w700, color: onSurfaceVar, letterSpacing: 0.5),
              ),
            ],
          ),
          SizedBox(height: 3 * s),
          Text(subtitle, style: GoogleFonts.montserrat(fontSize: 11 * s, fontWeight: FontWeight.w600, color: onSurfaceVar)),
          SizedBox(height: 12 * s),
          WorkoutHubMicroProgressBar(progress: progress, color: color, s: s),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String title, value, unit;
  final IconData icon;
  final Color color;
  final double s;

  const _SmallStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      height: 78 * s,
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rLG * s),
        border: Border.all(color: isDark ? colors.border : const Color(0xFFF1F5F9)),
        boxShadow: WorkoutHubTokens.lift(color: isDark ? Colors.black : Colors.black12, s: s, cBlur: 2, fBlur: 10, cDy: 1, fDy: 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WorkoutHubTokens.rLG * s),
        child: Row(
          children: [
            Container(
              width: 3 * s,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.25)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 12 * s),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6 * s),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 16 * s),
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                value,
                                style: GoogleFonts.montserrat(fontSize: 17 * s, fontWeight: FontWeight.w900, color: onSurface, height: 1.1, letterSpacing: -0.3),
                              ),
                              Text(unit, style: GoogleFonts.montserrat(fontSize: 10 * s, fontWeight: FontWeight.w600, color: onSurfaceVar)),
                            ],
                          ),
                          Text(title, style: GoogleFonts.montserrat(fontSize: 10 * s, fontWeight: FontWeight.w700, color: onSurfaceVar, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
