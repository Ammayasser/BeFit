import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/workout_colors.dart';
import '../providers/workout_hub_provider.dart';
import '../widgets/muscle_recovery_map.dart';
import '../widgets/recovery_legend.dart';
import '../widgets/muscle_detail_sheet.dart';
import '../../data/models/full_body_recovery_model.dart';
import '../../data/models/muscle_recovery_model.dart';

class RecoveryDashboardScreen extends StatelessWidget {
  const RecoveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<WorkoutHubProvider>();
    final recoveryState = hub.stats.fullBodyRecoveryState;

    if (recoveryState == null) {
      return Scaffold(
        backgroundColor: WorkoutColors.scaffold(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      appBar: AppBar(
        title: Text(
          'Recovery',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: WorkoutColors.onSurface(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: const BackButton(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;
          if (isWide) {
            return _buildWideLayout(context, recoveryState);
          } else {
            return _buildNarrowLayout(context, recoveryState);
          }
        },
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, FullBodyRecoveryState recoveryState) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Body Map Card (Muscle Status)
          Text(
            'Muscle Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: WorkoutColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: WorkoutColors.cardDecoration(context, radius: 24),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: MuscleRecoveryMap(
                    recoveryState: recoveryState,
                    showLabels: true,
                    onMuscleTap: (muscle) {
                      final state = recoveryState.muscles[muscle];
                      if (state != null) {
                        MuscleDetailSheet.show(context, state);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const RecoveryLegend(),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. Hero Readiness Section
          _buildReadinessHero(context, recoveryState.overallReadinessScore),
          const SizedBox(height: 32),

          // 3. Recommendation Focus Card
          _buildRecommendationCard(context, recoveryState),
          const SizedBox(height: 32),

          // 4. Per-Muscle Breakdown
          Text(
            'Detailed Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: WorkoutColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildMuscleTable(context, recoveryState),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, FullBodyRecoveryState recoveryState) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Pane: Muscle Status Body Map
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muscle Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: WorkoutColors.onSurface(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: WorkoutColors.cardDecoration(context, radius: 24),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Center(
                            child: MuscleRecoveryMap(
                              recoveryState: recoveryState,
                              showLabels: true,
                              onMuscleTap: (muscle) {
                                final state = recoveryState.muscles[muscle];
                                if (state != null) {
                                  MuscleDetailSheet.show(context, state);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const RecoveryLegend(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Pane: Readiness & Recommendations & Detailed Breakdown
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadinessHero(context, recoveryState.overallReadinessScore),
                    const SizedBox(height: 24),
                    _buildRecommendationCard(context, recoveryState),
                    const SizedBox(height: 24),
                    Text(
                      'Detailed Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: WorkoutColors.onSurface(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMuscleTable(context, recoveryState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadinessHero(BuildContext context, double score) {
    final pct = (score * 100).toInt();
    final color = pct > 70
        ? const Color(0xFF48BB78)
        : pct > 40
        ? const Color(0xFFECC94B)
        : const Color(0xFFE53E3E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: WorkoutColors.cardDecoration(context, radius: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 14,
                  color: color.withValues(alpha: 0.1),
                ),
              ),
              SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 14,
                      color: color,
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pct%',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    'READINESS',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: WorkoutColors.onSurfaceMuted(context),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            pct > 80
                ? 'Your body is primed for peak performance.'
                : pct > 60
                ? 'Good recovery. You can train at high intensity.'
                : 'Consider a lighter session or active recovery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: WorkoutColors.onSurface(context).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    FullBodyRecoveryState state,
  ) {
    final readyMuscles = state.readyMuscles
        .where((m) => m.recentEngagements.isNotEmpty)
        .toList();
    final top = readyMuscles.isNotEmpty
        ? readyMuscles.reduce(
            (a, b) => a.fatiguePercent < b.fatiguePercent ? a : b,
          )
        : null;

    final targetName = top?.muscleName ?? 'Full Body';
    final capitalize = targetName
        .split('-')
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join(' ');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: WorkoutColors.cardDecoration(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF48BB78).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF48BB78),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Focus',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: WorkoutColors.onSurface(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: WorkoutColors.onSurface(context),
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'Based on your recovery trends, your '),
                TextSpan(
                  text: capitalize,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF48BB78),
                  ),
                ),
                const TextSpan(
                  text:
                      ' is at optimal readiness. We recommend a session targeting this group for maximum efficiency.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleTable(BuildContext context, FullBodyRecoveryState state) {
    final list = state.muscles.values.toList()
      ..sort((a, b) => b.fatiguePercent.compareTo(a.fatiguePercent));

    return Column(
      children: list.map((m) {
        final percent = (100 - m.fatiguePercent * 100).toInt();
        final name = m.muscleName
            .split('-')
            .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
            .join(' ');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: WorkoutColors.cardDecoration(context, radius: 20),
          child: InkWell(
            onTap: () => MuscleDetailSheet.show(context, m),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: m.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: WorkoutColors.onSurface(context),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildStatusChip(context, m),
                          const SizedBox(width: 12),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: WorkoutColors.onSurface(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: WorkoutColors.border(context).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: (percent / 100.0).clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: m.color,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: m.color.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(BuildContext context, MuscleRecoveryState m) {
    String label = '';
    Color color = m.color;

    if (m.recentEngagements.isEmpty && m.fatiguePercent == 0.0) {
      label = 'Fresh';
      color = const Color(0xFF48BB78);
    } else {
      switch (m.recoveryTier) {
        case RecoveryTier.fatigued:
          label = 'Fatigued';
          break;
        case RecoveryTier.recovering:
          label = 'Recovering';
          break;
        case RecoveryTier.ready:
          label = 'Ready';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
