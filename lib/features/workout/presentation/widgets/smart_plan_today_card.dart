// lib/features/workout/presentation/widgets/smart_plan_today_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:befit/core/utils/responsive.dart';
import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/features/home/presentation/widgets/home_theme.dart';
import 'package:befit/features/workout/core/exercise_media.dart';
import '../../../smart_plan/data/models/smart_workout_plan.dart';
import '../../data/repositories/exercise_repository.dart';
import '../providers/workout_hub_provider.dart';
import '../screens/smart_day_detail_screen.dart';
import '../widgets/exercise_gif_image.dart';

class SmartPlanTodayCard extends StatefulWidget {
  final SmartWorkoutDay day;
  final List<SmartWorkoutDay> allDays;
  final String planName;

  const SmartPlanTodayCard({
    super.key,
    required this.day,
    required this.allDays,
    this.planName = 'My Smart Plan',
  });

  @override
  State<SmartPlanTodayCard> createState() => _SmartPlanTodayCardState();
}

class _SmartPlanTodayCardState extends State<SmartPlanTodayCard> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _loadVisuals();
  }

  @override
  void didUpdateWidget(SmartPlanTodayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day.name != widget.day.name) {
      _loadVisuals();
    }
  }

  Future<void> _loadVisuals() async {
    final repo = ExerciseRepository();
    final exerciseName = widget.day.exercises.isNotEmpty
        ? widget.day.exercises.first.name
        : widget.day.name;

    final item = await repo.getExerciseByName(exerciseName) ??
        await repo.findExerciseByFuzzyName(exerciseName);

    if (mounted) {
      setState(() {
        _resolvedUrl = normalizeExerciseMediaUrl(item?.gifUrl);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final isRest = day.isRestDay;
    final duration = isRest ? 0 : (day.exercises.length * 7).clamp(20, 90);
    final calories = duration * 7;

    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);
    
    final theme = Theme.of(context);
    final customColors = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    final trainedToday = context.watch<WorkoutHubProvider>().stats.trainedToday;

    // Resolve state colors & metadata
    Color accentColor;
    String badgeText;
    String titleText;
    String subtitleText;
    IconData actionIcon;
    List<Color> shroudColors;

    final bool useCinematicDark = (!trainedToday && !isRest) || isDark;

    if (trainedToday) {
      accentColor = customColors.success;
      badgeText = 'COMPLETED';
      titleText = 'Workout Finished! 🎉';
      subtitleText = 'Excellent work! Recovery is now in progress.';
      actionIcon = Icons.check_rounded;
      shroudColors = isDark
          ? [
              const Color(0xFF064E3B).withValues(alpha: 0.95),
              const Color(0xFF022C22).withValues(alpha: 0.70),
              Colors.black.withValues(alpha: 0.15),
            ]
          : [
              const Color(0xFFD1FAE5).withValues(alpha: 0.98),
              const Color(0xFFA7F3D0).withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.20),
            ];
    } else if (isRest) {
      accentColor = const Color(0xFF3B82F6); // Blue
      badgeText = 'RECOVERY PHASE';
      titleText = 'Active Rest Day';
      subtitleText = 'Stretching, light walk & hydration advised.';
      actionIcon = Icons.info_outline_rounded;
      shroudColors = isDark
          ? [
              const Color(0xFF1E3A8A).withValues(alpha: 0.95),
              const Color(0xFF172554).withValues(alpha: 0.70),
              Colors.black.withValues(alpha: 0.15),
            ]
          : [
              const Color(0xFFDBEAFE).withValues(alpha: 0.98),
              const Color(0xFFBFDBFE).withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.20),
            ];
    } else {
      accentColor = HomeUi.accent(context); // Neon/Emerald
      badgeText = 'STRENGTH SESSION';
      titleText = day.name;
      subtitleText = '${day.exercises.length} Targeted Exercises';
      actionIcon = Icons.play_arrow_rounded;
      shroudColors = isDark
          ? [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.50),
              Colors.black.withValues(alpha: 0.15),
            ]
          : [
              Colors.black.withValues(alpha: 0.90),
              Colors.black.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.05),
            ];
    }

    final cardBaseColor = isDark
        ? const Color(0xFF0F0F10)
        : (useCinematicDark ? const Color(0xFF111318) : Colors.white);
    final textOnShroudColor = useCinematicDark ? Colors.white : Colors.black87;
    final textMutedColor = useCinematicDark ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      height: 250 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * s),
        color: cardBaseColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: useCinematicDark ? 0.15 : 0.04),
            blurRadius: 20 * s,
            offset: Offset(0, 8 * s),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28 * s),
        child: Stack(
          children: [
            // 1. Full-bleed background media / image
            Positioned.fill(
              child: _resolvedUrl != null
                  ? ExerciseGifImage(
                      imageUrl: _resolvedUrl,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/trainer.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
            ),

            // 2. High-contrast Gradient shroud overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: shroudColors,
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Main cinematic dashboard content
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToDetail(context, trainedToday, isRest, day),
                  splashColor: accentColor.withValues(alpha: 0.1),
                  child: Padding(
                    padding: EdgeInsets.all(22 * s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(20 * s),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.montserrat(
                                  fontSize: 8.5 * fs,
                                  fontWeight: FontWeight.w900,
                                  color: (trainedToday && !isDark) ? Colors.white : Colors.black,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (!isRest && !trainedToday)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: useCinematicDark ? 0.12 : 0.8),
                                  borderRadius: BorderRadius.circular(20 * s),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: useCinematicDark ? 0.08 : 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_box_outlined,
                                      size: 11 * s,
                                      color: useCinematicDark ? Colors.white70 : Colors.black87,
                                    ),
                                    SizedBox(width: 4 * s),
                                    Text(
                                      '${day.exercises.length} Exercises',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9.5 * fs,
                                        fontWeight: FontWeight.w800,
                                        color: useCinematicDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // Bottom Section: Details & Glow Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 22 * fs,
                                      fontWeight: FontWeight.w900,
                                      color: textOnShroudColor,
                                      height: 1.1,
                                      letterSpacing: -0.6,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6 * s),
                                  Text(
                                    subtitleText,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11 * fs,
                                      fontWeight: FontWeight.w600,
                                      color: textMutedColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (!isRest && !trainedToday) ...[
                                    SizedBox(height: 12 * s),
                                    Wrap(
                                      spacing: 8 * s,
                                      runSpacing: 6 * s,
                                      children: [
                                        _CapsuleBadge(
                                          label: '$duration min',
                                          icon: Icons.timer_outlined,
                                          color: textMutedColor,
                                          s: s,
                                          fs: fs,
                                        ),
                                        _CapsuleBadge(
                                          label: '$calories kcal',
                                          icon: Icons.local_fire_department_rounded,
                                          color: textMutedColor,
                                          s: s,
                                          fs: fs,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Glowing Circular Play/Action Button
                            GestureDetector(
                              onTap: () => _navigateToDetail(context, trainedToday, isRest, day),
                              child: Container(
                                width: 52 * s,
                                height: 52 * s,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  actionIcon,
                                  color: (trainedToday && !isDark) ? Colors.white : Colors.black,
                                  size: 28 * s,
                                ),
                              )
                                  .animate(
                                    onPlay: (c) => trainedToday
                                        ? c.stop()
                                        : c.repeat(reverse: true),
                                  )
                                  .shimmer(
                                    duration: 2.seconds,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1.0, 1.0));
  }

  void _navigateToDetail(BuildContext context, bool trainedToday, bool isRest, SmartWorkoutDay day) {
    if (trainedToday) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartDayDetailScreen(
          day: day,
          planName: widget.planName,
        ),
      ),
    );
  }
}

class _CapsuleBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double s;
  final double fs;

  const _CapsuleBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10 * s),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1.0 * s,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12 * s, color: color),
          SizedBox(width: 4 * s),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10 * fs,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
