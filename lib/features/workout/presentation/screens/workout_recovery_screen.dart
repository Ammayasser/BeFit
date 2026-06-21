import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../core/workout_user_resolver.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../providers/workout_hub_provider.dart';
import '../widgets/workout_ui.dart';

class WorkoutRecoveryScreen extends StatefulWidget {
  const WorkoutRecoveryScreen({super.key});

  @override
  State<WorkoutRecoveryScreen> createState() => _WorkoutRecoveryScreenState();
}

class _WorkoutRecoveryScreenState extends State<WorkoutRecoveryScreen> {
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
    final hub = context.watch<WorkoutHubProvider>();
    final stats = hub.stats;
    final factors = hub.recoveryFactors;
    final score = stats.recoveryScore / 100;

    return WorkoutLightScaffold(
      appBar: const WorkoutBackAppBar(title: 'Recovery'),
      body: SafeArea(
        child: RefreshIndicator(
          color: WorkoutColors.lime(context),
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 100,
                  lineWidth: 12,
                  percent: score.clamp(0.05, 1.0),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.recoveryScore.round()}%',
                        style: workoutTextStyle(
                          context,
                          size: 36,
                          weight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${stats.recoveryLabel} Recovery',
                        style: workoutTextStyle(
                          context,
                          size: 14,
                          color: WorkoutColors.onSurfaceMuted(context),
                        ),
                      ),
                    ],
                  ),
                  progressColor: WorkoutColors.lime(context),
                  backgroundColor: WorkoutColors.card(context),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(height: 8),
                Text(
                  'Estimated from your training load, volume, and rest patterns.',
                  textAlign: TextAlign.center,
                  style: workoutTextStyle(
                    context,
                    size: 12,
                    color: WorkoutColors.onSurfaceSubtle(context),
                  ),
                ),
                const SizedBox(height: 32),
                ...factors.map((f) {
                  final color = f.statusLabel == 'Good'
                      ? const Color(0xFF22C55E)
                      : f.statusLabel == 'Fair'
                      ? const Color(0xFFF59E0B)
                      : WorkoutColors.onSurfaceMuted(context);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: WorkoutColors.border(context)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconForFactor(f.name),
                          color: WorkoutColors.onSurfaceMuted(context),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: workoutTextStyle(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                f.value,
                                style: workoutTextStyle(
                                  context,
                                  size: 12,
                                  color: WorkoutColors.onSurfaceMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            f.statusLabel,
                            style: workoutTextStyle(
                              context,
                              size: 12,
                              weight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WorkoutColors.limeMuted(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Recovery',
                              style: workoutTextStyle(
                                context,
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hub.suggestRecovery
                                  ? 'Recommended after ${stats.trainingLoad.toLowerCase()} training load'
                                  : 'Optional mobility — you\'re well recovered',
                              style: workoutTextStyle(
                                context,
                                size: 13,
                                color: WorkoutColors.onSurfaceMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      WorkoutPrimaryButton(
                        label: 'Start',
                        fullWidth: false,
                        onPressed: () {
                          final route = hub.featured?.routeId ?? 'recovery';
                          context.push(
                            AppRoutes.workoutDetail.replaceFirst(':id', route),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForFactor(String name) => switch (name) {
    'Sleep' => Icons.bedtime_outlined,
    'Training load' => Icons.fitness_center,
    'Soreness' => Icons.healing_outlined,
    _ => Icons.psychology_outlined,
  };
}
