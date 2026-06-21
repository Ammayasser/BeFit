import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../core/workout_user_resolver.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../data/models/workout_hub_stats.dart';
import '../providers/workout_hub_provider.dart';
import '../widgets/workout_cover_image.dart';
import '../widgets/workout_ui.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final programs = context.watch<WorkoutHubProvider>().programs;

    return WorkoutLightScaffold(
      appBar: const WorkoutBackAppBar(title: 'Programs'),
      body: SafeArea(
        child: programs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No active programs yet',
                        style: workoutTextStyle(
                          context,
                          size: 18,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enroll in a program from Training Plans to see it here.',
                        textAlign: TextAlign.center,
                        style: workoutTextStyle(
                          context,
                          size: 14,
                          color: WorkoutColors.onSurfaceMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: WorkoutColors.lime(context),
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  itemCount: programs.length,
                  itemBuilder: (ctx, i) => _programCard(context, programs[i]),
                ),
              ),
      ),
    );
  }

  Widget _programCard(BuildContext context, DynamicProgram p) {
    final gradient = p.gradientArgb.length >= 2
        ? [Color(p.gradientArgb[0]), Color(p.gradientArgb[1])]
        : [const Color(0xFF1E3A5F), const Color(0xFF0F172A)];

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.workout}/program/${p.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              WorkoutCoverImage(
                workoutRouteId: p.id,
                height: 200,
                borderRadius: BorderRadius.circular(24),
                muscleGroup: p.goal,
                category: p.difficulty,
                gradientColors: [
                  gradient[0].withValues(alpha: 0.25),
                  gradient[1].withValues(alpha: 0.75),
                ],
                overlayOpacity: 0.6,
              ),
              if (p.progress > 0)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: WorkoutColors.lime(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(p.progress * 100).toInt()}% done',
                      style: workoutTextStyle(
                        context,
                        size: 10,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: workoutTextStyle(
                        context,
                        size: 22,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${p.durationLabel} · ${p.difficulty}',
                      style: workoutTextStyle(
                        context,
                        size: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (p.progress > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.progress,
                          minHeight: 4,
                          backgroundColor: Colors.white24,
                          color: WorkoutColors.lime(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
