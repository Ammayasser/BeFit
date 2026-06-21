import 'package:befit/features/workout/presentation/screens/smart_workout_generator_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/setup/presentation/screens/gender_selection_screen.dart';
import '../../features/setup/presentation/screens/age_selection_screen.dart';
import '../../features/setup/presentation/screens/height_selection_screen.dart';
import '../../features/setup/presentation/screens/weight_selection_screen.dart';
import '../../features/setup/presentation/screens/goal_selection_screen.dart';
import '../../features/setup/presentation/screens/activity_level_screen.dart';
import '../../features/setup/presentation/screens/experience_selection_screen.dart';
import '../../features/setup/presentation/screens/workout_location_screen.dart';
import '../../features/setup/presentation/screens/workout_days_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../features/workout/data/models/workout_routine.dart';
import '../../features/workout/data/models/workout_models.dart';
import '../../features/workout/presentation/screens/workout_detail_screen.dart';
import '../../features/workout/presentation/screens/active_session_screen.dart';
import '../../features/workout/presentation/screens/workout_victory_screen.dart';
import '../../features/workout/presentation/screens/exercise_library_screen.dart';
import '../../features/workout/presentation/screens/workout_discover_screen.dart';
import '../../features/workout/presentation/screens/workout_filters_screen.dart';
import '../../features/workout/presentation/screens/workout_progress_screen.dart';
import '../../features/workout/presentation/screens/recovery_dashboard_screen.dart';
import '../../features/workout/presentation/screens/workout_challenges_screen.dart';
import '../../features/workout/presentation/screens/programs_screen.dart';
import '../../features/workout/presentation/screens/program_detail_screen.dart';
import '../../features/workout/presentation/screens/saved_workouts_screen.dart';
import '../../features/workout/presentation/screens/workout_ai_coach_screen.dart';
import '../../features/workout/presentation/screens/exercise_detail_screen.dart';
import '../../features/workout/presentation/screens/routine_edit_screen.dart';
import '../../features/workout/presentation/screens/ai_workout_recognition_screen.dart';
import '../../features/workout/presentation/screens/custom_programs_screen.dart';
import '../../features/workout/presentation/screens/custom_program_editor_screen.dart';
import '../../features/workout/presentation/screens/custom_program_day_screen.dart';
import '../../features/workout/presentation/screens/custom_program_overview_screen.dart';
import '../../features/nutrition/data/models/recipe.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/nutrition/presentation/screens/recipes_screen.dart';
import '../../features/nutrition/presentation/screens/recipe_detail_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/achievements_screen.dart';
import '../../features/profile/presentation/screens/notifications_settings_screen.dart';
import '../../features/profile/presentation/screens/privacy_policy_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';

import '../../features/setup/presentation/screens/plan_generation_screen.dart';
import '../../features/progress/presentation/screens/progress_dashboard_screen.dart';
import '../../features/progress/presentation/screens/weight_history_screen.dart';
import '../../features/progress/presentation/screens/photo_compare_screen.dart';
import '../../features/progress/data/models/progress_photo.dart';
import 'app_routes.dart';
import 'ui/main_navigation_shell.dart';

