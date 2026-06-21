import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/ruler_widget.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen>
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
        context.read<SetupProvider>().goToStep(SetupStep.age);
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
        final ageValue = provider.age ?? 22;

        return SetupScreenScaffold(
          currentStep: provider.currentStepIndex + 1,
          totalSteps: provider.totalSteps,
          onBack: () {
            provider.previousStep();
            context.go(AppRoutes.setup);
          },
          eyebrow: 'Basics',
          title: 'Your age',
          subtitle: 'Used to personalize your plan.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: () {
            HapticFeedback.mediumImpact();
            provider.nextStep();
            context.go(AppRoutes.setupHeight);
          },

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
                          SetupMetricCard(
                            label: 'YOUR AGE',
                            value: ageValue.toString(),
                            unit: 'yrs',
                            caption: '',
                          ),
                          const SizedBox(height: 20),
                          SetupRulerPanel(
                            child: RulerWidget(
                              value: ageValue.toDouble(),
                              minValue: 13,
                              maxValue: 100,
                              labelInterval: 10,
                              onValueChanged: (value) {
                                provider.setAnswer(
                                  SetupStep.age,
                                  value.toInt(),
                                );
                              },
                            ),
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
