import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/setup_provider.dart';
import '../widgets/ruler_widget.dart';
import '../widgets/setup_modern_widgets.dart';
import '../widgets/setup_screen_scaffold.dart';

class HeightSelectionScreen extends StatefulWidget {
  const HeightSelectionScreen({super.key});

  @override
  State<HeightSelectionScreen> createState() => _HeightSelectionScreenState();
}

class _HeightSelectionScreenState extends State<HeightSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isCm = true;

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
        context.read<SetupProvider>().goToStep(SetupStep.height);
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
        final heightCm = provider.height ?? 170.0;
        final displayHeight = _isCm ? heightCm : (heightCm / 30.48);
        final valueText = _isCm
            ? displayHeight.toStringAsFixed(0)
            : displayHeight.toStringAsFixed(1);

        return SetupScreenScaffold(
          currentStep: provider.currentStepIndex + 1,
          totalSteps: provider.totalSteps,
          onBack: () {
            provider.previousStep();
            context.go(AppRoutes.setupAge);
          },
          eyebrow: 'Basics',
          title: 'Your height',
          subtitle: 'Used for body calculations.',
          primaryButtonLabel: 'Continue',
          isPrimaryButtonEnabled: provider.canGoNext,
          onPrimaryButtonPressed: () {
            HapticFeedback.mediumImpact();
            provider.nextStep();
            context.go(AppRoutes.setupWeight);
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
                            label: 'CURRENT HEIGHT',
                            value: valueText,
                            unit: _isCm ? 'cm' : 'ft',
                            caption: '',
                          ),
                          const SizedBox(height: 16),
                          SetupSegmentedToggle(
                            labels: const ['Centimeters', 'Feet'],
                            selectedIndex: _isCm ? 0 : 1,
                            onChanged: (index) {
                              setState(() => _isCm = index == 0);
                            },
                          ),
                          const SizedBox(height: 20),
                          SetupRulerPanel(
                            child: RulerWidget(
                              key: ValueKey(_isCm),
                              value: displayHeight,
                              minValue: _isCm ? 120 : 4.0,
                              maxValue: _isCm ? 230 : 7.5,
                              labelInterval: _isCm ? 10 : 1,
                              pixelsPerUnit: _isCm ? 20.0 : 60.0,
                              onValueChanged: (value) {
                                final cmValue = _isCm ? value : (value * 30.48);
                                provider.setAnswer(SetupStep.height, cmValue);
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
