import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  static const _options = [
    (
      title: 'Sedentary',
      subtitle: 'Little exercise',
      value: 'sedentary',
      icon: Icons.weekend_rounded,
      badge: null,
    ),
    (
      title: 'Lightly Active',
      subtitle: '1-3 days / week',
      value: 'lightly_active',
      icon: Icons.directions_walk_rounded,
      badge: null,
    ),
    (
      title: 'Moderately Active',
      subtitle: '3-5 days / week',
      value: 'moderately_active',
      icon: Icons.local_fire_department_rounded,
      badge: null,
    ),
    (
      title: 'Very Active',
      subtitle: '6-7 days / week',
      value: 'very_active',
      icon: Icons.flash_on_rounded,
      badge: null,
    ),
    (
      title: 'Extra Active',
      subtitle: 'Athlete or physical job',
      value: 'extra_active',
      icon: Icons.bolt_rounded,
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SetupProvider>().goToStep(SetupStep.activity);
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
            context.go(AppRoutes.setupGoal);
          },
          eyebrow: 'Lifestyle',
          title: 'Your activity level',
          subtitle: 'Choose your typical week.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: provider.canGoNext
              ? () {
                  HapticFeedback.mediumImpact();
                  provider.nextStep();
                  context.go(AppRoutes.setupExperience);
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
                  isSelected: provider.activity == option.value,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setAnswer(SetupStep.activity, option.value);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
