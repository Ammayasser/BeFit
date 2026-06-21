import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profile/presentation/providers/user_provider.dart';
import '../achievements/engine/achievement_manager.dart';
import '../../features/profile/presentation/providers/profile_analytics_provider.dart';
import '../../features/nutrition/presentation/providers/nutrition_provider.dart';
import '../../features/community/presentation/providers/chat_provider.dart';
import '../../features/workout/presentation/providers/workout_session_provider.dart';
import '../../features/workout/presentation/providers/workout_history_provider.dart';
import '../../features/workout/presentation/providers/exercise_library_provider.dart';
import '../../features/workout/presentation/providers/workout_hub_provider.dart';
import '../../features/smart_plan/presentation/providers/smart_plan_provider.dart';
import '../../features/workout/presentation/providers/fitbod_workout_provider.dart';
import '../../features/workout/presentation/providers/saved_workouts_provider.dart';
import '../../features/progress/presentation/providers/progress_provider.dart';

class AppInitManager extends StatefulWidget {
  final Widget child;

  const AppInitManager({super.key, required this.child});

  @override
  State<AppInitManager> createState() => _AppInitManagerState();
}

class _AppInitManagerState extends State<AppInitManager> {
  String? _syncedLocalDataUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated && auth.userId != null) {
      final uid = auth.userId!;
      if (_syncedLocalDataUserId != uid) {
        _syncedLocalDataUserId = uid;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          _initUserServices(context, uid);
        });
      }
    } else if (auth.status == AuthStatus.unauthenticated) {
      if (_syncedLocalDataUserId != null) {
        _syncedLocalDataUserId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          _resetUserServices(context);
        });
      }
    }

    return widget.child;
  }

  Future<void> _initUserServices(BuildContext context, String uid) async {
    // ── Step 1: Load profile FIRST — everything else depends on it ──────────
    final userProvider = context.read<UserProvider>();
    await userProvider.loadProfile();

    // ── Step 2: Now that profile is loaded, read the real user values ────────
    final gender     = userProvider.gender;           // 'Male' or 'Female' — real value
    final experience = userProvider.experienceLevel;  // 'beginner', 'intermediate', 'advanced'
    final goal       = userProvider.fitnessGoal;      // 'BuildMuscle', 'LoseWeight', etc.
    final currentWeight = userProvider.weight;

    if (!context.mounted) return;

    // ── Step 3: Initialize everything else with correct values ───────────────
    context.read<AchievementManager>().init(uid);
    context.read<ProfileAnalyticsProvider>().initForUser(uid);
    context.read<NutritionProvider>().initForUser(uid);
    context.read<ChatProvider>().initForUser(uid, context);
    context.read<WorkoutSessionProvider>().initForUser(uid);
    context.read<WorkoutHistoryProvider>().initForUser(uid);
    context.read<ExerciseLibraryProvider>().initForUser(uid);

    // Deducing goal weight from weight and fitness goal
    double deducedGoalWeight = currentWeight;
    if (goal == 'LoseWeight') {
      deducedGoalWeight = currentWeight - 5.0;
    } else if (goal == 'BuildMuscle') {
      deducedGoalWeight = currentWeight + 4.0;
    }
    context.read<ProgressProvider>().initForUser(uid, userGoalWeight: deducedGoalWeight);

    // ── Step 4: Pass real gender/experience/goal to workout provider ─────────
    context.read<FitbodWorkoutProvider>().initForUser(
      uid,
      gender: gender,
      experience: experience,
      goal: goal,
    );

    context.read<SavedWorkoutsProvider>().load();
    context.read<WorkoutHubProvider>().refresh(
      userId: uid,
      user: userProvider,
      historyProvider: context.read<WorkoutHistoryProvider>(),
    );

    if (!context.mounted) return;
    context.read<SmartPlanProvider>().loadPlans(uid).then((_) {
      if (!context.mounted) return;
      final smartPlan = context.read<SmartPlanProvider>();
      if (smartPlan.hasMealPlan) {
        context.read<NutritionProvider>().setSmartCalorieGoal(
          smartPlan.mealPlan!.tdee,
        );
      }
    });
  }

  void _resetUserServices(BuildContext context) {
    context.read<ProfileAnalyticsProvider>().resetForLogout();
    context.read<NutritionProvider>().resetForLogout();
    context.read<ChatProvider>().resetForLogout();
    context.read<WorkoutSessionProvider>().resetForLogout();
    context.read<WorkoutHistoryProvider>().resetForLogout();
    context.read<ExerciseLibraryProvider>().resetForLogout();
    context.read<ProgressProvider>().resetForLogout();
    context.read<FitbodWorkoutProvider>().reset();
    context.read<WorkoutHubProvider>().reset();
    context.read<SmartPlanProvider>().reset();
  }
}
