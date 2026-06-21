import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/profile/presentation/providers/user_provider.dart';
import '../../features/setup/presentation/providers/setup_provider.dart';
import '../../features/community/presentation/providers/chat_provider.dart';
import '../../features/nutrition/presentation/providers/nutrition_provider.dart';
import '../../features/nutrition/presentation/providers/recipe_provider.dart';
import '../../features/workout/presentation/providers/exercise_library_provider.dart';
import '../../features/workout/presentation/providers/workout_history_provider.dart';
import '../../features/workout/presentation/providers/workout_session_provider.dart';
import '../../features/workout/presentation/providers/saved_workouts_provider.dart';
import '../../features/workout/presentation/providers/workout_hub_provider.dart';
import '../../features/workout/presentation/providers/routine_provider.dart';
import '../../features/workout/presentation/providers/ai_workout_provider.dart';
import '../../features/smart_plan/presentation/providers/smart_plan_provider.dart';
import '../../features/workout/presentation/providers/fitbod_workout_provider.dart';
import '../../features/workout/presentation/providers/custom_program_provider.dart';
import '../router/navigation_provider.dart';
import '../achievements/engine/achievement_manager.dart';
import '../../features/profile/presentation/providers/profile_analytics_provider.dart';
import '../../features/profile/presentation/providers/notification_provider.dart';

import '../../features/progress/presentation/providers/progress_provider.dart';

class ProviderSetup {
  static List<SingleChildWidget> getProviders(
    AuthProvider authProvider,
    SharedPreferences prefs,
  ) {
    return [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
      ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ChangeNotifierProvider(create: (_) => SetupProvider()),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => NutritionProvider()),
      ChangeNotifierProvider(create: (_) => WorkoutSessionProvider()),
      ChangeNotifierProvider(create: (_) => WorkoutHistoryProvider()),
      ChangeNotifierProvider(create: (_) => ExerciseLibraryProvider()),
      ChangeNotifierProvider(create: (_) => SavedWorkoutsProvider()),
      ChangeNotifierProvider(create: (_) => WorkoutHubProvider()),
      ChangeNotifierProvider(create: (_) => FitbodWorkoutProvider()),
      ChangeNotifierProvider(create: (_) => RoutineProvider()),
      ChangeNotifierProvider(create: (_) => AiWorkoutProvider()),
      ChangeNotifierProvider(create: (_) => SmartPlanProvider()),
      ChangeNotifierProvider(create: (_) => AchievementManager()),
      ChangeNotifierProvider(create: (_) => ProfileAnalyticsProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ChangeNotifierProvider(create: (_) => CustomProgramProvider()),

      ChangeNotifierProvider(
        create: (_) {
          final recipe = RecipeProvider();
          recipe.loadFavoritesFromPrefs();
          return recipe;
        },
      ),
    ];
  }
}