class AppRouter {
  static GoRouter router({required AuthProvider authProvider}) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: AppRoutes.splash,
      redirect: (context, state) {
        final authStatus = authProvider.status;
        final currentPath = state.matchedLocation;

        if (currentPath == AppRoutes.splash) return null;

        if (authStatus == AuthStatus.authenticated) {
          if (currentPath.startsWith(AppRoutes.onboarding) ||
              currentPath == AppRoutes.login ||
              currentPath.startsWith(AppRoutes.setup)) {
            return AppRoutes.home;
          }
          // Allow create-account screen to display success dialog and handle transition
          if (currentPath == AppRoutes.createAccount) return null;
          // Allow plan-generation even when authenticated
          if (currentPath == AppRoutes.planGeneration) return null;
          return null;
        }

        if (authStatus == AuthStatus.unauthenticated ||
            authStatus == AuthStatus.error) {
          if (currentPath == AppRoutes.onboarding ||
              currentPath == AppRoutes.login ||
              currentPath == AppRoutes.createAccount ||
              currentPath.startsWith(AppRoutes.setup)) {
            return null;
          }
          return authProvider.hasSeenOnboarding
              ? AppRoutes.login
              : AppRoutes.onboarding;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.createAccount,
          builder: (context, state) => const CreateAccountScreen(),
        ),
        GoRoute(
          path: AppRoutes.setup,
          builder: (context, state) => const GenderSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupAge,
          builder: (context, state) => const AgeSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupHeight,
          builder: (context, state) => const HeightSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupWeight,
          builder: (context, state) => const WeightSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupGoal,
          builder: (context, state) => const GoalSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupActivity,
          builder: (context, state) => const ActivityLevelScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupExperience,
          builder: (context, state) => const ExperienceSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupLocation,
          builder: (context, state) => const WorkoutLocationScreen(),
        ),
        GoRoute(
          path: AppRoutes.setupWorkoutDays,
          builder: (context, state) => const WorkoutDaysScreen(),
        ),
        GoRoute(
          path: AppRoutes.planGeneration,
          builder: (context, state) => const PlanGenerationScreen(),
        ),
        GoRoute(
          path: AppRoutes.workoutRecognition,
          builder: (context, state) => const AiWorkoutRecognitionScreen(),
        ),

        // Workout session — full-screen, no nav bar
        GoRoute(
          path: AppRoutes.workoutSession,
          builder: (context, state) => const ActiveSessionScreen(),
        ),
        // Workout summary — full-screen, no nav bar
        GoRoute(
          path: AppRoutes.workoutSummary,
          builder: (context, state) {
            final session = state.extra as WorkoutSession?;
            if (session == null) {
              return const Scaffold(
                body: Center(child: Text('No active workout session found.')),
              );
            }
            return WorkoutVictoryScreen(session: session);
          },
        ),

        // Main shell
        ShellRoute(
          builder: (context, state, child) {
            return MainNavigationShell(child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),

            GoRoute(
              path: AppRoutes.workout,
              builder: (context, state) => const WorkoutScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return WorkoutDetailScreen(workoutId: id);
                  },
                ),
                GoRoute(
                  path: 'plans',
                  builder: (context, state) => const ProgramsScreen(),
                ),
                GoRoute(
                  path: 'programs',
                  builder: (context, state) => const ProgramsScreen(),
                ),
                GoRoute(
                  path: 'program/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return ProgramDetailScreen(programId: id);
                  },
                ),
                GoRoute(
                  path: 'library',
                  builder: (context, state) => const ExerciseLibraryScreen(),
                ),
                GoRoute(
                  path: 'discover',
                  builder: (context, state) => const WorkoutDiscoverScreen(),
                ),
                GoRoute(
                  path: 'filters',
                  builder: (context, state) => const WorkoutFiltersScreen(),
                ),
                GoRoute(
                  path: 'progress',
                  builder: (context, state) => const WorkoutProgressScreen(),
                ),
                GoRoute(
                  path: 'recovery',
                  builder: (context, state) => const RecoveryDashboardScreen(),
                ),
                GoRoute(
                  path: 'challenges',
                  builder: (context, state) => const WorkoutChallengesScreen(),
                ),
                GoRoute(
                  path: 'saved',
                  builder: (context, state) => const SavedWorkoutsScreen(),
                ),
                GoRoute(
                  path: 'ai-coach',
                  builder: (context, state) => const WorkoutAiCoachScreen(),
                ),
                GoRoute(
                  path: 'generator',
                  builder: (context, state) {
                    final isReplacing = state.extra as bool? ?? false;
                    return SmartWorkoutGeneratorScreen(
                      isReplacingSmartPlan: isReplacing,
                    );
                  },
                ),
                GoRoute(
                  path: 'exercise/:id',
                  builder: (context, state) {
                    final exercise = state.extra as ExerciseLibraryItem?;
                    if (exercise == null) {
                      return const Scaffold(
                        body: Center(child: Text('Exercise not found')),
                      );
                    }
                    return ExerciseDetailScreen(exercise: exercise);
                  },
                ),
                GoRoute(
                  path: 'routine/edit',
                  builder: (context, state) {
                    final routine = state.extra as WorkoutRoutine?;
                    return RoutineEditScreen(routine: routine);
                  },
                ),
                GoRoute(
                  path: 'my-programs',
                  builder: (_, _) => const CustomProgramsScreen(),
                  routes: [
                    GoRoute(
                      path: ':programId',
                      builder: (_, state) => CustomProgramOverviewScreen(
                        programId: state.pathParameters['programId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (_, state) => CustomProgramEditorScreen(
                            programId: state.pathParameters['programId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'day/:dayId',
                          builder: (_, state) => CustomProgramDayScreen(
                            programId: state.pathParameters['programId']!,
                            dayId: state.pathParameters['dayId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.nutrition,
              builder: (context, state) => const NutritionScreen(),
              routes: [
                GoRoute(
                  path: 'recipes',
                  builder: (context, state) => const RecipesScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is Recipe) {
                          return RecipeDetailScreen(recipe: extra);
                        }
                        final idStr = state.pathParameters['id'];
                        final id = int.tryParse(idStr ?? '');
                        if (id != null) {
                          return RecipeDetailScreen(lookupId: id);
                        }
                        return Scaffold(
                          body: Center(
                            child: Text(
                              'Recipe not found',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.community,
              builder: (context, state) => const CommunityScreen(),
            ),
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditProfileScreen(),
                ),
                GoRoute(
                  path: 'achievements',
                  builder: (context, state) => const AchievementsScreen(),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) =>
                      const NotificationsSettingsScreen(),
                ),
                GoRoute(
                  path: 'privacy-policy',
                  builder: (context, state) => const PrivacyPolicyScreen(),
                ),
                GoRoute(
                  path: 'help-support',
                  builder: (context, state) => const HelpSupportScreen(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const ProgressDashboardScreen(),
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (context, state) => const WeightHistoryScreen(),
                ),
                GoRoute(
                  path: 'compare',
                  builder: (context, state) {
                    final extras = state.extra as Map<String, dynamic>?;
                    final before = extras?['before'] as ProgressPhoto?;
                    final after = extras?['after'] as ProgressPhoto?;
                    return PhotoCompareScreen(
                      initialBefore: before,
                      initialAfter: after,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
    );
  }
}
