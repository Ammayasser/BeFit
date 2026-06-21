import 'dart:async';
import 'package:befit/features/workout/presentation/providers/workout_session_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/workout_models.dart';
import '../providers/workout_history_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'exercise_gif_image.dart';
import 'muscle_map_widget.dart';
import 'exercise_video_player.dart';
import '../../core/workout_colors.dart';

class ExerciseDetailSheet extends StatelessWidget {
  final ExerciseLibraryItem exercise;

  const ExerciseDetailSheet({super.key, required this.exercise});

  static void show(BuildContext context, ExerciseLibraryItem exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: WorkoutColors.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Modern drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: WorkoutColors.border(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: NestedScrollView(
                          controller: scrollController,
                          headerSliverBuilder: (context, innerBoxIsScrolled) =>
                              [
                                SliverToBoxAdapter(
                                  child: _HeroHeader(exercise: exercise),
                                ),
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _TabBarDelegate(
                                    TabBar(
                                      isScrollable: false,
                                      indicatorColor: WorkoutColors.lime(
                                        context,
                                      ),
                                      indicatorWeight: 3,
                                      indicatorSize: TabBarIndicatorSize.label,
                                      labelColor: WorkoutColors.onSurface(
                                        context,
                                      ),
                                      unselectedLabelColor:
                                          WorkoutColors.onSurfaceMuted(context),
                                      labelStyle:
                                          (Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall ??
                                                  const TextStyle())
                                              .copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                      unselectedLabelStyle:
                                          (Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall ??
                                                  const TextStyle())
                                              .copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                      tabs: const [
                                        Tab(text: 'ABOUT'),
                                        Tab(text: 'HISTORY'),
                                        Tab(text: 'CHARTS'),
                                        Tab(text: 'RECORDS'),
                                      ],
                                    ),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                          body: Container(
                            color: WorkoutColors.scaffold(context),
                            child: TabBarView(
                              children: [
                                _AboutTab(exercise: exercise),
                                _HistoryTab(exercise: exercise),
                                _ChartsTab(exercise: exercise),
                                _RecordsTab(exercise: exercise),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ─── Add to Session Button ──────────────────────────────
                      _buildActionFooter(context, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionFooter(BuildContext context, bool isDark) {
    final sessionProvider = context.watch<WorkoutSessionProvider>();
    if (sessionProvider.session == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await sessionProvider.addExerciseToSession(exercise);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${exercise.name} added to session'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: WorkoutColors.lime(context),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: WorkoutColors.lime(context),
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Text(
          'ADD TO CURRENT SESSION',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Hero header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _HeroHeader({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVideo)
          ExerciseVideoPlayer(videoUrl: exercise.videoUrl!)
        else
          _AnimatedExerciseImage(images: exercise.images),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: WorkoutColors.onSurface(context),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (exercise.bodyPart != null)
                      _ModernTag(
                        exercise.bodyPart!,
                        color: WorkoutColors.lime(context),
                      ),
                    if (exercise.category != null)
                      _ModernTag(exercise.category!),
                    if (exercise.difficulty != null)
                      _ModernTag(exercise.difficulty!),
                    if (exercise.equipment != null)
                      _ModernTag(exercise.equipment!),
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

class _ModernTag extends StatelessWidget {
  final String label;
  final Color? color;
  const _ModernTag(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? WorkoutColors.onSurfaceMuted(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AnimatedExerciseImage extends StatefulWidget {
  final List<String> images;
  const _AnimatedExerciseImage({required this.images});

  @override
  State<_AnimatedExerciseImage> createState() => _AnimatedExerciseImageState();
}

class _AnimatedExerciseImageState extends State<_AnimatedExerciseImage> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.images.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        color: const Color(0xFFF8FAFB),
        child: Icon(
          Icons.fitness_center_rounded,
          size: 64,
          color: Color(0xFFCBD5E1),
        ),
      );
    }

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: ExerciseGifImage(
            key: ValueKey(widget.images[_currentIndex]),
            imageUrl: widget.images[_currentIndex],
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 16,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Tab bar delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;
  _TabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => false;
}

// ─── About tab ────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _AboutTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (exercise.description != null &&
            exercise.description!.isNotEmpty) ...[
          _SectionHeader(title: 'Overview', icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),
          Text(
            exercise.description!,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              height: 1.5,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
        ],

        if (exercise.proTips.isNotEmpty) ...[
          _SectionHeader(
            title: 'Pro Tips',
            icon: Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 12),
          ...exercise.proTips.map((tip) {
            final isMistake = tip.type == 'common_mistake';
            final color = isMistake ? Colors.orange : const Color(0xFF7CA794);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isMistake
                            ? Icons.warning_amber_rounded
                            : Icons.lightbulb_rounded,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip.title,
                          style: GoogleFonts.montserrat(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tip.description,
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
        ],

        _SectionHeader(title: 'Details', icon: Icons.grid_view_rounded),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _DetailCard(
              label: 'Category',
              value: exercise.category ?? '—',
              icon: Icons.category_rounded,
            ),
            _DetailCard(
              label: 'Difficulty',
              value: exercise.difficulty ?? '—',
              icon: Icons.speed_rounded,
            ),
            _DetailCard(
              label: 'Mechanic',
              value: exercise.mechanic ?? '—',
              icon: Icons.settings_rounded,
            ),
            _DetailCard(
              label: 'Force',
              value: exercise.forceType ?? '—',
              icon: Icons.flash_on_rounded,
            ),
          ],
        ),

        const SizedBox(height: 32),

        if (exercise.instructions.isNotEmpty) ...[
          _SectionHeader(title: 'Instructions', icon: Icons.list_alt_rounded),
          const SizedBox(height: 16),
          ...exercise.instructions.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: WorkoutColors.lime(context).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: GoogleFonts.montserrat(
                        color: WorkoutColors.lime(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.montserrat(
                        color: WorkoutColors.onSurface(context),
                        height: 1.4,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: 32),

        _SectionHeader(title: 'Muscles', icon: Icons.accessibility_new_rounded),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (exercise.target != null)
              _MusclePill(exercise.target!, primary: true),
            ...exercise.secondaryMuscles.map(
              (m) => _MusclePill(m, primary: false),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: MuscleMapWidget(
            primaryMuscle: exercise.target ?? '',
            secondaryMuscles: exercise.secondaryMuscles,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: WorkoutColors.onSurfaceSubtle(context)),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: WorkoutColors.onSurfaceSubtle(context),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WorkoutColors.fill(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: WorkoutColors.onSurfaceMuted(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: WorkoutColors.onSurface(context),
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MusclePill extends StatelessWidget {
  final String label;
  final bool primary;
  const _MusclePill(this.label, {required this.primary});

  @override
  Widget build(BuildContext context) {
    final c = primary
        ? WorkoutColors.lime(context)
        : WorkoutColors.onSurfaceMuted(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurface(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _HistoryTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.read<WorkoutHistoryProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId ?? '';

    return FutureBuilder<List<LoggedSet>>(
      future: historyProvider.getExerciseHistory(exercise.name, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7CA794)),
          );
        }

        final sets = snapshot.data ?? [];
        if (sets.isEmpty) {
          return _EmptyState(
            title: 'No History',
            sub: 'Log this exercise to see progress.',
          );
        }

        final byDate = <String, List<LoggedSet>>{};
        for (final s in sets) {
          final key = _dateKey(s.loggedAt);
          byDate.putIfAbsent(key, () => []).add(s);
        }
        final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final sessionSets = byDate[date]!;
            return _HistorySessionCard(date: date, sets: sessionSets);
          },
        );
      },
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _HistorySessionCard extends StatelessWidget {
  final String date;
  final List<LoggedSet> sets;
  const _HistorySessionCard({required this.date, required this.sets});

  @override
  Widget build(BuildContext context) {
    final totalVol = sets.fold<double>(0, (s, e) => s + e.weightKg * e.reps);
    // ignore: unused_local_variable
    final bestSet = sets.reduce(
      (a, b) => (a.weightKg * a.reps) > (b.weightKg * b.reps) ? a : b,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: WorkoutColors.onSurface(context),
                      ),
                    ),
                    Text(
                      'Volume: ${totalVol.toStringAsFixed(0)} kg',
                      style: GoogleFonts.montserrat(
                        color: WorkoutColors.lime(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: WorkoutColors.border(context)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: sets
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: WorkoutColors.fill(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${s.setNumber}',
                              style: GoogleFonts.montserrat(
                                color: WorkoutColors.onSurfaceMuted(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${s.weightKg.toStringAsFixed(1)} kg × ${s.reps}',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: WorkoutColors.onSurface(context),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(s.weightKg * s.reps).toStringAsFixed(0)} kg',
                            style: GoogleFonts.montserrat(
                              color: WorkoutColors.onSurfaceMuted(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String key) {
    final dt = DateTime.tryParse(key);
    if (dt == null) return key;
    return '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─── Charts tab ───────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _ChartsTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.read<WorkoutHistoryProvider>();
    final userId = context.read<AuthProvider>().userId ?? '';

    return FutureBuilder<List<LoggedSet>>(
      future: historyProvider.getExerciseHistory(exercise.name, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7CA794)),
          );
        }
        final sets = snapshot.data ?? [];
        final dateMaxWeight = <String, double>{};
        for (final s in sets) {
          final key =
              '${s.loggedAt.year}-${s.loggedAt.month.toString().padLeft(2, '0')}-${s.loggedAt.day.toString().padLeft(2, '0')}';
          if ((dateMaxWeight[key] ?? 0) < s.weightKg) {
            dateMaxWeight[key] = s.weightKg;
          }
        }

        if (dateMaxWeight.isEmpty) {
          return _EmptyState(
            title: 'No Data',
            sub: 'Charts require logged workout sessions.',
          );
        }

        final sortedDates = dateMaxWeight.keys.toList()..sort();
        final spots = sortedDates
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), dateMaxWeight[e.value]!))
            .toList();
        final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SectionHeader(title: 'Progress', icon: Icons.show_chart_rounded),
            const SizedBox(height: 8),
            Text(
              'Best weight per session (kg)',
              style: GoogleFonts.montserrat(
                color: WorkoutColors.onSurfaceMuted(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 240,
              padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
              decoration: BoxDecoration(
                color: WorkoutColors.card(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: WorkoutColors.border(context)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: WorkoutColors.border(context),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (v) =>
                        FlLine(color: Colors.transparent),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, m) => Text(
                          '${v.toInt()}',
                          style: GoogleFonts.montserrat(
                            color: WorkoutColors.onSurfaceSubtle(context),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }
                          final d = sortedDates[idx].split('-');
                          return Text(
                            '${d[1]}/${d[2]}',
                            style: GoogleFonts.montserrat(
                              color: WorkoutColors.onSurfaceSubtle(context),
                              fontSize: 8,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => WorkoutColors.onSurface(
                        context,
                      ).withValues(alpha: 0.8),
                    ),
                  ),
                  minY: 0,
                  maxY: maxY * 1.25,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: WorkoutColors.lime(context),
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            WorkoutColors.lime(context).withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Records tab ──────────────────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  final ExerciseLibraryItem exercise;
  const _RecordsTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.read<WorkoutHistoryProvider>();
    final userId = authId(context);

    return FutureBuilder<List<LoggedSet>>(
      future: historyProvider.getExerciseHistory(exercise.name, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7CA794)),
          );
        }
        final sets = snapshot.data ?? [];
        if (sets.isEmpty) {
          return _EmptyState(
            title: 'No Records',
            sub: 'Achieve your first PR today!',
          );
        }

        LoggedSet? heaviest = sets.reduce(
          (a, b) => a.weightKg > b.weightKg ? a : b,
        );
        LoggedSet? bestVolSet = sets.reduce(
          (a, b) => (a.weightKg * a.reps) > (b.weightKg * b.reps) ? a : b,
        );

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SectionHeader(
              title: 'Milestones',
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: 20),
            _ModernRecordTile(
              label: 'Max Weight',
              value: '${heaviest.weightKg.toStringAsFixed(1)} kg',
              sub: 'Set of ${heaviest.reps} reps',
              icon: Icons.fitness_center_rounded,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 16),
            _ModernRecordTile(
              label: 'Highest Volume',
              value:
                  '${(bestVolSet.weightKg * bestVolSet.reps).toStringAsFixed(0)} kg',
              sub: '${bestVolSet.weightKg}kg × ${bestVolSet.reps} reps',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFF59E0B),
            ),
          ],
        );
      },
    );
  }

  String authId(BuildContext context) =>
      context.read<AuthProvider>().userId ?? '';
}

class _ModernRecordTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _ModernRecordTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: WorkoutColors.onSurfaceMuted(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: WorkoutColors.onSurface(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.montserrat(
                    color: WorkoutColors.onSurfaceMuted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String sub;
  const _EmptyState({required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: WorkoutColors.onSurfaceSubtle(context),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: WorkoutColors.onSurface(context),
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurfaceMuted(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
