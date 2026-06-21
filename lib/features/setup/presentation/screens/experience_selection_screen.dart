import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class ExperienceSelectionScreen extends StatefulWidget {
  const ExperienceSelectionScreen({super.key});

  @override
  State<ExperienceSelectionScreen> createState() =>
      _ExperienceSelectionScreenState();
}

class _ExperienceSelectionScreenState extends State<ExperienceSelectionScreen> {
  static const _options = [
    (
      title: 'Beginner',
      subtitle: 'Just getting started',
      value: 'beginner',
      icon: Icons.flag_rounded,
      badge: null,
    ),
    (
      title: 'Novice',
      subtitle: 'Some experience',
      value: 'novice',
      icon: Icons.school_rounded,
      badge: null,
    ),
    (
      title: 'Intermediate',
      subtitle: 'Regular training',
      value: 'intermediate',
      icon: Icons.show_chart_rounded,
      badge: null,
    ),
    (
      title: 'Advanced',
      subtitle: 'Strong experience',
      value: 'advanced',
      icon: Icons.workspace_premium_rounded,
      badge: null,
    ),
    (
      title: 'Expert',
      subtitle: 'Advanced athlete',
      value: 'expert',
      icon: Icons.military_tech_rounded,
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SetupProvider>().goToStep(SetupStep.experience);
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
            context.go(AppRoutes.setupActivity);
          },
          eyebrow: 'Experience',
          title: 'Your experience',
          subtitle: 'So we match the right intensity.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: provider.canGoNext
              ? () {
                  HapticFeedback.mediumImpact();
                  provider.nextStep();
                  context.go(AppRoutes.setupLocation);
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
                  isSelected: provider.experience == option.value,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setAnswer(SetupStep.experience, option.value);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
