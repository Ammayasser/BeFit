// lib/core/router/app_routes.dart

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String createAccount = '/create-account';

  // Setup flow
  static const String setup = '/setup';
  static const String setupAge = '/setup-age';
  static const String setupHeight = '/setup-height';
  static const String setupWeight = '/setup-weight';
  static const String setupGoal = '/setup-goal';
  static const String setupActivity = '/setup-activity';
  static const String setupExperience = '/setup-experience';
  static const String setupLocation = '/setup-location';
  static const String setupWorkoutDays = '/setup-workout-days';
  static const String planGeneration = '/plan-generation';

  // Home
  static const String home = '/home';

  // Workout flow
  static const String workout = '/workout';
  static const String workoutDetail = '/workout/detail/:id';
  static const String workoutProgress = '/workout/progress';
  static const String workoutRecovery = '/workout/recovery';
  static const String workoutSession = '/workout/session';
  static const String workoutSummary = '/workout/summary';
  static const String workoutLibrary = '/workout/library';
  static const String workoutDiscover = '/workout/discover';
  static const String workoutAI = '/workout/ai-coach';
  static const String workoutRecognition = '/workout/recognition';
  static const String workoutGenerator = '/workout/generator';
  static const String exerciseDetail = '/workout/exercise/:id';
  static const String routineEdit = '/workout/routine/edit';
  static const String customPrograms      = '/workout/my-programs';
  static const String customProgramDetail = '/workout/my-programs/:id';
  static const String customProgramEditor = '/workout/my-programs/:id/edit';
  static const String customProgramDay    = '/workout/my-programs/:id/day/:dayId';

  // Nutrition flow
  static const String nutrition = '/nutrition';
  static const String recipes = '/nutrition/recipes';
  static const String recipeDetail = '/nutrition/recipes/:id';

  // Community flow
  static const String community = '/community';

  // Profile flow
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String achievements = '/profile/achievements';
  static const String notifications = '/profile/notifications';
  static const String privacyPolicy = '/profile/privacy-policy';
  static const String helpSupport = '/profile/help-support';

  // Progress flow
  static const String progress = '/progress';
  static const String weightHistory = '/progress/history';
  static const String progressCompare = '/progress/compare';
}
