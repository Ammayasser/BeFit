import 'package:befit/features/workout/data/models/fitbod_workout_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../providers/exercise_library_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../../smart_plan/presentation/providers/smart_plan_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/workout_session_provider.dart';
import '../providers/workout_hub_provider.dart';
import '../providers/custom_program_provider.dart';
import '../widgets/workout_screen/workout_hub_shared.dart';

import '../widgets/smart_plan_week_view.dart';
import '../widgets/workout_screen/workout_screen_components.dart';
import '../widgets/workout_screen/quick_start_card.dart';
import '../providers/fitbod_workout_provider.dart';
import '../widgets/workout_screen/netflix_workout_section.dart';
import '../widgets/workout_screen/challenge_hub_card.dart';

import '../widgets/workout_screen/ai_command_center.dart';
import '../widgets/workout_screen/discovery_carousel.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  UserProvider? _userProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  bool _wasSyncing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newUserProvider = context.watch<UserProvider>();
    final fitbodProvider = context.read<FitbodWorkoutProvider>();
    final libraryProvider = context.watch<ExerciseLibraryProvider>();

    // 1. Detect profile change
    if (_userProvider?.profile != newUserProvider.profile) {
      final oldGender = _userProvider?.gender.toLowerCase() ?? '';
      final newGender = newUserProvider.gender.toLowerCase();

      final profileJustLoaded =
          _userProvider?.profile == null && newUserProvider.profile != null;

      if (profileJustLoaded ||
          oldGender != newGender ||
          (fitbodProvider.isInitialized &&
              fitbodProvider.loadedForGender != newGender)) {
        Future.microtask(() => _loadData(forceRefresh: true));
      }
    }

    // 2. Detect sync completion
    if (_wasSyncing && !libraryProvider.isSyncing) {
      debugPrint('[WorkoutScreen] Sync completed - triggering data reload');
      Future.microtask(() => _loadData(forceRefresh: true));
    }
    _wasSyncing = libraryProvider.isSyncing;

    _userProvider = newUserProvider;
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;

    final fitbodProvider = context.read<FitbodWorkoutProvider>();
    final user = context.read<UserProvider>();

    // Don't load if profile isn't ready yet
    if (!user.hasProfile) return;

    if (!forceRefresh && fitbodProvider.isInitialized) return;

    if (forceRefresh) fitbodProvider.reset();

    // Run both in parallel — but since loadPersonalizedSections now checks
    // if _allWorkouts is already loaded and just re-slices, this is safe
    await Future.wait([
      fitbodProvider.loadCustomSections(
        user.gender,
        forceRefresh: forceRefresh,
      ),
      fitbodProvider.loadPersonalizedSections(
        gender: user.gender,
        experience: user.experienceLevel,
        goal: user.fitnessGoal,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.read<WorkoutSessionProvider>();
    final authProvider = context.read<AuthProvider>();
    final hubProvider = context.watch<WorkoutHubProvider>();
    final user = context.watch<UserProvider>();
    final smartPlan = context.watch<SmartPlanProvider>();
    final libraryProvider = context.watch<ExerciseLibraryProvider>();
    final fitbodProvider = context.watch<FitbodWorkoutProvider>();
    final hasSmartPlan = smartPlan.hasWorkoutPlan;

    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;
    final s = Responsive.scale(context, 1);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isNarrowScreen = size.width < 380;

    // Creative Personalization Logic
    final isFemale = user.gender.toLowerCase() == 'female';

    // 2. Goal row title
    String goalTitle;
    final goal = user.fitnessGoal.toLowerCase();
    if (goal.contains('muscle') || goal.contains('build')) {
      goalTitle = isFemale ? 'Sculpt & Define' : 'Hypertrophy: Build Mass';
    } else if (goal.contains('weight') ||
        goal.contains('fat') ||
        goal.contains('lose')) {
      goalTitle = 'Metabolic: Fat Burners';
    } else if (goal.contains('endurance')) {
      goalTitle = 'Endurance: Go the Distance';
    } else if (goal.contains('fit') ||
        goal.contains('tone') ||
        goal.contains('stay')) {
      goalTitle = isFemale ? 'Tone & Stay Fit' : 'Functional Fitness';
    } else {
      goalTitle = 'Recommended For You';
    }

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        color: colorScheme.primary,
        edgeOffset: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ─── Modern App Bar ───────────────────────────────────────────
            SliverAppBar(
              expandedHeight: isSmallScreen ? 120 : 140,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: colors.bgPrimary,
              surfaceTintColor: Colors.transparent,
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: HeaderPillButton(
                    icon: Icons.insights_rounded,
                    label: isNarrowScreen ? 'Stats' : 'Analytics',
                    onTap: () => context.push(AppRoutes.workoutProgress),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: HeaderCircleButton(
                    icon: Icons.search_rounded,
                    onTap: () {
                      context.read<ExerciseLibraryProvider>().resetFilters();
                      context.push('${AppRoutes.workout}/library');
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                expandedTitleScale: 1.2,
                titlePadding: EdgeInsets.symmetric(
                  horizontal: 20 * s,
                  vertical: 16 * s,
                ),
                title: Text(
                  'Workout',
                  style: GoogleFonts.montserrat(
                    fontSize: 22 * s,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // ─── Welcome Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 16 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'HELLO, ${user.displayName.toUpperCase()}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11 * s,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (libraryProvider.isSyncing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12 * s,
                            height: 12 * s,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SYNCING...',
                            style: GoogleFonts.montserrat(
                              fontSize: 9 * s,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // ─── Today's Plan: Primary Action ──────────────────────────────
            if (hasSmartPlan) ...[
              const SliverToBoxAdapter(child: SmartPlanWeekView()),
              SliverToBoxAdapter(child: SizedBox(height: 32 * s)),
            ],

            // ─── Premium AI Command Center ──────────────────────────────────
            SliverToBoxAdapter(
              child: AICommandCenter(
                onVisionTap: () => context.push(AppRoutes.workoutRecognition),
                onGeneratorTap: () =>
                    context.push(AppRoutes.workoutGenerator, extra: true),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 32 * s)),

            // ─── My Programs Section ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * s),
                child: _MyProgramsCard(
                  activeProgram: context
                      .watch<CustomProgramProvider>()
                      .activeProgram,
                  onBrowseTap: () => context.push(AppRoutes.customPrograms),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 32 * s)),

            // ─── Quick Start Action ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * s),
                child: QuickStartCard(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await sessionProvider.startSession(
                      'Empty Workout',
                      authProvider.userId ?? '',
                      [],
                    );
                    if (context.mounted) {
                      context.push(AppRoutes.workoutSession);
                    }
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 40 * s)),

            // ─── Explore by Muscle Group ──────────────────────────────────
            SliverToBoxAdapter(
              child: DiscoveryCarousel(
                title: 'Explore by Muscle Group',
                filterType: 'muscle',
                onSeeAll: () {
                  context.read<ExerciseLibraryProvider>().resetFilters();
                  context.push('${AppRoutes.workout}/library');
                },
                categories: const [
                  DiscoveryCategory(
                    id: 'chest',
                    name: 'Chest',
                    filterKey: 'Chest',
                  ),
                  DiscoveryCategory(
                    id: 'back',
                    name: 'Back',
                    filterKey: 'Back',
                  ),
                  DiscoveryCategory(
                    id: 'shoulders',
                    name: 'Shoulders',
                    filterKey: 'Shoulders',
                  ),
                  DiscoveryCategory(
                    id: 'biceps',
                    name: 'Biceps',
                    filterKey: 'Upper Arms',
                  ),
                  DiscoveryCategory(
                    id: 'triceps',
                    name: 'Triceps',
                    filterKey: 'Upper Arms',
                  ),
                  DiscoveryCategory(id: 'abs', name: 'Abs', filterKey: 'Waist'),
                  DiscoveryCategory(
                    id: 'quads',
                    name: 'Quads',
                    filterKey: 'Upper Legs',
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 40 * s)),

            // ─── Workout Sections ──────────────────────────────────────────
            if (!fitbodProvider.isInitialized || libraryProvider.isSyncing)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        libraryProvider.isSyncing
                            ? 'Initializing Workout Library (${(libraryProvider.syncProgress * 100).toInt()}%)...'
                            : 'Loading Workouts...',
                        style: GoogleFonts.montserrat(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (fitbodProvider.genderSections.every(
              (s) => s.workouts.isEmpty,
            ))
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(32 * s),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.data_usage_rounded,
                        size: 64 * s,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'NO WORKOUTS FOUND',
                        style: GoogleFonts.montserrat(
                          fontSize: 18 * s,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your workout database is empty or still initializing.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14 * s,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _loadData(forceRefresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('RELOAD DATABASE'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24 * s,
                            vertical: 12 * s,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ─── DYNAMIC GENDER-SPECIFIC SECTIONS ────────────────────────────────
              ...fitbodProvider.genderSections
                  .where((section) => section.workouts.isNotEmpty)
                  .map(
                    (section) => _buildSliverSection(
                      section.title,
                      section.workouts,
                      user.gender,
                      s,
                    ),
                  ),

              SliverToBoxAdapter(child: SizedBox(height: 36 * s)),

              // ─── 6. GOAL-BASED (Both genders) ────────────────────────────────────
              SliverToBoxAdapter(
                child: NetflixWorkoutSection(
                  title: goalTitle,
                  workouts: fitbodProvider.goalWorkouts,
                  userGender: user.gender,
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 36 * s)),

              // ─── 7. QUICK HITS (Both genders) ────────────────────────────────────
              SliverToBoxAdapter(
                child: NetflixWorkoutSection(
                  title: 'Quick Hits (< 30 Min)',
                  workouts: fitbodProvider.quickWorkouts,
                  userGender: user.gender,
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 40 * s)),

              // ─── Monthly Challenge ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: ChallengeHubCard(challenges: hubProvider.challenges),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 120 * s)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliverSection(
    String title,
    List<FitbodWorkout> workouts,
    String gender,
    double s,
  ) {
    if (workouts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          NetflixWorkoutSection(
            title: title,
            workouts: workouts,
            userGender: gender,
          ),
          SizedBox(height: 36 * s),
        ],
      ),
    );
  }
}

class _MyProgramsCard extends StatelessWidget {
  final dynamic activeProgram;
  final VoidCallback onBrowseTap;

  const _MyProgramsCard({
    required this.activeProgram,
    required this.onBrowseTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    if (activeProgram != null) {
      return Container(
        height: 180 * s,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32 * s),
          color: const Color(0xFF17191E),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24 * s,
              offset: Offset(0, 12 * s),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background mesh-like gradient
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [WorkoutHubTokens.lime, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // Faded Watermark Emoji
            Positioned(
              right: -20 * s,
              top: -10 * s,
              child: Opacity(
                opacity: 0.07,
                child: Text(
                  activeProgram.emoji ?? '💪',
                  style: TextStyle(fontSize: 140 * s),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * s,
                          vertical: 6 * s,
                        ),
                        decoration: BoxDecoration(
                          color: WorkoutHubTokens.lime.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8 * s),
                        ),
                        child: Text(
                          'CURRENT PROGRAM',
                          style: GoogleFonts.montserrat(
                            fontSize: 9 * fs,
                            fontWeight: FontWeight.w900,
                            color: WorkoutHubTokens.lime,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onBrowseTap,
                        child: Text(
                          'View All',
                          style: GoogleFonts.inter(
                            fontSize: 12 * fs,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeProgram.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 22 * fs,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6 * s),
                            Text(
                              'Week ${activeProgram.currentWeekIndex + 1} • Day ${activeProgram.currentDayIndex + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 13 * fs,
                                color: const Color(0xFFA0A3AB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(
                          '${AppRoutes.customPrograms}/${activeProgram.id}',
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18 * s,
                            vertical: 12 * s,
                          ),
                          decoration: BoxDecoration(
                            color: WorkoutHubTokens.lime,
                            borderRadius: BorderRadius.circular(16 * s),
                            boxShadow: [
                              BoxShadow(
                                color: WorkoutHubTokens.lime.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 15 * s,
                                offset: Offset(0, 5 * s),
                              ),
                            ],
                          ),
                          child: Icon(
                            Iconsax.play5,
                            color: Colors.black,
                            size: 20 * s,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20 * s),
                  Stack(
                    children: [
                      Container(
                        height: 6 * s,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      AnimatedContainer(
                        duration: 800.ms,
                        height: 6 * s,
                        width:
                            (MediaQuery.of(context).size.width - 88 * s) *
                            activeProgram.progressFraction,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [WorkoutHubTokens.lime, Color(0xFF7CA794)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: WorkoutHubTokens.lime.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    }

    return GestureDetector(
      onTap: onBrowseTap,
      child: Container(
        height: 100 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28 * s),
          color: const Color(0xFF17191E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20 * s,
              offset: Offset(0, 10 * s),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s),
          child: Row(
            children: [
              Container(
                width: 54 * s,
                height: 54 * s,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18 * s),
                ),
                child: Icon(
                  Iconsax.calendar_add,
                  color: AppColors.primary,
                  size: 24 * s,
                ),
              ),
              SizedBox(width: 16 * s),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Your System',
                      style: GoogleFonts.montserrat(
                        fontSize: 16 * fs,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Design your multi-week plan',
                      style: GoogleFonts.inter(
                        fontSize: 12 * fs,
                        color: const Color(0xFFA0A3AB),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36 * s,
                height: 36 * s,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 16 * s,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
