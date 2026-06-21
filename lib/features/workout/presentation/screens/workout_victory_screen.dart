import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/token_service.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_log_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../providers/workout_session_provider.dart';
import '../providers/workout_history_provider.dart';
import '../providers/workout_hub_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import 'victory_colors.dart';
import 'victory_animation_queue.dart';
import 'victory_shockwave.dart';
import 'victory_body_map.dart';
import 'victory_pr_card.dart';
import 'victory_score_card.dart';
import 'victory_rank_badge.dart';
import 'muscle_name_resolver.dart';

class PRInfo {
  final String exerciseName;
  final String detail;
  final bool isWeightPR;

  PRInfo({required this.exerciseName, required this.detail, required this.isWeightPR});
}

class WorkoutVictoryScreen extends StatefulWidget {
  final WorkoutSession session;

  const WorkoutVictoryScreen({super.key, required this.session});

  @override
  State<WorkoutVictoryScreen> createState() => _WorkoutVictoryScreenState();
}

class _WorkoutVictoryScreenState extends State<WorkoutVictoryScreen> with SingleTickerProviderStateMixin {
  late final VictoryAnimationQueue _queue;
  late final AnimationController _shockwaveController;
  
  List<TrainedMuscle> _trainedMuscles = [];
  List<PRInfo> _prs = [];
  WorkoutRank _rank = WorkoutRank.B;
  String _rankLabel = 'Solid Effort';
  bool _isSaving = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    _queue = VictoryAnimationQueue();
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadData();
    _startAnimationSequence();
  }

  Future<void> _loadData() async {
    final workoutRepo = WorkoutLogRepository();
    final exerciseRepo = ExerciseRepository();
    final historyProvider = context.read<WorkoutHistoryProvider>();
    final userId = widget.session.userId;

    // 1. Compute Muscle Volume
    final Map<String, double> muscleVolumes = {};
    final Map<String, List<int>> muscleIds = {};
    final Map<String, bool> muscleIsSecondary = {};

    for (final ex in widget.session.exercises) {
      if (ex.isSkipped) continue;
      
      final libEx = await exerciseRepo.getExerciseByName(ex.name);
      if (libEx == null) continue;

      final exerciseVolume = ex.loggedSets
          .where((s) => s.isCompleted)
          .fold(0.0, (sum, s) => sum + (s.weightKg * s.reps));

      for (final m in libEx.primaryMuscles) {
        final ids = MuscleNameResolver.resolveToIds(m);
        if (ids.isNotEmpty) {
          final key = m.toLowerCase().trim();
          muscleVolumes[key] = (muscleVolumes[key] ?? 0) + exerciseVolume;
          muscleIds[key] = ids;
          muscleIsSecondary[key] = false;
        }
      }
      for (final m in libEx.secondaryMuscles) {
        final ids = MuscleNameResolver.resolveToIds(m);
        if (ids.isNotEmpty) {
          final key = m.toLowerCase().trim();
          if (muscleIsSecondary[key] != false) {
            muscleVolumes[key] = (muscleVolumes[key] ?? 0) + (exerciseVolume * 0.5);
            muscleIds[key] = ids;
            muscleIsSecondary[key] = true;
          }
        }
      }
    }

    _trainedMuscles = muscleVolumes.entries.map((e) => TrainedMuscle(
      ids: muscleIds[e.key]!,
      name: e.key,
      volume: e.value,
      isSecondary: muscleIsSecondary[e.key] ?? false,
    )).toList();

    // 2. Detect PRs
    final List<PRInfo> detectedPrs = [];
    for (final ex in widget.session.exercises) {
      if (ex.isSkipped) continue;
      
      final maxWeight = ex.loggedSets
          .where((s) => s.isCompleted)
          .fold(0.0, (max, s) => s.weightKg > max ? s.weightKg : max);
      
      if (maxWeight > 0) {
        final isWeightPR = await workoutRepo.isPersonalRecord(userId, ex.name, maxWeight);
        if (isWeightPR) {
          detectedPrs.add(PRInfo(
            exerciseName: ex.name,
            detail: '${maxWeight.toInt()}kg Max Lift!',
            isWeightPR: true,
          ));
        } else {
          // Check volume PR
          final sessionVol = ex.loggedSets
              .where((s) => s.isCompleted)
              .fold(0.0, (sum, s) => sum + (s.weightKg * s.reps));
          final historicalVol = await workoutRepo.getVolumeRecord(userId, ex.name);
          if (sessionVol > historicalVol) {
            detectedPrs.add(PRInfo(
              exerciseName: ex.name,
              detail: '${sessionVol.toInt()}kg Volume PR!',
              isWeightPR: false,
            ));
          }
        }
      }
    }
    _prs = detectedPrs;

    // 3. Compute Rank
    final currentVolume = widget.session.totalVolume;
    final history = historyProvider.history;
    if (history.length < 5) {
      _rank = WorkoutRank.A;
      _rankLabel = 'Great Start!';
    } else {
      final volumes = history.map((e) => e.totalVolume).toList()..sort();
      final p70 = volumes[(volumes.length * 0.7).floor()];
      final p90 = volumes[(volumes.length * 0.9).floor()];

      if (currentVolume >= p90) {
        _rank = WorkoutRank.S;
        _rankLabel = 'S-RANK: Top Session!';
      } else if (currentVolume >= p70) {
        _rank = WorkoutRank.A;
        _rankLabel = 'A-RANK: Great Session';
      } else {
        _rank = WorkoutRank.B;
        _rankLabel = 'B-RANK: Solid Effort';
      }
    }

    setState(() {
      _dataLoaded = true;
    });
  }

  void _startAnimationSequence() async {
    // Phase 1: Impact
    await Future.delayed(200.ms);
    HapticFeedback.heavyImpact();
    _shockwaveController.forward();
    await Future.delayed(600.ms);
    
    // Title & Counter animations are handled via flutter_animate in build
    await Future.delayed(2.seconds);
    _queue.advancePhase(); // -> muscleGlow

    // Phase 2: Muscle Glow
    // Wait for muscle cascade: muscles.length * 250ms + 1s buffer
    final cascadeDuration = (_trainedMuscles.length * 250) + 1000;
    await Future.delayed(Duration(milliseconds: cascadeDuration));
    _queue.advancePhase(); // -> prExplosion

    // Phase 3: PR Explosion
    if (_prs.isNotEmpty) {
      await Future.delayed((_prs.length * 600 + 1000).ms);
    }
    _queue.advancePhase(); // -> scoreCard
  }

  Future<void> _onSave(int mood, String note) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<WorkoutSessionProvider>();
      final token = await TokenService.instance.getToken() ?? '';

      await provider.finishSession(
        token,
        note,
        mood,
        context.read<WorkoutHistoryProvider>(),
      );

      if (mounted) {
        final uid = provider.session?.userId;
        if (uid != null) {
          context.read<WorkoutHubProvider>().refresh(
            userId: uid,
            user: context.read<UserProvider>(),
            historyProvider: context.read<WorkoutHistoryProvider>(),
          );
        }

        HapticFeedback.mediumImpact();
        context.go(AppRoutes.workout);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save workout: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _shockwaveController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VictoryColors.background,
      body: ListenableBuilder(
        listenable: _queue,
        builder: (context, _) {
          return GestureDetector(
            onTap: _queue.skip,
            child: Stack(
              children: [
                // Layer 1: Body Map
                if (_dataLoaded)
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: VictoryBodyMap(
                        trainedMuscles: _trainedMuscles,
                      ),
                    ),
                  ),

                // Layer 2: Shockwave
                AnimatedBuilder(
                  animation: _shockwaveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: VictoryShockwave(
                        progress: _shockwaveController.value,
                        color: VictoryColors.accent,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Layer 3: Title & Duration
                _buildHeader(),

                // Layer 4: PR Cards
                if (_dataLoaded && _queue.currentPhase == VictoryPhase.prExplosion)
                  Positioned(
                    top: 250,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _prs.take(3).map((pr) {
                        final index = _prs.indexOf(pr);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: VictoryPrCard(
                            exerciseName: pr.exerciseName,
                            prDetail: pr.detail,
                            delay: (index * 600).ms,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Layer 5: Score Card
                if (_dataLoaded && _queue.currentPhase == VictoryPhase.scoreCard)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VictoryScoreCard(
                      totalVolume: widget.session.totalVolume,
                      totalSets: widget.session.totalSets,
                      totalReps: widget.session.totalReps,
                      trainedMuscles: _trainedMuscles.map((m) => m.name).toList(),
                      rank: _rank,
                      rankLabel: _rankLabel,
                      onSave: _onSave,
                      isSaving: _isSaving,
                    ).animate().slideY(begin: 1.0, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'WORKOUT COMPLETE',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
          const SizedBox(height: 8),
          Text(
            widget.session.workoutName.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: VictoryColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 16),
          _buildDurationCounter(),
        ],
      ),
    );
  }

  Widget _buildDurationCounter() {
    final minutes = widget.session.duration.inMinutes;
    final seconds = widget.session.duration.inSeconds % 60;
    final timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Text(
      timeStr,
      style: GoogleFonts.robotoMono(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: VictoryColors.accent,
      ),
    ).animate(delay: 500.ms).fadeIn().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
  }
}
