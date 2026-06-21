import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  static const _options = [
    (
      title: 'Lose Weight',
      subtitle: 'Lose fat',
      value: 'lose_weight',
      icon: Icons.trending_down_rounded,
      badge: null,
    ),
    (
      title: 'Build Muscle',
      subtitle: 'Gain strength',
      value: 'build_muscle',
      icon: Icons.fitness_center_rounded,
      badge: null,
    ),
    (
      title: 'Stay Fit',
      subtitle: 'Stay balanced',
      value: 'stay_fit',
      icon: Icons.favorite_rounded,
      badge: null,
    ),
    (
      title: 'Improve Endurance',
      subtitle: 'Build stamina',
      value: 'improve_endurance',
      icon: Icons.directions_run_rounded,
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SetupProvider>().goToStep(SetupStep.goal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SetupProvider>(
      builder: (context, provider, _) {
        return SetupScreenScaffold(
          currentStep: provider.currentStepIndex + 1,
          totalSteps: provider.totalSteps,
          onBack: () {
            provider.previousStep();
            context.go(AppRoutes.setupWeight);
          },
          eyebrow: 'Goal',
          title: 'What is your goal?',
          subtitle: 'Pick what matters most right now.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: provider.canGoNext
              ? () {
                  HapticFeedback.mediumImpact();
                  provider.nextStep();
                  context.go(AppRoutes.setupActivity);
                }
              : null,

          body: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              for (final option in _options)
                SetupOptionCard(
                  title: option.title,
                  subtitle: option.subtitle,
                  icon: option.icon,
                  badge: option.badge,
                  isSelected: provider.goal == option.value,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setAnswer(SetupStep.goal, option.value);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
