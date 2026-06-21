// lib/features/workout/presentation/screens/smart_day_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../../smart_plan/data/models/smart_workout_plan.dart';
import '../providers/workout_session_provider.dart';
import '../../core/workout_colors.dart';
import '../../core/exercise_media.dart';
import '../../data/repositories/exercise_repository.dart';
import '../widgets/exercise_gif_image.dart';
import '../widgets/workout_cover_image.dart';
import '../widgets/exercise_detail_sheet.dart';

class SmartDayDetailScreen extends StatefulWidget {
  final SmartWorkoutDay day;
  final String planName;

  const SmartDayDetailScreen({
    super.key,
    required this.day,
    required this.planName,
  });

  @override
  State<SmartDayDetailScreen> createState() => _SmartDayDetailScreenState();
}

class _SmartDayDetailScreenState extends State<SmartDayDetailScreen> {
  bool _isStarting = false;

  Future<void> _startWorkout() async {
    if (widget.day.isRestDay || widget.day.exercises.isEmpty) return;
    HapticFeedback.mediumImpact();

    setState(() => _isStarting = true);

    final sessionProvider = context.read<WorkoutSessionProvider>();
    final auth = context.read<AuthProvider>();

    try {
      await sessionProvider.startSessionFromSmartPlan(
        widget.day.name,
        auth.userId ?? '',
        widget.day.exercises,
      );
      if (mounted) context.push(AppRoutes.workoutSession);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not start workout: $e')));
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final isRest = day.isRestDay;
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280 * s,
            pinned: true,
            stretch: true,
            backgroundColor: WorkoutColors.scaffold(context),
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.only(left: 8 * s),
              child: Center(
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8 * s),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 16 * s,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Hero Image
                  if (!isRest && day.exercises.isNotEmpty)
                    WorkoutCoverImage(
                      imageUrl: day.exercises.first.name,
                      muscleGroup: day.exercises.first.muscleGroup,
                      gender: userProvider.gender,
                      overlayOpacity: 0.0, // We use our own stack gradient
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WorkoutColors.primary(context).withValues(alpha: 0.2),
                            WorkoutColors.scaffold(context),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                  // 2. High-Level Professional Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.3),
                          WorkoutColors.scaffold(context),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // 3. Content Overlays
                  Padding(
                    padding: EdgeInsets.fromLTRB(24 * s, 0, 24 * s, 20 * s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * s,
                            vertical: 6 * s,
                          ),
                          decoration: BoxDecoration(
                            color: isRest
                                ? Colors.blueGrey.withValues(alpha: 0.2)
                                : WorkoutColors.lime(context).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10 * s),
                            border: Border.all(
                              color: isRest
                                  ? Colors.blueGrey.withValues(alpha: 0.3)
                                  : WorkoutColors.lime(context).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRest ? Icons.hotel_rounded : Iconsax.magic_star,
                                size: 14 * s,
                                color: isRest
                                    ? Colors.blueGrey
                                    : WorkoutColors.lime(context),
                              ),
                              SizedBox(width: 8 * s),
                              Text(
                                isRest ? 'REST DAY' : 'AI SMART PLAN',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10 * fs,
                                  fontWeight: FontWeight.w900,
                                  color: isRest
                                      ? Colors.blueGrey
                                      : WorkoutColors.lime(context),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        Text(
                          day.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 34 * fs,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 12 * s),
                        if (!isRest && day.exercises.isNotEmpty)
                          Row(
                            children: [
                              _HeaderMeta(
                                icon: Iconsax.weight,
                                label: '${day.exercises.length} Exercises',
                                s: s,
                                fs: fs,
                                isDark: true,
                              ),
                              SizedBox(width: 16 * s),
                              if (day.primaryMuscles.isNotEmpty)
                                Expanded(
                                  child: _HeaderMeta(
                                    icon: Icons.architecture_rounded,
                                    label: day.primaryMuscles.join(' · '),
                                    s: s,
                                    fs: fs,
                                    isDark: true,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Rest Day Content ─────────────────────────────────────────────
          if (isRest)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _RestDayContent(s: s, fs: fs),
            )
          else ...[
            // ── Exercise Cards ───────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 120 * s),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ex = day.exercises[index];
                  return _SmartExerciseCard(
                    exercise: ex,
                    index: index,
                    s: s,
                    fs: fs,
                  );
                }, childCount: day.exercises.length),
              ),
            ),
          ],
        ],
      ),

      // ── Bottom CTA ───────────────────────────────────────────────────────
      bottomNavigationBar: isRest
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 32 * s),
              decoration: BoxDecoration(
                color: WorkoutColors.card(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20 * s,
                    offset: Offset(0, -8 * s),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isStarting ? null : _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WorkoutColors.lime(context),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 18 * s),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20 * s),
                  ),
                  elevation: 0,
                ),
                child: _isStarting
                    ? SizedBox(
                        height: 22 * s,
                        width: 22 * s,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'START WORKOUT',
                        style: GoogleFonts.montserrat(
                          fontSize: 16 * fs,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
    );
  }
}

// ── Rest Day Content ─────────────────────────────────────────────────────────

class _RestDayContent extends StatelessWidget {
  final double s;
  final double fs;

  const _RestDayContent({required this.s, required this.fs});

