import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/curated_workouts.dart';
import '../providers/saved_workouts_provider.dart';
import '../widgets/workout_cover_image.dart';
import '../widgets/workout_ui.dart';
import '../widgets/exercise_list_tile.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../../data/models/workout_models.dart';

class SavedWorkoutsScreen extends StatefulWidget {
  const SavedWorkoutsScreen({super.key});

  @override
  State<SavedWorkoutsScreen> createState() => _SavedWorkoutsScreenState();
}

class _SavedWorkoutsScreenState extends State<SavedWorkoutsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SavedWorkoutsProvider>().load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedWorkoutsProvider>();
    final savedWorkouts = allCuratedWorkouts
        .where((w) => saved.isSaved(w.routeId))
        .toList();

    return WorkoutLightScaffold(
      appBar: AppBar(
        backgroundColor: WorkoutColors.scaffold(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Saved',
          style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: WorkoutColors.onSurface(context),
          unselectedLabelColor: WorkoutColors.onSurfaceMuted(context),
          indicatorColor: WorkoutColors.lime(context),
          tabs: const [
            Tab(text: 'Workouts'),
            Tab(text: 'Exercises'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          savedWorkouts.isEmpty
              ? _empty(
                  context,
                  'No saved workouts yet',
                  'Bookmark workouts from Discover or Details',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: savedWorkouts.length,
                  itemBuilder: (ctx, i) =>
                      _workoutCard(context, savedWorkouts[i]),
                ),
          FutureBuilder<List<ExerciseLibraryItem>>(
            future: context.read<ExerciseLibraryProvider>().getSaved(
              context.read<AuthProvider>().userId ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: WorkoutColors.lime(context),
                  ),
                );
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return _empty(
                  context,
                  'No saved exercises yet',
                  'Bookmark exercises from the Exercise Library',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final ex = list[i];
                  return ExerciseListTile(
                    exercise: ex,
                    onTap: () {
                      ExerciseDetailSheet.show(context, ex);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: WorkoutColors.onSurfaceSubtle(context),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: workoutTextStyle(
                context,
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: workoutTextStyle(
                context,
                size: 13,
                color: WorkoutColors.onSurfaceMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workoutCard(BuildContext context, CuratedWorkout w) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.workoutDetail.replaceFirst(':id', w.routeId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: WorkoutColors.border(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WorkoutCoverImage(
                workoutRouteId: w.routeId,
                width: 64,
                height: 64,
                muscleGroup: w.muscleGroup,
                category: w.category,
                overlayOpacity: 0.35,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    style: workoutTextStyle(
                      context,
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${w.durationMin} min · ${w.estimatedKcal} kcal',
                    style: workoutTextStyle(
                      context,
                      size: 12,
                      color: WorkoutColors.onSurfaceMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: WorkoutColors.onSurfaceMuted(context),
            ),
          ],
        ),
      ),
    );
  }
}
