// lib/features/workout/presentation/screens/workout_progress_screen.dart

import 'package:befit/features/workout/data/models/workout_hub_stats.dart';
import 'package:befit/features/workout/presentation/widgets/workout_screen/professional_workout_analytics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:befit/features/workout/core/workout_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/workout_user_resolver.dart';
import '../../data/models/workout_history_entry.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../providers/workout_history_provider.dart';
import '../providers/workout_hub_provider.dart';

class WorkoutProgressScreen extends StatefulWidget {
  const WorkoutProgressScreen({super.key});

  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen> {
  int _timeframeIndex = 0; // 0: 1W, 1: 1M, 2: 3M, 3: 6M, 4: 1Y

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final uid = WorkoutUserResolver.resolve(context);
    await context.read<WorkoutHubProvider>().refresh(
      userId: uid,
      legacyUserId: WorkoutUserResolver.legacyDisplayNameKey(context),
      user: context.read<UserProvider>(),
      historyProvider: context.read<WorkoutHistoryProvider>(),
    );
  }

  DateTime _timeframeStart(DateTime now) {
    final anchor = DateTime(now.year, now.month, now.day);
    switch (_timeframeIndex) {
      case 0:
        return anchor.subtract(const Duration(days: 7));
      case 1:
        return anchor.subtract(const Duration(days: 30));
      case 2:
        return anchor.subtract(const Duration(days: 90));
      case 3:
        return anchor.subtract(const Duration(days: 180));
      case 4:
        return anchor.subtract(const Duration(days: 365));
      default:
        return anchor.subtract(const Duration(days: 7));
    }
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: WorkoutColors.scaffold(context),
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: WorkoutColors.onSurface(context),
        ),
      ),
      title: Text(
        'Progress Tracker',
        style: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector(
    BuildContext context,
    List<String> timeframes, {
    double horizontalPadding = 20,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: WorkoutColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WorkoutColors.border(context)),
        ),
        child: Row(
          children: List.generate(timeframes.length, (i) {
            final isSelected = _timeframeIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _timeframeIndex = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WorkoutColors.primary(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    timeframes[i],
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : WorkoutColors.onSurfaceMuted(context),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    WorkoutHubStats stats,
    List<WorkoutHistoryEntry> filteredHistory,
    List<String> timeframes,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _buildSliverAppBar(context),

        // ── Professional Analytics Dashboard ──
        SliverToBoxAdapter(
          child: ProfessionalWorkoutAnalytics(
            stats: stats,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Timeframe Selector ──
        SliverToBoxAdapter(
          child: _buildTimeframeSelector(
            context,
            timeframes,
            horizontalPadding: 20,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Volume Summary Chart ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _ChartSection(
              title: 'Volume Distribution',
              subtitle: 'Aggregate load across selected period',
              icon: Icons.bar_chart_rounded,
              child: _ProfessionalBarChart(
                timeframeIndex: _timeframeIndex,
                history: filteredHistory,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Performance Trend Chart ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _ChartSection(
              title: 'Growth Trend',
              subtitle: 'Smoothed performance tracking',
              icon: Icons.trending_up_rounded,
              child: _ProfessionalLineChart(
                timeframeIndex: _timeframeIndex,
                history: filteredHistory,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // ── Recent History ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _ChartSection(
              title: 'Recent Sessions',
              subtitle: 'Detailed log history',
              icon: Icons.history_toggle_off_rounded,
              child: _HistoryList(history: filteredHistory.reversed.toList()),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    WorkoutHubStats stats,
    List<WorkoutHistoryEntry> filteredHistory,
    List<String> timeframes,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _buildSliverAppBar(context),

        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60, top: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Pane: Analytics Summary
                    Expanded(
                      flex: 9,
                      child:
                          ProfessionalWorkoutAnalytics(
                                stats: stats,
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 10,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.05, end: 0),
                    ),

                    // Right Pane: Graphs & Session Logs
                    Expanded(
                      flex: 11,
                      child:
                          Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Timeframe Selector
                                    _buildTimeframeSelector(
                                      context,
                                      timeframes,
                                      horizontalPadding: 0,
                                    ),
                                    const SizedBox(height: 24),

                                    // Volume Distribution Chart
                                    _ChartSection(
                                      title: 'Volume Distribution',
                                      subtitle:
                                          'Aggregate load across selected period',
                                      icon: Icons.bar_chart_rounded,
                                      child: _ProfessionalBarChart(
                                        timeframeIndex: _timeframeIndex,
                                        history: filteredHistory,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Performance Trend Chart
                                    _ChartSection(
                                      title: 'Growth Trend',
                                      subtitle: 'Smoothed performance tracking',
                                      icon: Icons.trending_up_rounded,
                                      child: _ProfessionalLineChart(
                                        timeframeIndex: _timeframeIndex,
                                        history: filteredHistory,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Recent Sessions List
                                    _ChartSection(
                                      title: 'Recent Sessions',
                                      subtitle: 'Detailed log history',
                                      icon: Icons.history_toggle_off_rounded,
                                      child: _HistoryList(
                                        history: filteredHistory.reversed
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 100.ms)
                              .slideY(begin: 0.05, end: 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<WorkoutHubProvider>();
    final stats = hub.stats;
    final history = context.watch<WorkoutHistoryProvider>().history;
    const timeframes = ['1W', '1M', '3M', '6M', '1Y'];

    final now = DateTime.now();
    final start = _timeframeStart(now);

    // Sort and filter history for the charts
    final sortedHistory = List<WorkoutHistoryEntry>.from(history)
      ..sort((a, b) {
        final da = DateTime.tryParse(a.date) ?? DateTime(2000);
        final db = DateTime.tryParse(b.date) ?? DateTime(2000);
        return da.compareTo(db);
      });

    final filteredHistory = sortedHistory.where((e) {
      final dt = DateTime.tryParse(e.date);
      if (dt == null) return false;
      return !dt.isBefore(start);
    }).toList();

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: WorkoutColors.primary(context),
        edgeOffset: 120,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;
            if (isWide) {
              return _buildWideLayout(
                context,
                stats,
                filteredHistory,
                timeframes,
              );
            } else {
              return _buildNarrowLayout(
                context,
                stats,
                filteredHistory,
                timeframes,
              );
            }
          },
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final IconData? icon;

  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = WorkoutColors.primary(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? WorkoutColors.card(context).withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: WorkoutColors.border(context).withValues(alpha: isDark ? 0.2 : 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Subtle Tech Grid Pattern
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.03 : 0.05,
              child: CustomPaint(painter: _GridPainter(spacing: 20)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Premium Header Inside Card
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: WorkoutColors.onSurface(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: WorkoutColors.onSurfaceMuted(
                                context,
                              ).withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                              textStyle: const TextStyle(height: 1.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 3. The Chart Content
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double spacing;
  _GridPainter({required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfessionalBarChart extends StatelessWidget {
  final int timeframeIndex;
  final List<WorkoutHistoryEntry> history;

  const _ProfessionalBarChart({
    required this.timeframeIndex,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final accent = WorkoutColors.primary(context);
    final now = DateTime.now();

    // Bucketing logic
    List<_ChartDataPoint> buckets = [];

    if (timeframeIndex == 0) {
      // 1W - Daily (last 7 days)
      buckets = List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final vol = history
            .where((e) => e.date == dateStr)
            .fold(0.0, (sum, e) => sum + e.totalVolume);
        return _ChartDataPoint(
          label: DateFormat('E').format(date).substring(0, 1),
          value: vol,
          isCurrent: i == 6,
        );
      });
    } else if (timeframeIndex == 1) {
      // 1M - Weekly (last 4 weeks)
      buckets = List.generate(4, (i) {
        final end = now.subtract(Duration(days: (3 - i) * 7));
        final start = end.subtract(const Duration(days: 6));
        final vol = history
            .where((e) {
              final dt = DateTime.tryParse(e.date);
              return dt != null &&
                  dt.isAfter(start.subtract(const Duration(days: 1))) &&
                  dt.isBefore(end.add(const Duration(days: 1)));
            })
            .fold(0.0, (sum, e) => sum + e.totalVolume);
        return _ChartDataPoint(
          label: 'W${i + 1}',
          value: vol,
          isCurrent: i == 3,
        );
      });
    } else {
      // Others - Monthly
      buckets = List.generate(12, (i) {
        final monthDate = DateTime(now.year, now.month - (11 - i), 1);
        final vol = history
            .where((e) {
              final dt = DateTime.tryParse(e.date);
              return dt != null &&
                  dt.year == monthDate.year &&
                  dt.month == monthDate.month;
            })
            .fold(0.0, (sum, e) => sum + e.totalVolume);
        return _ChartDataPoint(
          label: DateFormat('MMM').format(monthDate).substring(0, 1),
          value: vol,
          isCurrent: i == 11,
        );
      });
    }

    final totalVol = buckets.fold(0.0, (sum, b) => sum + b.value);
    if (totalVol <= 0) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No workout data for this period.',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WorkoutColors.onSurfaceMuted(context),
            ),
          ),
        ),
      );
    }

    final maxY = buckets
        .fold(0.0, (m, b) => b.value > m ? b.value : m)
        .clamp(100.0, double.infinity);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      buckets[i].label,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: buckets[i].isCurrent
                            ? accent
                            : WorkoutColors.onSurfaceMuted(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => WorkoutColors.onSurface(context),
              tooltipBorderRadius: BorderRadius.circular(12),
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${rod.toY.toInt()} kg',
                GoogleFonts.montserrat(
                  color: WorkoutColors.scaffold(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          barGroups: buckets.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: e.value.isCurrent ? accent : accent.withValues(alpha: 0.2),
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.2,
                    color: WorkoutColors.scaffold(context).withValues(alpha: 0.5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProfessionalLineChart extends StatelessWidget {
  final int timeframeIndex;
  final List<WorkoutHistoryEntry> history;

  const _ProfessionalLineChart({
    required this.timeframeIndex,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final accent = WorkoutColors.primary(context);
    final now = DateTime.now();

    // Data points logic
    List<_ChartDataPoint> points = [];
    if (timeframeIndex <= 1) {
      // Daily for 1W/1M
      final days = timeframeIndex == 0 ? 7 : 30;
      points = List.generate(days, (i) {
        final date = now.subtract(Duration(days: (days - 1) - i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final vol = history
            .where((e) => e.date == dateStr)
            .fold(0.0, (sum, e) => sum + e.totalVolume);
        return _ChartDataPoint(label: '', value: vol);
      });
    } else {
      // Weekly for 3M/6M/1Y
      final weeks = timeframeIndex == 2 ? 12 : (timeframeIndex == 3 ? 24 : 52);
      points = List.generate(weeks, (i) {
        final end = now.subtract(Duration(days: (weeks - 1 - i) * 7));
        final start = end.subtract(const Duration(days: 6));
        final vol = history
            .where((e) {
              final dt = DateTime.tryParse(e.date);
              return dt != null &&
                  dt.isAfter(start.subtract(const Duration(days: 1))) &&
                  dt.isBefore(end.add(const Duration(days: 1)));
            })
            .fold(0.0, (sum, e) => sum + e.totalVolume);
        return _ChartDataPoint(label: '', value: vol);
      });
    }

    final totalVol = points.fold(0.0, (sum, p) => sum + p.value);
    if (totalVol <= 0) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Keep training to see your trend!',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WorkoutColors.onSurfaceMuted(context),
            ),
          ),
        ),
      );
    }

    final maxY = points
        .fold(0.0, (m, b) => b.value > m ? b.value : m)
        .clamp(100.0, double.infinity);

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          maxY: maxY * 1.35,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: WorkoutColors.border(context).withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  WorkoutColors.onSurface(context).withValues(alpha: 0.9),
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${s.y.toInt()} kg',
                      GoogleFonts.montserrat(
                        color: WorkoutColors.scaffold(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            // 1. Glowing Shadow Line
            LineChartBarData(
              spots: points
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              color: accent.withValues(alpha: 0.2),
              barWidth: 8,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            // 2. Main Line
            LineChartBarData(
              spots: points
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              color: accent,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  // Only show dots for peak points or end points for a cleaner look
                  bool isPeak =
                      index > 0 &&
                      index < points.length - 1 &&
                      points[index].value > points[index - 1].value &&
                      points[index].value > points[index + 1].value;
                  bool isEnd = index == points.length - 1;

                  if (!isPeak && !isEnd && points.length > 15) {
                    return FlDotCirclePainter(radius: 0);
                  }

                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: accent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.05),
                    accent.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<WorkoutHistoryEntry> history;

  const _HistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: WorkoutColors.fill(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: WorkoutColors.border(context).withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 32,
                color: WorkoutColors.onSurfaceMuted(context).withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No sessions recorded in this period.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: WorkoutColors.onSurfaceMuted(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final accent = WorkoutColors.primary(context);

    return Column(
      children: history.take(5).map((e) {
        final dt = DateTime.tryParse(e.date) ?? DateTime.now();
        final day = DateFormat('dd').format(dt);
        final month = DateFormat('MMM').format(dt).toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WorkoutColors.fill(context).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: WorkoutColors.border(context).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Date Card
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      month,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      day,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 2. Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.focus ?? 'General Workout',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: WorkoutColors.onSurface(context),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: WorkoutColors.onSurfaceMuted(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(e.durationSeconds / 60).toInt()} min',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WorkoutColors.onSurfaceMuted(context),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 12,
                              color: WorkoutColors.onSurfaceMuted(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${e.totalSets} sets',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WorkoutColors.onSurfaceMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Volume Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${e.totalVolume.toInt()}',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                    Text(
                      'KG',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: accent.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ChartDataPoint {
  final String label;
  final double value;
  final bool isCurrent;
  _ChartDataPoint({
    required this.label,
    required this.value,
    this.isCurrent = false,
  });
}
