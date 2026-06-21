// lib/features/workout/presentation/widgets/smart_plan_week_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';


import '../../../smart_plan/data/models/smart_workout_plan.dart';
import '../../../smart_plan/presentation/providers/smart_plan_provider.dart';
import '../../core/workout_colors.dart';
import '../../core/exercise_media.dart';
import '../../data/repositories/exercise_repository.dart';
import '../screens/smart_day_detail_screen.dart';

import 'smart_plan_today_card.dart';
import '../widgets/exercise_gif_image.dart';

class SmartPlanWeekView extends StatelessWidget {
  final String planName;

  const SmartPlanWeekView({super.key, this.planName = 'My Smart Plan'});

  @override
  Widget build(BuildContext context) {
    final smartPlan = context.watch<SmartPlanProvider>();
    final days = smartPlan.workoutDays;
    final s = MediaQuery.of(context).size.width / 390;

    if (days == null || days.isEmpty) return const SizedBox.shrink();

    // Determine today's day index (1=Mon…7=Sun)
    final todayWeekday = DateTime.now().weekday; // 1=Mon in Dart
    final todayDay = days.firstWhere(
      (d) => d.dayIndex == todayWeekday,
      orElse: () => days.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * s,
                            vertical: 3 * s,
                          ),
                          decoration: BoxDecoration(
                            color: WorkoutColors.lime(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8 * s),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.magic_star,
                                size: 10 * s,
                                color: WorkoutColors.lime(context),
                              ),
                              SizedBox(width: 5 * s),
                              Text(
                                'AI SMART PLAN',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9 * s,
                                  fontWeight: FontWeight.w900,
                                  color: WorkoutColors.lime(context),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6 * s),
                    Text(
                      "Today's Plan",
                      style: GoogleFonts.montserrat(
                        fontSize: 22 * s,
                        fontWeight: FontWeight.w900,
                        color: WorkoutColors.onSurface(context),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Weekly Schedule trigger button
              GestureDetector(
                onTap: () => _showWeeklySchedule(context, days),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * s,
                    vertical: 8 * s,
                  ),
                  decoration: BoxDecoration(
                    color: WorkoutColors.lime(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12 * s),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15 * s,
                        color: WorkoutColors.lime(context),
                      ),
                      SizedBox(width: 5 * s),
                      Text(
                        'Weekly Plan',
                        style: GoogleFonts.montserrat(
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w700,
                          color: WorkoutColors.lime(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        SizedBox(height: 16 * s),

        // ── Today's Workout Focus Card ──────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s),
          child: SmartPlanTodayCard(
            day: todayDay,
            allDays: days,
            planName: planName,
          ),
        ),
      ],
    );
  }

  void _showWeeklySchedule(BuildContext context, List<SmartWorkoutDay> days) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final onBackgroundColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final maxHeight = mediaQuery.size.height * 0.6;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border.all(
              color: onBackgroundColor.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: onBackgroundColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '7-Day Workout Schedule',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: onBackgroundColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return _SmartWeeklyDayRow(day: day, planName: planName);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _SmartWeeklyDayRow extends StatefulWidget {
  final SmartWorkoutDay day;
  final String planName;

  const _SmartWeeklyDayRow({required this.day, required this.planName});

  @override
  State<_SmartWeeklyDayRow> createState() => _SmartWeeklyDayRowState();
}

class _SmartWeeklyDayRowState extends State<_SmartWeeklyDayRow> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _loadVisuals();
  }

  Future<void> _loadVisuals() async {
    if (widget.day.isRestDay || widget.day.exercises.isEmpty) return;

    final repo = ExerciseRepository();
    String? foundUrl;
    String? bestExerciseName;

    // 1. Try to find a real GIF for ANY exercise in this day's routine
    for (final ex in widget.day.exercises) {
      final item =
          await repo.getExerciseByName(ex.name) ??
          await repo.findExerciseByFuzzyName(ex.name);

      if (item?.gifUrl != null && item!.gifUrl!.isNotEmpty) {
        foundUrl = normalizeExerciseMediaUrl(item.gifUrl);
        bestExerciseName = ex.name;
        break; // Found a real API visual, stop searching
      }
    }

    // 2. If NO GIF found in API, use the high-accuracy stock fallback based on the first exercise
    if (foundUrl == null) {
      bestExerciseName = widget.day.exercises.first.name;
      foundUrl = stockWorkoutCoverUrl(
        name: bestExerciseName,
        muscleGroup: widget.day.primaryMuscles.isNotEmpty
            ? widget.day.primaryMuscles.first
            : null,
      );
    }

    if (mounted) {
      setState(() {
        _resolvedUrl = foundUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final isToday = day.dayIndex == DateTime.now().weekday;
    final isRest = day.isRestDay;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = WorkoutColors.onSurface(context);
    final onSurfaceMuted = WorkoutColors.onSurfaceMuted(context);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SmartDayDetailScreen(day: day, planName: widget.planName),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday
              ? WorkoutColors.lime(context).withValues(alpha: 0.12)
              : onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isToday
                ? WorkoutColors.lime(context).withValues(alpha: 0.4)
                : onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRest
                    ? Colors.blueGrey.withValues(alpha: 0.1)
                    : onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isRest
                  ? const Icon(
                      Icons.hotel_rounded,
                      color: Colors.blueGrey,
                      size: 20,
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/trainer.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (_resolvedUrl != null)
                          Positioned.fill(
                            child: ExerciseGifImage(
                              imageUrl: _resolvedUrl,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        day.dayAbbr.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isToday
                              ? WorkoutColors.lime(context)
                              : onSurfaceMuted,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: WorkoutColors.lime(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TODAY',
                            style: GoogleFonts.montserrat(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRest ? 'Rest & Recovery' : day.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRest) ...[
              Text(
                '${day.exercises.length} ex.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onSurfaceMuted,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: onSurfaceMuted.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

