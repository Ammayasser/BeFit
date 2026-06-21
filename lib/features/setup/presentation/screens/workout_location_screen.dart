import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class WorkoutLocationScreen extends StatefulWidget {
  const WorkoutLocationScreen({super.key});

  @override
  State<WorkoutLocationScreen> createState() => _WorkoutLocationScreenState();
}

class _WorkoutLocationScreenState extends State<WorkoutLocationScreen> {
  static const _options = [
    (
      title: 'Gym',
      subtitle: 'Full equipment access',
      value: 'gym',
      icon: Icons.fitness_center_rounded,
      badge: null,
    ),
    (
      title: 'Home',
      subtitle: 'Minimal equipment',
      value: 'home',
      icon: Icons.home_rounded,
      badge: null,
    ),
    (
      title: 'Outdoor',
      subtitle: 'Open-air workouts',
      value: 'outdoor',
      icon: Icons.park_rounded,
      badge: null,
    ),
    (
      title: 'Anywhere',
      subtitle: 'Flexible anywhere',
      value: 'anywhere',
      icon: Icons.public_rounded,
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SetupProvider>().goToStep(SetupStep.location);
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
            context.go(AppRoutes.setupExperience);
          },
          eyebrow: 'Setup',
          title: 'Where do you train?',
          subtitle: 'We will adapt your plan to your setup.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: provider.canGoNext
              ? () {
                  HapticFeedback.mediumImpact();
                  provider.nextStep();
                  context.go(AppRoutes.setupWorkoutDays);
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
                  isSelected: provider.location == option.value,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setAnswer(SetupStep.location, option.value);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
