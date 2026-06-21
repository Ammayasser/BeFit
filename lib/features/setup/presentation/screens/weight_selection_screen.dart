import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/ruler_widget.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class WeightSelectionScreen extends StatefulWidget {
  const WeightSelectionScreen({super.key});

  @override
  State<WeightSelectionScreen> createState() => _WeightSelectionScreenState();
}

class _WeightSelectionScreenState extends State<WeightSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isKg = true;

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
        context.read<SetupProvider>().goToStep(SetupStep.weight);
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
        final weightKg = provider.weight ?? 80.0;
        final displayWeight = _isKg ? weightKg : weightKg * 2.20462;

        return SetupScreenScaffold(
          currentStep: provider.currentStepIndex + 1,
          totalSteps: provider.totalSteps,
          onBack: () {
            provider.previousStep();
            context.go(AppRoutes.setupHeight);
          },
          eyebrow: 'Basics',
          title: 'Your weight',
          subtitle: 'Used for tracking and targets.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: () {
            HapticFeedback.mediumImpact();
            provider.nextStep();
            context.go(AppRoutes.setupGoal);
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
                            label: 'CURRENT WEIGHT',
                            value: displayWeight.toStringAsFixed(0),
                            unit: _isKg ? 'kg' : 'lbs',
                            caption: '',
                          ),
                          const SizedBox(height: 16),
                          SetupSegmentedToggle(
                            labels: const ['Kilograms', 'Pounds'],
                            selectedIndex: _isKg ? 0 : 1,
                            onChanged: (index) {
                              setState(() => _isKg = index == 0);
                            },
                          ),
                          const SizedBox(height: 20),
                          SetupRulerPanel(
                            child: RulerWidget(
                              key: ValueKey(_isKg),
                              value: displayWeight,
                              minValue: _isKg ? 40 : 90,
                              maxValue: _isKg ? 180 : 400,
                              labelInterval: _isKg ? 5 : 10,
                              pixelsPerUnit: _isKg ? 15.0 : 8.0,
                              onValueChanged: (value) {
                                final kgValue = _isKg
                                    ? value
                                    : (value / 2.20462);
                                provider.setAnswer(SetupStep.weight, kgValue);
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
