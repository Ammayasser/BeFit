library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:befit/features/profile/presentation/providers/user_provider.dart';
import 'package:befit/features/workout/presentation/providers/workout_hub_provider.dart';
import 'package:befit/features/workout/presentation/providers/workout_history_provider.dart';
import 'package:befit/features/workout/core/workout_user_resolver.dart';
import 'package:befit/features/nutrition/presentation/providers/nutrition_provider.dart';

import 'package:befit/features/home/presentation/widgets/home_theme.dart';
import 'package:befit/features/home/presentation/widgets/home_header.dart';
import 'package:befit/features/home/presentation/widgets/activity_rings_card.dart';
import 'package:befit/features/home/presentation/widgets/calorie_balance_card.dart';
import 'package:befit/features/home/presentation/widgets/weight_dashboard_card.dart';
import 'package:befit/features/home/presentation/widgets/today_plan_card.dart';

import 'package:befit/features/home/presentation/widgets/ai_coach_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    if (!mounted) return;
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    final historyProvider = context.read<WorkoutHistoryProvider>();
    final hubProvider = context.read<WorkoutHubProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    final uid = WorkoutUserResolver.resolve(context);
    final legacyUid = WorkoutUserResolver.legacyDisplayNameKey(context);

    await Future.wait([
      userProvider.loadProfile(),
      nutritionProvider.refresh(),
      hubProvider.refresh(
        userId: uid,
        legacyUserId: legacyUid,
        user: userProvider,
        historyProvider: historyProvider,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: HomeUi.pageBg(context),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: HomeUi.pageGradient(context)),
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: HomeUi.accent(context),
          backgroundColor: colorScheme.surface,
          displacement: 40,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const HomeHeaderSliver(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kHorizontalPadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    const SizedBox(height: 16),
                    const TodayPlanCard()
                        .animate()
                        .fadeIn(duration: kEntryDuration)
                        .slideY(begin: kSlideYBegin, end: 0),
                    const SizedBox(height: kSectionGap),
                    const ActivityRingsCard()
                        .animate()
                        .fadeIn(duration: kEntryDuration, delay: kStaggerDelay)
                        .slideY(begin: kSlideYBegin, end: 0),
                    const SizedBox(height: kSectionGap),
                    const CalorieBalanceCard()
                        .animate()
                        .fadeIn(
                          duration: kEntryDuration,
                          delay: kStaggerDelay * 3,
                        )
                        .slideY(begin: kSlideYBegin, end: 0),
                    const SizedBox(height: kSectionGap),
                    const WeightDashboardCard()
                        .animate()
                        .fadeIn(
                          duration: kEntryDuration,
                          delay: kStaggerDelay * 4,
                        )
                        .slideY(begin: kSlideYBegin, end: 0),
                    const SizedBox(height: kSectionGap),
                    const AiCoachCard()
                        .animate()
                        .fadeIn(
                          duration: kEntryDuration,
                          delay: kStaggerDelay * 5,
                        )
                        .slideY(begin: kSlideYBegin, end: 0),
                    const SizedBox(height: kBottomNavPadding),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

