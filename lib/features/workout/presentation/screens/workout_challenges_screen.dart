import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/workout_user_resolver.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../data/models/workout_hub_stats.dart';
import '../providers/workout_hub_provider.dart';
import '../widgets/workout_ui.dart';

class WorkoutChallengesScreen extends StatefulWidget {
  const WorkoutChallengesScreen({super.key});

  @override
  State<WorkoutChallengesScreen> createState() =>
      _WorkoutChallengesScreenState();
}

class _WorkoutChallengesScreenState extends State<WorkoutChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<WorkoutHubProvider>().refresh(
      userId: WorkoutUserResolver.resolve(context),
      legacyUserId: WorkoutUserResolver.legacyDisplayNameKey(context),
      user: context.read<UserProvider>(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<WorkoutHubProvider>();
    final challenges = hub.challenges;
    final stats = hub.stats;

    return WorkoutLightScaffold(
      appBar: AppBar(
        backgroundColor: WorkoutColors.scaffold(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Challenges',
          style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: WorkoutColors.onSurface(context),
          unselectedLabelColor: WorkoutColors.onSurfaceMuted(context),
          indicatorColor: WorkoutColors.lime(context),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            color: WorkoutColors.lime(context),
            onRefresh: _refresh,
            child: _ActiveTab(challenges: challenges, stats: stats),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                challenges.where((c) => c.percent >= 1).isEmpty
                    ? 'Complete a challenge to see it here.'
                    : 'Completed challenges',
                style: workoutTextStyle(
                  context,
                  color: WorkoutColors.onSurfaceMuted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  final List<DynamicChallenge> challenges;
  final WorkoutHubStats stats;

  const _ActiveTab({required this.challenges, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'Log workouts to unlock challenges',
              style: workoutTextStyle(
                context,
                color: WorkoutColors.onSurfaceMuted(context),
              ),
            ),
          ),
        ],
      );
    }

    final monthly = challenges.firstWhere(
      (c) => c.isMonthly,
      orElse: () => challenges.first,
    );
    final others = challenges.where((c) => !c.isMonthly).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthly.title,
                      style: workoutTextStyle(
                        context,
                        size: 20,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      monthly.subtitle,
                      style: workoutTextStyle(
                        context,
                        size: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${monthly.progress.toInt()} / ${monthly.target.toInt()}',
                      style: workoutTextStyle(
                        context,
                        size: 14,
                        weight: FontWeight.w600,
                        color: WorkoutColors.lime(context),
                      ),
                    ),
                  ],
                ),
              ),
              CircularPercentIndicator(
                radius: 48,
                lineWidth: 8,
                percent: monthly.percent,
                center: Text(
                  '${monthly.target.toInt()}',
                  style: workoutTextStyle(
                    context,
                    size: 18,
                    weight: FontWeight.w800,
                    color: WorkoutColors.lime(context),
                  ),
                ),
                progressColor: WorkoutColors.lime(context),
                backgroundColor: Colors.white24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...others.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: WorkoutColors.border(context)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: workoutTextStyle(
                    context,
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.subtitle,
                  style: workoutTextStyle(
                    context,
                    size: 12,
                    color: WorkoutColors.onSurfaceMuted(context),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.percent,
                    minHeight: 6,
                    backgroundColor: WorkoutColors.card(context),
                    color: WorkoutColors.lime(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.progress.toInt()} / ${c.target.toInt()}',
                  style: workoutTextStyle(
                    context,
                    size: 11,
                    color: WorkoutColors.onSurfaceMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your Stats',
          style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _leaderRow(context, '#1', 'You', stats.monthlyWorkouts, true),
        if (stats.currentStreak > 0)
          _leaderRow(
            context,
            '#2',
            'Current streak',
            stats.currentStreak,
            false,
          ),
        if (stats.longestStreak > 0)
          _leaderRow(context, '#3', 'Best streak', stats.longestStreak, false),
      ],
    );
  }

  Widget _leaderRow(
    BuildContext context,
    String rank,
    String name,
    int score,
    bool highlight,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? WorkoutColors.limeMuted(context)
            : WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Row(
        children: [
          Text(
            rank,
            style: workoutTextStyle(context, size: 14, weight: FontWeight.w800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: workoutTextStyle(
                context,
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$score',
            style: workoutTextStyle(context, size: 14, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
