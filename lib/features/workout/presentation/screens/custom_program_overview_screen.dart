import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../core/workout_user_resolver.dart';
import '../widgets/workout_screen/workout_hub_shared.dart';
import '../../data/models/custom_program_models.dart';
import '../providers/custom_program_provider.dart';

class CustomProgramOverviewScreen extends StatefulWidget {
  final String programId;

  const CustomProgramOverviewScreen({super.key, required this.programId});

  @override
  State<CustomProgramOverviewScreen> createState() =>
      _CustomProgramOverviewScreenState();
}

class _CustomProgramOverviewScreenState
    extends State<CustomProgramOverviewScreen> {
  CustomProgram? _program;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    setState(() => _isLoading = true);
    final program = await context.read<CustomProgramProvider>().loadProgramFull(
      widget.programId,
    );
    if (mounted) {
      setState(() {
        _program = program;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_program == null) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: Center(
          child: Text(
            'Program not found',
            style: TextStyle(color: colors.setupTextPrimary),
          ),
        ),
      );
    }

    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, s, fs),
          if (_program!.isActive)
            SliverToBoxAdapter(
              child: _ProgressCard(program: _program!, s: s, fs: fs),
            ),
          SliverToBoxAdapter(
            child: _WeekDayGrid(program: _program!, s: s, fs: fs),
          ),
          if (!_program!.isActive && !_program!.isCompleted)
            SliverToBoxAdapter(child: _buildActivateButton(context, s, fs)),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double s, double fs) {
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 200 * s,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.bgPrimary,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colors.setupTextPrimary,
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? const Color(0xFF1A2F1A) : colors.setupPrimary.withValues(alpha: 0.15),
                    colors.bgPrimary,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -20 * s,
              top: 20 * s,
              child: Opacity(
                opacity: isDark ? 0.04 : 0.08,
                child: Text(
                  _program!.emoji ?? '💪',
                  style: TextStyle(fontSize: 140 * s, color: colors.setupTextPrimary),
                ),
              ),
            ),
            Positioned(
              bottom: 20 * s,
              left: 20 * s,
              right: 100 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _program!.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 26 * fs,
                      fontWeight: FontWeight.w900,
                      color: colors.setupTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6 * s),
                  Row(
                    children: [
                      _MetaBadge(text: '${_program!.totalWeeks} Weeks', fs: fs),
                      SizedBox(width: 8 * s),
                      _MetaBadge(
                        text: '${_program!.daysPerWeek} Days/Wk',
                        fs: fs,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        title: Text(
          _program!.name,
          style: GoogleFonts.montserrat(
            fontSize: 18 * fs,
            fontWeight: FontWeight.w800,
            color: colors.setupTextPrimary,
          ).copyWith(
            // Only show title when collapsed
            color: colors.setupTextPrimary.withValues(alpha: 0),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Iconsax.edit_2, color: colors.setupTextPrimary),
          onPressed: () =>
              context.push('${AppRoutes.customPrograms}/${_program!.id}/edit'),
        ),
        IconButton(
          icon: Icon(Iconsax.trash, color: colors.setupTextPrimary),
          onPressed: _showDeleteDialog,
        ),
      ],
    );
  }

  Widget _buildActivateButton(BuildContext context, double s, double fs) {
    final colors = context.customColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 32 * s, 20 * s, 0),
      child: GestureDetector(
        onTap: _activateProgram,
        child: Container(
          width: double.infinity,
          height: 54 * s,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.setupPrimary, colors.setupPrimary.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Activate Program',
              style: GoogleFonts.montserrat(
                fontSize: 16 * fs,
                fontWeight: FontWeight.w800,
                color: colors.setupOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _activateProgram() async {
    final userId = WorkoutUserResolver.resolve(context);
    await context.read<CustomProgramProvider>().activateProgram(
      _program!.id,
      userId,
    );
    _loadProgram();
  }

  void _showDeleteDialog() {
    final colors = context.customColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text(
          'Delete Program',
          style: GoogleFonts.montserrat(color: colors.setupTextPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this program? This action cannot be undone.',
          style: TextStyle(color: colors.setupTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final userId = WorkoutUserResolver.resolve(context);
              await context.read<CustomProgramProvider>().deleteProgram(
                _program!.id,
                userId,
              );
              if (mounted) {
                Navigator.pop(context);
                context.pop();
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String text;
  final double fs;

  const _MetaBadge({required this.text, required this.fs});

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.setupTextPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11 * fs,
          fontWeight: FontWeight.w700,
          color: colors.setupTextPrimary,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CustomProgram program;
  final double s;
  final double fs;

  const _ProgressCard({
    required this.program,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    return Container(
      margin: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 0),
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: WorkoutHubTokens.lime.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: WorkoutHubTokens.lime.withValues(alpha: 0.05),
            blurRadius: 20 * s,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ProgressRing(progress: program.progressFraction, size: 60 * s),
              SizedBox(width: 16 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEK ${program.currentWeekIndex + 1} · DAY ${program.currentDayIndex + 1}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11 * fs,
                        fontWeight: FontWeight.w800,
                        color: WorkoutHubTokens.lime,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${program.progressLabel} Complete',
                      style: GoogleFonts.montserrat(
                        fontSize: 20 * fs,
                        fontWeight: FontWeight.w900,
                        color: colors.setupTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final day = program.currentDay;
                  if (day != null) {
                    context.push(
                      '${AppRoutes.customPrograms}/${program.id}/day/${day.id}',
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * s,
                    vertical: 10 * s,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [WorkoutHubTokens.lime, Color(0xFF7CA794)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.montserrat(
                      fontSize: 13 * fs,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          WorkoutHubMicroProgressBar(
            progress: program.progressFraction,
            color: WorkoutHubTokens.lime,
            s: s,
            height: 5,
            glow: true,
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final double size;

  const _ProgressRing({required this.progress, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress,
          trackColor: colors.border,
          progressColor: WorkoutHubTokens.lime,
          strokeWidth: 6,
        ),
        child: Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.montserrat(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w800,
              color: colors.setupTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeekDayGrid extends StatelessWidget {
  final CustomProgram program;
  final double s;
  final double fs;

  const _WeekDayGrid({
    required this.program,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 24 * s),
        WorkoutHubSectionHeader(title: 'Schedule', s: s, fs: fs),
        SizedBox(height: 16 * s),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20 * s),
          itemCount: program.weeks.length,
          itemBuilder: (context, index) {
            final week = program.weeks[index];
            return _WeekAccordion(week: week, program: program, s: s, fs: fs);
          },
        ),
      ],
    );
  }
}

class _WeekAccordion extends StatelessWidget {
  final ProgramWeek week;
  final CustomProgram program;
  final double s;
  final double fs;

  const _WeekAccordion({
    required this.week,
    required this.program,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final isCurrentWeek = week.weekNumber == program.currentWeekIndex + 1;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * s),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: ExpansionTile(
          initiallyExpanded: isCurrentWeek,
          tilePadding: EdgeInsets.symmetric(
            horizontal: 20 * s,
            vertical: 4 * s,
          ),
          childrenPadding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 12 * s),
          collapsedIconColor: colors.setupTextSecondary,
          iconColor: colors.setupTextPrimary,
          title: Row(
            children: [
              Text(
                week.displayName,
                style: GoogleFonts.montserrat(
                  fontSize: 15 * fs,
                  fontWeight: FontWeight.w700,
                  color: colors.setupTextPrimary,
                ),
              ),
              const Spacer(),
              if (week.isCompleted)
                const _StatusPill(text: 'DONE', color: Colors.green)
              else if (isCurrentWeek)
                const _StatusPill(
                  text: 'CURRENT',
                  color: WorkoutHubTokens.lime,
                ),
            ],
          ),
          children: week.days
              .map((day) => _DayRow(day: day, program: program, s: s, fs: fs))
              .toList(),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final ProgramDay day;
  final CustomProgram program;
  final double s;
  final double fs;

  const _DayRow({
    required this.day,
    required this.program,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final isCurrentDay =
        program.isActive &&
        day.programWeekId == program.weeks[program.currentWeekIndex].id &&
        day.dayNumber == program.currentDayIndex + 1;

    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.customPrograms}/${program.id}/day/${day.id}',
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 8 * s),
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentDay
                ? WorkoutHubTokens.lime.withValues(alpha: 0.4)
                : colors.border,
            width: isCurrentDay ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28 * s,
              height: 28 * s,
              decoration: BoxDecoration(
                color: day.isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : day.isRestDay
                    ? colors.border
                    : isCurrentDay
                    ? WorkoutHubTokens.lime.withValues(alpha: 0.12)
                    : colors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(
                day.isCompleted
                    ? Iconsax.tick_circle5
                    : day.isRestDay
                    ? Iconsax.moon5
                    : Iconsax.weight5,
                color: day.isCompleted
                    ? Colors.green
                    : day.isRestDay
                    ? colors.setupTextSecondary
                    : isCurrentDay
                    ? WorkoutHubTokens.lime
                    : colors.setupTextSecondary,
                size: 14 * s,
              ),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 13 * fs,
                      fontWeight: FontWeight.w700,
                      color: colors.setupTextPrimary,
                    ),
                  ),
                  if (!day.isRestDay)
                    Text(
                      '${day.exercises.length} exercises · ~${day.estimatedMinutes}m',
                      style: GoogleFonts.inter(
                        fontSize: 11 * fs,
                        color: colors.setupTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isCurrentDay)
              const _StatusPill(text: 'TODAY', color: WorkoutHubTokens.lime)
            else
              Icon(
                Iconsax.arrow_right_3,
                color: colors.setupTextSecondary.withValues(alpha: 0.5),
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}
