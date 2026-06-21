import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class WorkoutDaysScreen extends StatefulWidget {
  const WorkoutDaysScreen({super.key});

  @override
  State<WorkoutDaysScreen> createState() => _WorkoutDaysScreenState();
}

class _WorkoutDaysScreenState extends State<WorkoutDaysScreen> {
  static const _options = [
    (
      days: 2,
      title: '2 Days per Week',
      subtitle: 'Light schedule',
      icon: Icons.looks_two_rounded,
      badge: null,
    ),
    (
      days: 3,
      title: '3 Days per Week',
      subtitle: 'Balanced schedule',
      icon: Icons.looks_3_rounded,
      badge: null,
    ),
    (
      days: 4,
      title: '4 Days per Week',
      subtitle: 'Focused schedule',
      icon: Icons.looks_4_rounded,
      badge: null,
    ),
    (
      days: 5,
      title: '5+ Days per Week',
      subtitle: 'High commitment',
      icon: Icons.calendar_month_rounded,
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SetupProvider>().goToStep(SetupStep.workoutDays);
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
            context.go(AppRoutes.setupLocation);
          },
          eyebrow: 'Schedule',
          title: 'How often do you train?',
          subtitle: 'Pick a schedule you can keep.',
          primaryButtonLabel: 'Finish Setup',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: provider.canGoNext
              ? () {
                  HapticFeedback.mediumImpact();
                  provider.nextStep();
                  context.go(AppRoutes.createAccount);
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
                  isSelected:
                      provider.workoutDays?.contains(option.days) ?? false,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setAnswer(SetupStep.workoutDays, [option.days]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
