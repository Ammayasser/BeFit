import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SetupProvider>().goToStep(SetupStep.gender);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SetupProvider>(
      builder: (context, provider, _) {
        return SetupScreenScaffold(
          currentStep: provider.currentStepIndex + 1,
          totalSteps: provider.totalSteps,
          onBack: () => context.go(AppRoutes.onboarding),
          eyebrow: 'About you',
          title: 'Choose your gender',
          subtitle: 'Used to personalize your plan.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: provider.canGoNext
              ? () {
                  HapticFeedback.mediumImpact();
                  provider.nextStep();
                  context.go(AppRoutes.setupAge);
                }
              : null,

          body: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SetupOptionCard(
                            title: 'Male',
                            subtitle: '',
                            icon: Icons.male_rounded,
                            isSelected: provider.gender == 'male',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              provider.setAnswer(SetupStep.gender, 'male');
                            },
                          ),
                          SetupOptionCard(
                            title: 'Female',
                            subtitle: '',
                            icon: Icons.female_rounded,
                            isSelected: provider.gender == 'female',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              provider.setAnswer(SetupStep.gender, 'female');
                            },
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