  @override
  Widget build(BuildContext context) {
    final tips = [
      ('Sleep 7–9 hours', Icons.bedtime_rounded, const Color(0xFF6366F1)),
      ('Stay hydrated', Icons.local_drink_rounded, const Color(0xFF0EA5E9)),
      (
        'Light stretching',
        Icons.self_improvement_rounded,
        const Color(0xFF10B981),
      ),
      (
        'Eat nutritious meals',
        Icons.restaurant_rounded,
        const Color(0xFFF59E0B),
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(24 * s),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(28 * s),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueGrey.withValues(alpha: 0.08),
              border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.nightlight_round,
              size: 52 * s,
              color: Colors.blueGrey,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          SizedBox(height: 24 * s),
          Text(
            'Rest & Recover',
            style: GoogleFonts.montserrat(
              fontSize: 28 * fs,
              fontWeight: FontWeight.w900,
              color: WorkoutColors.onSurface(context),
            ),
          ),
          SizedBox(height: 10 * s),
          Text(
            'Recovery is when your muscles grow and\nget stronger. Make today count.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15 * fs,
              color: WorkoutColors.onSurfaceMuted(context),
              height: 1.5,
            ),
          ),
          SizedBox(height: 36 * s),
          ...tips.asMap().entries.map((e) {
            final idx = e.key;
            final tip = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 14 * s),
              child:
                  Container(
                        padding: EdgeInsets.all(16 * s),
                        decoration: BoxDecoration(
                          color: tip.$3.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16 * s),
                          border: Border.all(color: tip.$3.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10 * s),
                              decoration: BoxDecoration(
                                color: tip.$3.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(tip.$2, color: tip.$3, size: 20 * s),
                            ),
                            SizedBox(width: 14 * s),
                            Expanded(
                              child: Text(
                                tip.$1,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15 * fs,
                                  fontWeight: FontWeight.w700,
                                  color: WorkoutColors.onSurface(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 * idx))
                      .slideX(begin: 0.1),
            );
          }),
        ],
      ),
    );
  }
}

// ── Exercise Card ────────────────────────────────────────────────────────────

class _SmartExerciseCard extends StatefulWidget {
  final SmartWorkoutExercise exercise;
  final int index;
  final double s;
  final double fs;

  const _SmartExerciseCard({
    required this.exercise,
    required this.index,
    required this.s,
    required this.fs,
  });

  @override
  State<_SmartExerciseCard> createState() => _SmartExerciseCardState();
}

class _SmartExerciseCardState extends State<_SmartExerciseCard> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _loadVisuals();
  }

  Future<void> _loadVisuals() async {
    final repo = ExerciseRepository();
    final item =
        await repo.getExerciseByName(widget.exercise.name) ??
        await repo.findExerciseByFuzzyName(widget.exercise.name);

    String? url;
    if (item?.gifUrl != null && item!.gifUrl!.isNotEmpty) {
      url = normalizeExerciseMediaUrl(item.gifUrl);
    } else {
      // Intelligent fallback using the same logic as curated cards
      url = stockWorkoutCoverUrl(
        name: widget.exercise.name,
        muscleGroup: widget.exercise.muscleGroup,
      );
    }

    if (mounted) {
      setState(() {
        _resolvedUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * widget.s),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(28 * widget.s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15 * widget.s,
            offset: Offset(0, 8 * widget.s),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28 * widget.s),
        onTap: () async {
          final repo = ExerciseRepository();
          final item =
              await repo.getExerciseByName(widget.exercise.name) ??
              await repo.findExerciseByFuzzyName(widget.exercise.name);

          if (item != null && context.mounted) {
            ExerciseDetailSheet.show(context, item);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exercise details not found')),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12 * widget.s),
          child: Row(
            children: [
              // ── Exercise Image ─────────────────────────────────────────────
              Container(
                width: 84 * widget.s,
                height: 84 * widget.s,
                decoration: BoxDecoration(
                  color: WorkoutColors.fill(context),
                  borderRadius: BorderRadius.circular(20 * widget.s),
                ),
                child: ExerciseGifImage(
                  imageUrl: _resolvedUrl ?? widget.exercise.name,
                  width: 84 * widget.s,
                  height: 84 * widget.s,
                  borderRadius: BorderRadius.circular(20 * widget.s),
                ),
              ),

              SizedBox(width: 16 * widget.s),

              // ── Details ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 18 * widget.fs,
                        fontWeight: FontWeight.w800,
                        color: WorkoutColors.onSurface(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2 * widget.s),
                    Text(
                      (widget.exercise.muscleGroup ?? 'Full Body')
                          .toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11 * widget.fs,
                        fontWeight: FontWeight.w900,
                        color: WorkoutColors.lime(context),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12 * widget.s),
                    Wrap(
                      spacing: 8 * widget.s,
                      runSpacing: 6 * widget.s,
                      children: [
                        _PillChip(
                          label: '${widget.exercise.sets} Sets',
                          s: widget.s,
                          fs: widget.fs,
                        ),
                        _PillChip(
                          label: '${widget.exercise.reps} Reps',
                          s: widget.s,
                          fs: widget.fs,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Index Badge ────────────────────────────────────────────────
              Container(
                width: 32 * widget.s,
                height: 32 * widget.s,
                margin: EdgeInsets.only(
                  left: 8 * widget.s,
                  right: 4 * widget.s,
                ),
                decoration: BoxDecoration(
                  color: WorkoutColors.fill(context),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: GoogleFonts.montserrat(
                      fontSize: 13 * widget.fs,
                      fontWeight: FontWeight.w900,
                      color: WorkoutColors.onSurface(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * widget.index))
        .slideY(begin: 0.1);
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final double s;
  final double fs;

  const _PillChip({required this.label, required this.s, required this.fs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: WorkoutColors.fill(context),
        borderRadius: BorderRadius.circular(10 * s),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12 * fs,
          fontWeight: FontWeight.w600,
          color: WorkoutColors.onSurfaceMuted(context),
        ),
      ),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final double s;
  final double fs;
  final bool isDark;

  const _HeaderMeta({
    required this.icon,
    required this.label,
    required this.s,
    required this.fs,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : WorkoutColors.onSurfaceMuted(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14 * s, color: color),
        SizedBox(width: 6 * s),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13 * fs,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
